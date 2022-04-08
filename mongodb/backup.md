## mongo 导入导出

```
mongodump -h HOST -u USER -p PWD -d DB --authenticationDatabase "admin" -o FILE
```

> authenticationDatabase 是创建账号的数据库. 如果是在 DB 当中创建的, 则不需要. 如果是在 admin 当中创建的, 则是需
要带上该参数的.

```
mongorestore -h HOST -u USER -p PWD -d DB --authenticationDatabase "admin" --drop --dir DIR
```

> --drop 是导入之前删除之前的 collection
> --dir=DIR 输入是一个文件夹. 在该文件夹下全部是文件