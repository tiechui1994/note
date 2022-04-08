# MongoDB 授权

## 用户创建和授权

> 注意: 创建用户或者更新用户的时候需要先切换到对应的数据库当中. 一般情况下, 切换的数据库是 admin

- 创建用户, 并且授权

```
db.createUser({
    user:"<username>",
    pwd:"<pwd>",
    roles:[{
        role: "<role>",
        db: "<accessdb>",
    }]
})
```

- 增加用户权限

```
db.grantRolesToUser("<username>", [ <roles> ], { <writeConcern> })
```

- 删除用户权限

```
db.revokeRolesFronUser("<username>", [ <roles> ], { <writeConcern> })
```

- 更新用户

```
db.updateUser("<username>", {
    roles:[{
        role:"<role>",
        db:"<accessdb>"
    }],
    pwd:"<pwd>"
}, { <writeConcern > })
```


MongoDB在每个数据库上提供内置的database user 和 database administration 角色. 
MongoDB仅在admin数据库上提供所有其他内置角色.

### Database User Roles

每个数据库都包含以下客户端角色.

- read

- readWrite

## Database Administration Roles

每个数据库都包含以下数据库管理角色.

- dbAdmin

- dbOwner

- userAdmin

### Cluster Administration Roles

admin数据库包括以下角色, 用于管理整个系统而不仅仅是单个数据库. 这些角色包括但不限于副本集(replia set)和分片集群(sharded cluster)管理功能.

- clusterAdmin

- clusterManager (3.4)

- clusterMonitor (3.4)

- hostManager

## Backup And Restoration Roles

admin数据库包括以下用于备份和还原数据的角色.

- backup (3.4)

- restore (3.6)

## All-Database Roles (3.4)

**以下角色仅适用于admin数据库中的用户**. 这些角色提供适用于 `除了local和config之外的所有数据库` 上 `除了system.*集合之外的所有集合` 的权限.

- readAnyDatabase

- readWriteAnyDatabase

- userAdminAnyDatabase

- dbAdminAnyDatabase

### Superuser Roles

- root
