# Magicain 生产证书续期

## 固定上下文

| 项目 | 值 |
| --- | --- |
| 主域名 | `magicain.com` |
| 期望 SAN | `magicain.com`、`www.magicain.com` |
| 证书服务 | 阿里云数字证书管理服务 CAS，DigiCert DV |
| 仓库 | `magicain-com/magicain-harness` |
| GitHub 环境 | `prod` |
| GitHub 密钥 | `MAGICAIN_CERT_KEY`、`MAGICAIN_CERT_PEM` |
| 部署工作流 | `.github/workflows/deploy-app-frontend.yml` |
| 默认分支 | 运行时查询，不硬编码；当前通常为 `main` |
| 生产 SSH 别名 | `prod-app-frontend`（本机存在时使用） |
| 生产目录 | `/opt/magicain` |
| Nginx 容器 | `magicain-nginx-proxy-1` |

个人测试 DV 证书通常只有约 3 个月有效期。建议在到期前 30 天检查并续期，不要等到最后一周。

## 阶段 0：预检

1. 从仓库根目录读取 `AGENTS.md` 和 `.github/workflows/deploy-app-frontend.yml`，确认环境名、密钥名和部署目标没有变化。
2. 检查工具：`aliyun`、`gh`、`jq`、`openssl`、`dig`、`ssh`。
3. 运行：

   ```bash
   .agents/skills/magicain-ops/scripts/check-production-certificate.sh
   ```

4. 检查认证身份，不输出密钥：

   ```bash
   aliyun sts GetCallerIdentity
   gh auth status
   gh repo view magicain-com/magicain-harness --json nameWithOwner,defaultBranchRef
   ```

5. 如果环境变量 `GITHUB_TOKEN` 覆盖了钥匙串中的有效登录并导致失败，使用 `env -u GITHUB_TOKEN gh ...` 重试。不要打印环境变量内容。
6. 使用 `aliyun configure list` 选择有 CAS 权限的配置。团队机器可使用 `magicain-prod`，但必须以 `GetCallerIdentity` 的实际结果为准，不假设账号身份。

## 阶段 1：准备并申请证书

优先复用未使用的个人测试证书实例，避免重复购买或耗尽额度：

```bash
aliyun cas ListInstances --InstanceType TEST --Status inactive --CurrentPage 1 --ShowSize 100
aliyun cas ListContact --CurrentPage 1 --ShowSize 100
```

选择明确属于 Magicain 的联系人 ID 和未使用实例。不要把联系人邮箱或手机号写入 Skill、仓库或聊天输出。

配置实例。替换占位符，不要盲目复用旧实例 ID：

```bash
aliyun cas UpdateInstance \
  --InstanceId <INSTANCE_ID> \
  --CertificateName cert-magicain-YYYY-MM \
  --Domain magicain.com \
  --ContactIdList.1 <CONTACT_ID> \
  --GenerateCsrMethod online \
  --KeyAlgorithm RSA_2048 \
  --CountryCode CN \
  --Province Shanghai \
  --City Shanghai \
  --ValidationMethod DNS \
  --AutoReissue disable
aliyun cas ApplyCertificate --InstanceId <INSTANCE_ID>
```

若没有可复用实例，先通过阿里云控制台获取个人测试证书额度，或在联系人信息已获授权时使用 `CreateCertificateRequest`。执行前用 `aliyun cas CreateCertificateRequest help` 核对当前参数；不要把个人信息硬编码进仓库。

不要为当前 Magicain 入口选择 HTTP/FILE 验证。公网可能被阿里云 ICP 备案页面拦截，导致 CA 无法读取验证文件；使用 DNS 验证。

## 阶段 2：完成 DNS 验证

查询实例详情并提取本次申请的验证记录：

```bash
aliyun cas GetInstanceDetail --InstanceId <INSTANCE_ID>
```

以返回的 `DomainValidationList` 为唯一真源，读取：

- `ValidationKey` 或 `CnameKey`：通常为 `_dnsauth`
- `ValidationType`：当前流程使用 `TXT`
- `ValidationValue`：每次申请都会变化，绝不能复用旧值

如果 CAS 账号同时拥有 DNS 权限，优先使用阿里云 DNS CLI 精确更新现有 `_dnsauth` TXT。若 DNS 属于另一个阿里云账号，使用用户已登录的 Chrome 操作云解析 DNS 控制台：

1. 打开 `magicain.com` 的解析设置。
2. 定位唯一的 `_dnsauth` TXT 记录。
3. 只把记录值改成本次 `ValidationValue`；保留主机记录、类型、线路、TTL 和启用状态。
4. 在变更确认页再次核对旧值、新值和域名后提交。

用公网 DNS 验收：

```bash
dig +short TXT _dnsauth.magicain.com
```

返回值必须与本次申请的 `ValidationValue` 完全一致。

## 阶段 3：等待签发并验证证书

每 20–60 秒查询一次，不要高频轮询：

