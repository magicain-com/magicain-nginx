INSERT INTO `system_menu` VALUES (8001, '智能问数', '', 1, 3, 0, '/aibi', 'ep:data-board', '', '', 0, b'1', b'1', b'1', '1', '2025-05-26 08:21:49', '1', '2025-05-26 08:21:49', b'0');


-- 民宿房间管理的菜单 SQL
INSERT INTO system_menu(
    name, permission, type, sort, parent_id,
    path, icon, component, status, component_name
)
VALUES (
           '民宿房间管理', '', 2, 0, 8001,
           'abb-room', '', 'aibi/abbroom/index', 0, 'AbbRoom'
       );

-- 按钮父菜单ID
-- 暂时只支持 MySQL。如果你是 Oracle、PostgreSQL、SQLServer 的话，需要手动修改 @parentId 的部分的代码
SELECT @parentId := LAST_INSERT_ID();

-- 按钮 SQL
INSERT INTO system_menu(
    name, permission, type, sort, parent_id,
    path, icon, component, status
)
VALUES (
           '民宿房间查询', 'aibi:abb-room:query', 3, 1, @parentId,
           '', '', '', 0
       );
INSERT INTO system_menu(
    name, permission, type, sort, parent_id,
    path, icon, component, status
)
VALUES (
           '民宿房间创建', 'aibi:abb-room:create', 3, 2, @parentId,
           '', '', '', 0
       );
INSERT INTO system_menu(
    name, permission, type, sort, parent_id,
    path, icon, component, status
)
VALUES (
           '民宿房间更新', 'aibi:abb-room:update', 3, 3, @parentId,
           '', '', '', 0
       );
INSERT INTO system_menu(
    name, permission, type, sort, parent_id,
    path, icon, component, status
)
VALUES (
           '民宿房间删除', 'aibi:abb-room:delete', 3, 4, @parentId,
           '', '', '', 0
       );
INSERT INTO system_menu(
    name, permission, type, sort, parent_id,
    path, icon, component, status
)
VALUES (
           '民宿房间导出', 'aibi:abb-room:export', 3, 5, @parentId,
           '', '', '', 0
       );


-- 民宿QA管理的菜单 SQL
INSERT INTO system_menu(
    name, permission, type, sort, parent_id,
    path, icon, component, status, component_name
)
VALUES (
           '民宿QA管理', '', 2, 0, 8001,
           'abb-qa', '', 'aibi/abbqa/index', 0, 'AbbQa'
       );

-- 按钮父菜单ID
-- 暂时只支持 MySQL。如果你是 Oracle、PostgreSQL、SQLServer 的话，需要手动修改 @parentId 的部分的代码
SELECT @parentId := LAST_INSERT_ID();

-- 按钮 SQL
INSERT INTO system_menu(
    name, permission, type, sort, parent_id,
    path, icon, component, status
)
VALUES (
           '民宿QA查询', 'aibi:abb-qa:query', 3, 1, @parentId,
           '', '', '', 0
       );
INSERT INTO system_menu(
    name, permission, type, sort, parent_id,
    path, icon, component, status
)
VALUES (
           '民宿QA创建', 'aibi:abb-qa:create', 3, 2, @parentId,
           '', '', '', 0
       );
INSERT INTO system_menu(
    name, permission, type, sort, parent_id,
    path, icon, component, status
)
VALUES (
           '民宿QA更新', 'aibi:abb-qa:update', 3, 3, @parentId,
           '', '', '', 0
       );
INSERT INTO system_menu(
    name, permission, type, sort, parent_id,
    path, icon, component, status
)
VALUES (
           '民宿QA删除', 'aibi:abb-qa:delete', 3, 4, @parentId,
           '', '', '', 0
       );
INSERT INTO system_menu(
    name, permission, type, sort, parent_id,
    path, icon, component, status
)
VALUES (
           '民宿QA导出', 'aibi:abb-qa:export', 3, 5, @parentId,
           '', '', '', 0
       );
