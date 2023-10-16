## MySQL命令 - GRANT, REVOKE, CREATE USER

### grant

数据库用户授权.

```
GRANT  privilege_type [(column_list)], privilege_type [(column_list)] ...
       ON [object_type] privilege_level
       TO user [auth_option], user [auth_option] ...
       [WITH {GRANT OPTION | resource_option} ...]

GRANT PROXY ON user
      TO user user, user ...
      [WITH GRANT OPTION]

privilege_type:
    ALL PRIVILLEGES
    INSERT   levels: global, database, table, column
    UPDATE   levels: global, database, table, column
    SELECT   levels: global, database, table, column
    CREATE   levels: global, database, table
    DELETE   levels: global, database, table
    
    ALTER    ALTER TABLE. levels: global, database, table
    DROP     levels: global, database, table
    INDEX    levels: global, database, table
    EVENT    Event Scheduler. levels: global, database
    EXECUTE  execute stored routines. levels: global, routine
    FILE     server read and write files. levels: global
    PROXY    proxying. level: from user to user
    RELOAD   FLUSH operations.  level: global
    SUPPER   admin. level: global

object_type:
    TABLE | FUNCTION | PROCEDURE

privilege_level:
    * | *.* | db_name.* | db_name.tb_name | tb_name | db_name_routine_name

user: 
    基本格式: 'user_name'@'host_name'
    a) 'user_name' <==> 'user_name'@'%'
    b) user_name是区分大小写的, host_name是不区分大小写的
    c) user_name是非空格值, 如果 user_name='' 或 user_name=' ', 则该账号是匿名用户(任何用户都可以登录). 要在SQL
    语句当中指定匿名用户, 请使用带引号的空格用户名, 例如: ''@'localhost'
    d) user_name 和 host_name 可以采用多种形式, 并允许使用通配符.
    host_name 可以使用主机名或IP地址. 并且主机名和IP地址可以使用 '%' 和 '_' 通配符(与LIKE运算匹配相同)
    host_name使用子网掩码, 格式是 host_ip/netmask, 其中host_ip 是网络地址, 例如 '192.168.10.0/255.255.255.0'
  
auth_option:
    IDENTIFIED BY 'auth_string' 
    IDENTIFIED WITH auth_plugin
    IDENTIFIED WITH auth_plugin BY 'auth_string'
    IDENTIFIED WITH auth_plugin AS 'auth_string'
    IDENTIFIED BY PASSWORD 'auth_string'

resource_option:
    MAX_QUERIES_PER_HOUR count
    MAX_UPDATES_PER_HOUR count
    MAX_CONNECTIONS_PER_HOUR count
    MAX_USER_CONNECTIONS count
```

column_list, 只有当 `privilege_type` 是**column级别**的权限的时候,才可能会出现.

object_type, 默认是 `TABLE`.


例1: 数据库级别权限
```
GRANT ALL PRIVILLEGES ON db.* TO 'username'@'192.168.1.1.' WITH GRANT OPTION;

GRANT ALL PRIVILLEGES ON db.* TO 'username'@'192.168.1.1.' WITH IDENTIFIED BY '1234567';
```

例2: 带限定性质权限
```
GRANT ALL PRIVILLEGES ON db.* TO 'username'@'192.168.1.1.' WITH MAX_USER_CONNECTIONS 128;
```

例3: 数据库管理员
```
GRANT ALL PRIVILLEGES ON * TO 'admin'@'127.0.0.1' WITH GRANT OPTION;
```

### reovke

数据库用户撤销授权.

```
REVOKE privilege_type [(column_list)], privilege_type [(column_list)] ...
    ON [object_type] privilege_level
    FROM user, user ...

REVOKE ALL PRIVILLEGES, GRANT OPTION
    FROM user, user ....

privilege_type:
    ALL PRIVILLEGES
    INSERT   levels: global, database, table, column
    UPDATE   levels: global, database, table, column
    SELECT   levels: global, database, table, column
    CREATE   levels: global, database, table
    DELETE   levels: global, database, table
    
    ALTER    ALTER TABLE. levels: global, database, table
    DROP     levels: global, database, table
    INDEX    levels: global, database, table
    EVENT    Event Scheduler. levels: global, database
    EXECUTE  execute stored routines. levels: global, routine
    FILE     server read and write files. levels: global
    PROXY    proxying. level: from user to user
    RELOAD   FLUSH operations.  level: global
    SUPPER   admin. level: global

object_type:
    TABLE | FUNCTION | PROCEDURE

privilege_level:
    * | *.* | db_name.* | db_name.tb_name | tb_name | db_name_routine_name

user: 
    基本格式: 'user_name'@'host_name'
    a) 'user_name' <==> 'user_name'@'%'
    b) user_name是区分大小写的, host_name是不区分大小写的
    c) user_name是非空格值, 如果 user_name='' 或 user_name=' ', 则该账号是匿名用户(任何用户都可以登录). 要在SQL
    语句当中指定匿名用户, 请使用带引号的空格用户名, 例如: ''@'localhost'
    d) user_name 和 host_name 可以采用多种形式, 并允许使用通配符.
    host_name 可以使用主机名或IP地址. 并且主机名和IP地址可以使用 '%' 和 '_' 通配符(与LIKE运算匹配相同)
    host_name使用子网掩码, 格式是 host_ip/netmask, 其中host_ip 是网络地址, 例如 '192.168.10.0/255.255.255.0'
```