```bash
aliyun cas GetInstanceDetail --InstanceId <INSTANCE_ID>
aliyun cas ListCertificates --InstanceId <INSTANCE_ID> --CurrentPage 1 --ShowSize 10
```

只有 `CertificateStatus` 或 `PendingResult` 显示 `issued`，并获得新的 `CertificateId`，才进入下载阶段。失败时读取明确的审核原因，不要反复创建新订单。

## 阶段 4：安全下载和本地校验

创建随机临时目录并收紧权限。下列文件只能存在于临时目录，绝不提交到 Git：

```bash
CERT_TMP_DIR="$(mktemp -d /private/tmp/magicain-cert.XXXXXX)"
chmod 700 "$CERT_TMP_DIR"
umask 077
aliyun cas GetUserCertificateDetail --CertId <CERTIFICATE_ID> > "$CERT_TMP_DIR/detail.json"
jq -r .Cert "$CERT_TMP_DIR/detail.json" > "$CERT_TMP_DIR/cert.pem"
jq -r .Key "$CERT_TMP_DIR/detail.json" > "$CERT_TMP_DIR/key.pem"
chmod 600 "$CERT_TMP_DIR/detail.json" "$CERT_TMP_DIR/cert.pem" "$CERT_TMP_DIR/key.pem"
```

不要把 `detail.json`、`.Key`、私钥正文或完整 CLI 响应输出到聊天。验证以下条件：

```bash
openssl x509 -in "$CERT_TMP_DIR/cert.pem" -noout -subject -issuer -dates -ext subjectAltName -fingerprint -sha256
openssl x509 -in "$CERT_TMP_DIR/cert.pem" -pubkey -noout | openssl sha256
openssl pkey -in "$CERT_TMP_DIR/key.pem" -pubout | openssl sha256
rg -c "BEGIN CERTIFICATE" "$CERT_TMP_DIR/cert.pem"
```

验收门槛：

- SAN 同时包含 `magicain.com` 与 `www.magicain.com`。
- 证书有效期是新周期。
- 证书公钥和私钥派生公钥的 SHA-256 完全一致。
- PEM 包含叶证书和中间证书链；当前阿里云返回通常是 2 个证书块。

## 阶段 5：更新 GitHub prod 密钥

先确认密钥名称和更新时间，不读取密钥值：

```bash
gh secret list --repo magicain-com/magicain-harness --env prod
```

从标准输入更新，避免把敏感值放进命令参数或历史：

```bash
gh secret set MAGICAIN_CERT_KEY --repo magicain-com/magicain-harness --env prod < "$CERT_TMP_DIR/key.pem"
gh secret set MAGICAIN_CERT_PEM --repo magicain-com/magicain-harness --env prod < "$CERT_TMP_DIR/cert.pem"
gh secret list --repo magicain-com/magicain-harness --env prod
```

最后一条输出中的两项更新时间必须刷新。若使用 `env -u GITHUB_TOKEN` 才能认证，对本阶段所有 `gh` 命令保持一致。

## 阶段 6：触发并跟踪部署

运行时查询默认分支，然后触发生产工作流：

```bash
gh repo view magicain-com/magicain-harness --json defaultBranchRef
gh workflow run deploy-app-frontend.yml --repo magicain-com/magicain-harness --ref <DEFAULT_BRANCH>
gh run watch <RUN_ID> --repo magicain-com/magicain-harness --exit-status --interval 10
```

必须保存并交付 Actions 运行链接。只有工作流结论为 `success` 且 Upload、Deploy 步骤均通过，才视为部署完成。

## 阶段 7：生产服务器验收

验证 Nginx 配置：

```bash
ssh -o BatchMode=yes prod-app-frontend "docker exec magicain-nginx-proxy-1 nginx -t"
```

直接读取服务器本机 443 端口实际提供的证书：

```bash
ssh -o BatchMode=yes prod-app-frontend \
  "openssl s_client -connect 127.0.0.1:443 -servername magicain.com </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates -ext subjectAltName -fingerprint -sha256"
```

服务器证书的有效期、SAN 和 SHA-256 指纹必须与新证书一致。公网 TLS 可作为附加检查，但不能替代服务器本机验收；如果公网被 ICP 备案拦截，要单独报告。

## 阶段 8：清理和交付

只删除本次创建的明确临时文件和目录：

```bash
rm -f "$CERT_TMP_DIR/detail.json" "$CERT_TMP_DIR/cert.pem" "$CERT_TMP_DIR/key.pem"
rmdir "$CERT_TMP_DIR"
```

交付内容包括：

- 新证书 ID、域名/SAN、签发者和有效期
- DNS 验证已生效
- GitHub `prod` 两项密钥更新时间已刷新
- Actions 运行链接和成功结论
- Nginx 配置检查结果
- 服务器 443 端口证书指纹
- 临时敏感文件已删除
- ICP 备案等与证书无关的遗留风险
