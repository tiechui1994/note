## git tag

### git tag 基础相关命令

```
git tag [-a | -s | -u <keyid>] [-f] [-m <msg> | -F <file>]
        <tagname> [<commit> | <object>]

git tag -d <tagname>...

git tag -l [-n[<num>]] [--contains <commit>] [--sort=<key>]
        [--format=<format>] [<pattern>...]
        
git tag -v <tagname>...
```

说明:
 
- 添加一个tag, 会在refs/tags/目录下添加一个 `tag` 文件(内容指向打 tag 时候的 HEAD 指向的commit).
  `-d/-l/-v` 参数分别对应 **`删除tag`**, **`列出tag`**, 和 **`验证tag`**
    
- 如果指定了 `-a`, `-s` 或 `-u <keyid>` 其中之一, 则该命令会创建标记对象, **并且需要标记消息**. 除非给出 `-m <msg>` 
  或 `-F <file>`, 否则将启动编辑器以供用户键入标记消息.

- 如果给出 `-m <msg>` 或 `-F <file>`, 但是 **`缺少 -a, -s 和 -u <keyid> 其中之一`**, 则隐式使用**`-a`**参数.

- 当使用 `-s` 或 `-u <keyid>` 时, 将创建GnuPG签名标记对象. 如果没有指定 `-u <keyid>`, 则使用当前用户的身份标示来
  查找用于签名的GnuPG密钥. 配置变量 `gpg.program` 用于指定自定义GnuPG二进制.

- 标记对象(使用 `-a`, `-s` 或 `-u` 创建)称为 "带注释" 标记; 它们包含创建日期, 标记名称和电子邮件, 标记消息以及可选
  的GnuPG签名. 而 "轻量级" 标签只是对象的名称(通常是提交对象).

- **带注释的标签用于发布, 而轻量级标签用于私有或临时对象标签. 出于这个原因, 一些用于命名对象的git命令(如git describe)
  将默认忽略轻量级标记.**


参数:

- -a, --annotate 创建一个未签名的带注释的标记对象

- -s, --sign 创建一个 **使用默认电子邮件地址作为密钥的** GPG签名的标记对象

- -u <keyid>, --local-user=<keyid> 创建一个使用给定秘钥的GPG签名的标记对象

- -f, --force 强制替换已经存在的tag

- -d, --delete 删除已经存在的tag

- -v, --verify 验证GPG签名的tag

- -l <pattern>, --list <pattern> 列出名称与给定模式匹配的标记(如果没有给出模式,则列出所有标记). 不带参数运行 
  "git tag"也会列出所有标签. 该模式是 shell 通配符(即, 使用fnmatch(3)匹配).可以给出多种模式; 如果它们中的任何一个
  匹配,则显示标记.

- -m <msg>, --message=<msg> 创建tag的msg

- -F <file>, --file=<file> 从给定文件中获取标记消息. 即:从标准输入中读取消息


### tag 推送

`git push origin <tag>`, 这样在 gitlab 当中的 tag 才会出现设置的tag


### 用于发布的标签

1.对当前的分支的提交进行打 tag (带注释的tag), 并推送

```
git commit -m "v1.0"
git tag -a -m "v1.0" 1.0
git push origin 1.0
```

2.后续的提交必须新创建一个 commit (在打 tag 的 commit 基础上), 不能覆盖提交.

```
// 当前的提交是 1.0 tag 的提交, 新的内容.
git add -A
git commit -m "new"
git push origin xxx
```
