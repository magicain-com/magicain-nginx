-- 整体注意租户ID，不同租户都需要执行
INSERT INTO system_menu(
    id, name, permission, type, sort, parent_id, path, status
)
VALUES (
    8000, '智能问数', '', 2, 0, 1, 'chatbi', 0
);

INSERT INTO system_menu(
    id, name, permission, type, sort, parent_id,
    path, icon, component, status
)
VALUES (
    8001, '智能问数智能体管理', 'aibi:agent:admin', 3, 1, 8000,
    '', '', '', 0
);

INSERT INTO system_menu(
    id, name, permission, type, sort, parent_id,
    path, icon, component, status
)
VALUES (
    8002, '智能问数使用', 'aibi:agent:user', 3, 1, 8000,
    '', '', '', 0
);

-- 添加角色，租户唯一
INSERT INTO system_role (id, name, code, sort, data_scope, data_scope_dept_ids, status, type, remark, creator, create_time, updater, update_time, deleted, tenant_id) 
VALUES (800, '智能问数用户', 'aibi_user', 1, 1, '', 0, 1, '使用问数智能体', 'admin', '2021-01-05 17:03:48', '', '2022-02-22 05:08:21', '0', 123);


INSERT INTO system_role (id, name, code, sort, data_scope, data_scope_dept_ids, status, type, remark, creator, create_time, updater, update_time, deleted, tenant_id) 
VALUES (801, '智能问数智能体管理员', 'aibi_agent_admin', 1, 1, '', 0, 1, '管理问数智能体', 'admin', '2021-01-05 17:03:48', '', '2022-02-22 05:08:21', '0', 123);

-- 添加角色的权限，租户唯一
-- 智能问数用户角色的权限
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id) 
VALUES (8000, 800, 1, '1', '2022-02-22 00:56:14', '1', '2022-02-22 00:56:14', '0', 123);
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id) 
VALUES (8001, 800, 8000, '1', '2022-02-22 00:56:14', '1', '2022-02-22 00:56:14', '0', 123);
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id) 
VALUES (8002, 800, 8002, '1', '2022-02-22 00:56:14', '1', '2022-02-22 00:56:14', '0', 123);
-- 智能问数智能体管理角色的权限
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id) 
VALUES (8003, 801, 1, '1', '2022-02-22 00:56:14', '1', '2022-02-22 00:56:14', '0', 123);
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id) 
VALUES (8004, 801, 8000, '1', '2022-02-22 00:56:14', '1', '2022-02-22 00:56:14', '0', 123);
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id) 
VALUES (8005, 801, 8001, '1', '2022-02-22 00:56:14', '1', '2022-02-22 00:56:14', '0', 123);
INSERT INTO system_role_menu (id, role_id, menu_id, creator, create_time, updater, update_time, deleted, tenant_id) 
VALUES (8006, 801, 8002, '1', '2022-02-22 00:56:14', '1', '2022-02-22 00:56:14', '0', 123);