-- ----------------------------
-- Table structure for system_source_identity_mapping
-- ----------------------------
DROP TABLE IF EXISTS system_source_identity_mapping;
CREATE TABLE system_source_identity_mapping
(
    id                 int8         NOT NULL,
    source_type        varchar(32)  NOT NULL,
    source_user_id     varchar(128) NOT NULL,
    source_user_name   varchar(128) NULL     DEFAULT NULL,
    source_union_id    varchar(128) NULL     DEFAULT NULL,
    source_open_id     varchar(128) NULL     DEFAULT NULL,
    source_tenant_id   varchar(128) NULL     DEFAULT NULL,
    mobile             varchar(32)  NULL     DEFAULT NULL,
    email              varchar(128) NULL     DEFAULT NULL,
    internal_user_id   int8         NOT NULL,
    status             int2         NOT NULL DEFAULT 1,
    last_login_time    timestamp    NULL     DEFAULT NULL,
    last_verified_time timestamp    NULL     DEFAULT NULL,
    ext_json           text         NULL     DEFAULT NULL,
    creator            varchar(64)  NULL     DEFAULT '',
    create_time        timestamp    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater            varchar(64)  NULL     DEFAULT '',
    update_time        timestamp    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted            int2         NOT NULL DEFAULT 0,
    tenant_id          int8         NOT NULL DEFAULT 0
);

ALTER TABLE system_source_identity_mapping
    ADD CONSTRAINT pk_system_source_identity_mapping PRIMARY KEY (id);

CREATE UNIQUE INDEX uk_tenant_source_user
    ON system_source_identity_mapping (tenant_id, source_type, source_user_id);

CREATE UNIQUE INDEX uk_tenant_source_internal_user
    ON system_source_identity_mapping (tenant_id, source_type, internal_user_id);

CREATE INDEX idx_source_identity_internal_user_id
    ON system_source_identity_mapping (internal_user_id);

CREATE INDEX idx_source_identity_tenant_status
    ON system_source_identity_mapping (tenant_id, status);

COMMENT ON TABLE system_source_identity_mapping IS '来源身份映射表';
COMMENT ON COLUMN system_source_identity_mapping.id IS '编号';
COMMENT ON COLUMN system_source_identity_mapping.tenant_id IS '租户ID';
COMMENT ON COLUMN system_source_identity_mapping.source_type IS '来源类型，如 PLATFORM_INTERNAL / DINGTALK / FEISHU / WECHAT_ENTERPRISE';
COMMENT ON COLUMN system_source_identity_mapping.source_user_id IS '来源侧用户ID（下游权限 userId 实际取值）';
COMMENT ON COLUMN system_source_identity_mapping.source_user_name IS '来源侧用户名称';
COMMENT ON COLUMN system_source_identity_mapping.source_union_id IS '跨应用统一标识';
COMMENT ON COLUMN system_source_identity_mapping.source_open_id IS '单应用登录标识';
COMMENT ON COLUMN system_source_identity_mapping.source_tenant_id IS '来源侧租户标识（预留）';
COMMENT ON COLUMN system_source_identity_mapping.mobile IS '手机号（预留）';
COMMENT ON COLUMN system_source_identity_mapping.email IS '邮箱（预留）';
COMMENT ON COLUMN system_source_identity_mapping.internal_user_id IS '平台内部用户ID';
COMMENT ON COLUMN system_source_identity_mapping.status IS '映射状态，1 启用，0 停用';
COMMENT ON COLUMN system_source_identity_mapping.last_login_time IS '最近登录时间（预留）';
COMMENT ON COLUMN system_source_identity_mapping.last_verified_time IS '最近校验时间';
COMMENT ON COLUMN system_source_identity_mapping.ext_json IS '扩展信息';
COMMENT ON COLUMN system_source_identity_mapping.creator IS '创建者';
COMMENT ON COLUMN system_source_identity_mapping.create_time IS '创建时间';
COMMENT ON COLUMN system_source_identity_mapping.updater IS '更新者';
COMMENT ON COLUMN system_source_identity_mapping.update_time IS '更新时间';
COMMENT ON COLUMN system_source_identity_mapping.deleted IS '是否删除（0 否，1 是）';

-- ----------------------------
-- Sequence structure for system_source_identity_mapping
-- ----------------------------
DROP SEQUENCE IF EXISTS system_source_identity_mapping_seq;
CREATE SEQUENCE system_source_identity_mapping_seq
    START 1;