案例:

```
REVOKE ALL PRIVILLEGES ON '*'.'*' FROM 'admin'@'%';
```


### user

用户创建与删除

```
CREATE USER [IF NOT EXISTS]
    user [auth_option], user [auth_option] ...
    [WITH resource_option resource_option ...]
    [password_option]

DROP USER [IF EXISTS] user, user ....

user: 
    基本格式: 'user_name'@'host_name'
    a) 'user_name' <==> 'user_name'@'%'
    b) user_name是区分大小写的, host_name是不区分大小写的
    c) user_name是非空格值, 如果 user_name='' 或 user_name=' ', 则该账号是匿名用户(任何用户都可以登录). 要在SQL
    语句当中指定匿名用户, 请使用带引号的空格用户名, 例如: ''@'localhost'
    d) user_name 和 host_name 可以采用多种形式, 并允许使用通配符.
    host_name 可以使用主机名或IP地址. 并且主机名和IP地址可以使用 '%' 和 '_' 通配符(与LIKE运算匹配相同)
    host_name使用子网掩码, 格式是 host_ip/netmask, 其中host_ip 是网络地址, 例如 '192.168.10.0/255.255.255.0'
  
auth_option:
    IDENTIFIED BY 'auth_string' 
    IDENTIFIED WITH auth_plugin
    IDENTIFIED WITH auth_plugin BY 'auth_string'
    IDENTIFIED WITH auth_plugin AS 'auth_string'
    IDENTIFIED BY PASSWORD 'auth_string'

resource_option:
    MAX_QUERIES_PER_HOUR count
    MAX_UPDATES_PER_HOUR count
    MAX_CONNECTIONS_PER_HOUR count
    MAX_USER_CONNECTIONS count

password_option:
    PASSWORD EXPIRE
    PASSWORD EXPIRE DEFAULT
    PASSWORD EXPIRE NEVER
    PASSWORD INTERVAL n DAY
```

关于 auth_option 的说明:

- `IDENTIFIED BY 'auth_string'`, 将用户身份验证插件设置为默认插件. 将明文 'auth_string' 值传递给插件以进行可能的
hash, 并将结果存储在 mysql.user 表当中.

- `IDENTIFIED WITH auth_plugin`, 将用户身份验证插件设置为 auth_plugin, 并清除认证凭证, 并将结果存储在 mysql.user 
表当中 

- `IDENTIFIED WITH auth_plugin BY 'auth_string'`, 将用户身份验证插件设置为 auth_plugin, 将明文 'auth_string' 
值传递给插件以进行可能的 hash, 并将结果存储在 mysql.user 表当中.

- `IDENTIFIED WITH auth_plugin AS 'auth_string'`, 将用户身份验证插件设置为 auth_plugin, **将明文'auth_string'
值原样存储在mysql.user表当中**.

- `IDENTIFIED BY PASSWORD 'auth_string'`, 将用户身份验证插件设置为默认插件. **将明文'auth_string' 值原样存储
在mysql.user表当中**.

> default_authentication_plugin 变量可以设置默认的插件. 默认插件是 `mysql_native_password`

案例1: 创建匿名账号
```
CREATE USER ''%'localhost' IDENTIFIED BY 'password';
```

案例2: 创建特定IP网段访问的账号
```
CREATE USER 'account'%'192.168.1.%' IDENTIFIED BY 'password' PASSWORD EXPIRE NEVER;
```

### 用户权限刷新

```
FLUSH PRIVILLEGES;
```

作用: 当数据表中的权限数据和内存中的权限数据不一致的时候, 可以重新构建内存数据, 达到一致状态. 

不规范的操作, 可能需要上述的操作, 例如: 直接更改或删除 `mysql.user` 表当中相关用户的权限. 如果用户的创建,删除,授权,撤
销授权是按照前面的操作执行的, 是不需要 `FLUSH PRIVILLEGES` 操作的.
