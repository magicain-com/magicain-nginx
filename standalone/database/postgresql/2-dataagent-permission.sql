-- 整体注意租户ID，不同租户都需要执行
INSERT INTO system_menu(
    id, name, permission, type, sort, parent_id, path, status
)
VALUES (
    7000, '数据分析', '', 2, 0, 1, 'dataagent', 0
);

INSERT INTO system_menu(
    id, name, permission, type, sort, parent_id,
    path, icon, component, status
)
VALUES (
    7001, '数据分析智能体管理', 'dataagent:agent:admin', 3, 1, 7000,
    '', '', '', 0
);

INSERT INTO system_menu(
    id, name, permission, type, sort, parent_id,
    path, icon, component, status
)
VALUES (
    7002, '数据分析使用', 'dataagent:agent:user', 3, 1, 7000,
    '', '', '', 0
);

-- 添加角色，租户唯一
INSERT INTO system_role (id, name, code, sort, data_scope, data_scope_dept_ids, status, type, remark, creator, create_time, updater, update_time, deleted, tenant_id) 
VALUES (700, '数据分析用户', 'dataagent_user', 1, 1, '', 0, 1, '使用数据分析智能体', 'admin', '2021-01-05 17:03:48', '', '2022-02-22 05:08:21', '0', 123);


INSERT INTO system_role (id, name, code, sort, data_scope, data_scope_dept_ids, status, type, remark, creator, create_time, updater, update_time, deleted, tenant_id) 
VALUES (701, '数据分析智能体管理员', 'dataagent_agent_admin', 1, 1, '', 0, 1, '管理数据分析智能体', 'admin', '2021-01-05 17:03:48', '', '2022-02-22 05:08:21', '0', 123);

-- 添加角色的权限，租户唯一
-- 数据分析用户角色的权限
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id) 
VALUES (7000, 700, 1, '1', '2022-02-22 00:56:14', '1', '2022-02-22 00:56:14', '0', 123);
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id) 
VALUES (7001, 700, 7000, '1', '2022-02-22 00:56:14', '1', '2022-02-22 00:56:14', '0', 123);
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id) 
VALUES (7002, 700, 7002, '1', '2022-02-22 00:56:14', '1', '2022-02-22 00:56:14', '0', 123);
-- 数据分析智能体管理角色的权限
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id) 
VALUES (7003, 701, 1, '1', '2022-02-22 00:56:14', '1', '2022-02-22 00:56:14', '0', 123);
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id) 
VALUES (7004, 701, 7000, '1', '2022-02-22 00:56:14', '1', '2022-02-22 00:56:14', '0', 123);
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id) 
VALUES (7005, 701, 7001, '1', '2022-02-22 00:56:14', '1', '2022-02-22 00:56:14', '0', 123);
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id) 
VALUES (7006, 701, 7002, '1', '2022-02-22 00:56:14', '1', '2022-02-22 00:56:14', '0', 123);