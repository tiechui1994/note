## 文件权限

同一个权限对于 `文件` 和 `目录` 来说, 含义是不一样的.

| 权限 | 文件 | 目录 |
| --- | --- | --- |
| r | 可以读取文件内容	| 可以读取目录结构列表 |
| w	| 可以编辑修改文件内容 | 可以改动目录结构列表 |
| x	| 可以被系统执行 |	用户可以进入目录 (cd) |

> 注意: **可以改动目录结构列表**, 意味着:
> 
> - 建立新的文件与目录
> - 删除已存在的文件与目录
> - 将已存在的文件或目录进行更名
> - 搬移该目录内的文件, 目录位置
