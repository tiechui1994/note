## mongo 查询

- 模糊匹配

如果是在 mngo shell 当中执行命令, 格式可以为:

```
{
    "name": {
        "$regex": /name/i
    }
}
```

或者 

```
{
    "name": {
        "$regex": "name",
        "$options":"i"
    }
}
```

对于 `golang` 使用的 `go.mongodb.org/mongo-driver/bson` 或者 `gopkg.in/mgo.v2/bson` 包, 写法和上面的第二种类似:

```cgo
{
    "name": bson.M{
        "$regex":   name,
        "$options": "i",
    }
}
```

> `$options` 是正则匹配选项, 常用的有 `i`, 忽略大小写匹配, `m` 多行匹配, `x` 扩展选项

