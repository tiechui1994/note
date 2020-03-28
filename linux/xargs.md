## xargs 命令

- 标准输入与管道命令

Linux 命令都带有参数, 有些命令可以接收 "标准输入" (stdin) 作为参数

```
cat /etc/passwd | grep root
```

上述代码使用了管道命令 `|`, 管道的作用, 是将左侧命令 `cat /etc/passwd` 的标准输出转换为标准输入,
提供给右侧命令 `grep root` 作为参数.

> **grep** 命令可以接收标准输入作为参数.

```
grep root /ect/passwd
```

> 可以接收标准输入作为参数的命令有: cat, head, tail, less, more, wc 等

但是, 大部分命令不接收标准输入作为参数, 只能直接在命令行输入参数, 这导致了无法使用管道命令传递参数.


- xargs命令的作用

`xargs` 命令的作用, 是将标准输入转为命令行参数.

```
echo "hello world" | xargs echo
```

上述的代码将管道左侧的标准输入, 转为命令行参数 `hello world`, 传递给第二个 `echo` 命令.


`xargs` 命令格式:

```
xargs [-option] [command]
```

- xargs 常用参数

1. -d 参数 与 分隔符, 默认情况下, xargs将换行符和空格作为分隔符, 把标准输入分解成一个个命令行参数.

```
echo "one two three" | xargs mkdir
```
 
上述代码将创建 `one two three` 三个目录.

-d 参数可以更改分隔符.


2. -p 参数打印要执行的命令, 询问用户是否要执行, -t 参数打印最终要执行的命令, 然后直接执行, 不需要用户确认.

3. -L 参数指定 `多少行` 作为命令行参数

4. -n 参数指定 `多少项` 作为命令行参数

```
$ echo -e "a\nb\nc" | xargs -L 1 echo
a
b
c

> 每次将一行作为一个参数, 执行三次

$ echo {0..9} | xargs -n 2 echo
0 1
2 3
4 5
6 7
8 9

> 每次将2项作为命令行参数
```

5. 如果 `xargs` 要将命令行参数传递给多个命令, 可以使用 `-I` 参数. -I 指定 `每一项命令行参数` 的替代字符串. 

```
$ echo -e "aa\nbb\ncc" | xargs -I arg bash -c 'echo arg; mkdir arg'
aa
bb
cc

> 针对每一项命令行参数, 执行两个命令 echo 和 mdkir, 使用 -I arg 表示 arg 是命令行参数的替代字符串. 执行命令
时, 具体的参数会被替代掉arg.
```