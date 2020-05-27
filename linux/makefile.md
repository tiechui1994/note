# makefile

## makefile 规则

```
target ... : prerequisities ...
    command
    ...
    ...
```

target, 可以是一个 object file (目标文件), 也可以是一个执行文件, 还可以是一个标签(label). 对于标签
这种特性, 在后续的 `伪目标` 中有介绍.

prerequisites, 生成该 target 所依赖的文件或target

command, 该target要执行的命令(任意的shell命令)

> 这是一个文件的依赖关系, 也就说, target 这一个或多个的目标文件依赖于 prerequisites 中的文件, 其生成规
> 则定义在 command 中.


案例: (原始)
```makefile
edit : main.o command.o
	cc -o edit main.o command.o

main.o : main.c
	cc -c main.c
command.o : command.c
	cc -c command.c

clean :
	rm edit main.o command.o
```


案例: (使用变量)
```makefile
objects = main.o command.o

edit : $(objects)
	cc -o edit $(objects)

main.o : main.c
	cc -c main.c
command.o : command.c
	cc -c command.c

clean :
	rm edit $(objects)
```


案例:(make自动推倒)
```makefile
objects = main.o command.o

edit : $(objects)
	cc -o edit $(objects)

# 可以省略
main.o:main.c
command.o: command.c

clean :
	rm edit $(objects)
```

### 引用其他的 Makefile

在 Makefile 使用 `include` 关键字可以把别的 Makefile 包含进来, 这很像 C 语言的 `#include`, 被包含的
文件会原模原样的放在当前文件的包含位置. 

```
include <filename>
```

> `filename` 可以是当前操作系统 shell 的文件模式 (可以包含路径和通配符). 
>
> 在 `include` 前面可以有一些空字符, 但是绝对不能是 `TAB` 键开始. `include` 和 `<filename>` 可以用
> 一个或多个空格隔开.

```makefile
bar = e.mk f.mk
include foo.make *.mk $(bar)
```

make 命令开始时, 会寻找 `include` 所指出的其他 Makefile, 并把其内容安置到当前的位置. 如果文件没有指定绝对路径
或者相对路径的话, make 会在当前目录下首先寻找, 如果当前目录没有找到, 那么, make 会在以下几个目录查找:

1.如果make执行时, 有 `-I` 或 `--include` 参数, 那么 make 就会在这个参数所指定的目录下去寻找.

2.如果目录 `<prefix>/include` (一般是: `/usr/local/bin` 或 `/usr/include`) 存在的话, make 也会去找.

如果没有找到文件的话, make 会产生一条警告信息, 但是不会马上出现致命错误. 它会继续载入其他的文件, 一旦完成 makefile 
的读取, make 会再重试这些没有找到, 或者不能读取的文件, 如果还是不行, make才会出现一条致命信息.


## 书写规则

规则包含两个部分: 一个是依赖关系, 一个是生成目标的方法

在 Makefile 中, 规则的顺序很重要. 因为, Makefile 中只应该有一个最终目标, 其他的目标都是被目标这个目标所带出来的, 
所以一定要让 make 知道你的最终目标是什么. 一般来说, 定义在 Makefile 中的目标可能会有很多, 但是第一条规则中目标将
被确定为最终的目标. `如果第一条规则中的目标有很多个, 那么, 第一个目标目标就会成为最终的目标.`

### 规则的语法

```
target : prerequisities 
    command
    ...
```

targets是文件名, 以空格分开, `可以使用通配符`. 一般来说, 目标基本上是一个文件, 但也有可能是多个文件.

command是命令行, 必须以 `TAB` 键开头.

prerequisities是目标所依赖的文件(或依赖目标). 如果其中的某个文件要比目标要新, 那么, 目标就被认为是
"过时的", 被认为是需要重生成的.

> 如果命令太长, 可以使用反斜线 `\` 作为换行符.

> 一般来说, make 会以 UNIX 的标准 Shell, 也就是 `/bin/sh` 来执行命令.


### 在规则当中使用通配符

### 文件搜索

### 伪目标

### 多目标

### 静态模式

### 自动生成依赖性



