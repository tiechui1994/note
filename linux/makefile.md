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

make 支持三个通配符: `*`, `?` 和 `~`. 这是和 Unix 的 B-Shell 是相同的.

波浪号 `~` 字符在文件名中也有比较特殊的用途. 如果是 `~/test`, 这就表示当前用户的 `$HOME` 目录下的 test 目录. 
而 `~hchen/test` 表示用户 hchen 的宿主目录下的 test 目录. (这些是 Unix 小知识, make 也支持)

通配符代表了一系列的文件, 如 `*.c` 表示所有后缀为 c 的文件.

Makefile 中的变量其实就是 C/C++ 中的宏. 如要让通配符在变量中展开, 也就是让 `*.c` 表示所有 `.c` 的文件名的集
合, 那么:

- 1.列出一确定文件夹中的所有 `.c` 文件: 

```
objects = $(wildcard *.c)
```

- 2.列出(1)中所有文件对应的 `.o` 文件

```
$(patsubst %.c,%.o,$(wildcard *.c))
```

- 3.由于(1)(2)两步, 可编写并链接所有 `.c` 和 `.o` 文件

```
objects := $(patsubst %.c,%.o,$(wildcard *.c))
foo: $(objects)
    cc -o foo $(objects)
```

### 文件搜索

在大的工程中, 有大量的源文件, 通常的做法是把这许多的源文件分类, 并存放在不同的目录中. 所以, 当 make 需要找寻文
件的依赖关系时, 可以在文件前加上路径, 但最好的方法是把一个路径告诉 make, 让 make 自动去查找.


Makefile 文件中的特殊变量 `VPATH` 就是完成这个功能的, 如果没有指明这个变量, make 只会在 `当前的目录` 中去找
寻依赖文件和目标文件. 如果定义了这个变量, make 就会在当前找不到的情况下, 到所指定的目录中去找寻文件了.


```
VPATH = src:../headers
```

上面的定义指定两个目录, "src" 和 "../headers", make 会按照这个顺序进行搜索. 目录由 "冒号"(`:`) 分
隔. 


另一个设置文件搜索路径的方法是使用 make 的 `vpath` 关键字. 它可以指定不同的文件在不同的搜索目录中. 它
的使用方法有三种:

```
1. vpath <pattern> <directories>

为符合 <pattern> 的文件指定搜索目录 <directories>

2. vpath <pattern>

清除符合 <pattern> 的文件的搜索目录

3. vpath

清除所有已经设置好了的文件搜索目录
```

> vpath 使用方法中的 <pattern> 需要包含 `%` 字符串. `%` 的意思是匹配零或若干字符串. 例如 `%.h` 表示所有以
> `.h` 结尾的文件. <pattern> 指定了要搜索的文件集, 而 <directories> 指定了 <pattern> 的文件集的搜索目录.

```
vpath %.h ../headers
```

> 要求 make 在 "../headers" 目录下搜索所有以 `.h` 结尾的文件. (如果某文件在当前目录下没有找到的话)



### 伪目标

"伪目标" 并不是一个文件, 只是一个标签, 由于 "伪目标" 不是文件, 所以 make 无法生成它的依赖关系和决定它是否要执行.
只有显示地指明这个 "目标" 才能让其生效. 当然, "伪目标" 的取名不能和文件名重名, 不然就失去了 "伪目标" 的意义了.

为了避免和文件重名的这种情况, 可以使用一个特殊的标记 ".PHONY" 来显示地声明一个目标是 "伪目标", 向 make 说明, 不
管是否有这个文件, 这个目标就是 "伪目标".

```makefile
.PHONY: clean
clean:
	rm -rf *o
```

伪目标一般没有依赖的文件. 但是, 可以为伪目标指定依赖的文件. 伪目标同样可以作为 "默认目录", 只要将其放在第一个.

例如: 如果 Makefile 需要生成多个可执行文件, 但是只想简单地执行 make 完事, 并且, 所有的目标文件都写在一个 
Makefile 中, 可以使用 "伪目标" 的特性:

```makefile
all: exe1 exe2
.PHONY: all

exe1: exe1.o
    cc -o exe1 exe1.o
exe2: exe2.o
	cc -o exe2 exe2.o
```

### 静态模式

静态模式可以更容易地定义多目标的规则, 可以让规则变得更加有弹性和灵活.

```
<targets ...> : <target-pattern> : <prereq-patterns ...>
    <commands>
    ...
```

targets 定义一系列的目标文件, 可以使用通配符. 是一个目标的集合.

target-pattern 是指明了 targets 的模式, 也就是目标集模式.

prereq-patterns 是目标的依赖模式,它对 target-pattern 形成的模式再进行一次依赖目标的定义.

例如, <target-pattern> 定义为 `%.o`, 表示 target 集合中都是以 `.o` 结尾的, <prereq-patterns> 定义成 
`%.c`, 意思是对 <target-pattern> 所形成的目标集进行二次定义, 其计算方法是取 <target-pattern> ,模式中的
`%`(也就是去掉了 `.o` 这个结尾), 并为其加上 `.c` 这个结尾, 形成新集合.


```makefile
objects = foo.o bar.o

all:$(objects)

$(objects) : %.o : %.c
	$(CC) -c $(CFLAGS) $< -o $@
```

目标是从 $objects 中获取, `%.o` 表面所有以 `.o` 结尾的目标(也就是 `foo.o bar.o`), 而依赖模式 `%.c` 则取模
式 `%.o` 的 `%`, 也就是 `foo bar`, 并为期其加上 `.c` 的后缀, 于是, 依赖的目标就是 `foo.c bar.c`.

命令中的 `$<` 和 `$@` 是自动化变量, `$<` 表示第一个依赖文件, `$@` 表示目标集合(`foo.o bar.o`)

等价形式

```makefile
foo.o : foo.c
    $(CC) -c $(CFLAGS) foo.c -o foo.o
bar.o : bar.c
	$(CC) -c $(CFLAGS) bar.c -o bar.o
```


例子:

```makefile
files = foo.elc bar.o lose.o

$(filter %.o,$(files)) : %.o : %.c
    $(CC) -c $(CFLAGS) $< -o $@
$(filter %.elc,$(files)) : %.elc : %el
	emacs -f batch-byte-compile $<
```

`$(filter %.o,$(files))` 表示调用 Makefile 的 filter函数, 过滤 `$(files)` 集, 只有其中模式为 `%.o` 的内
容.



### 自动生成依赖性

在 Makefile 中, 依赖关系可能会包含一系列的头文件, 比如 main.c 中的 `#include "defs.h"`, 依赖关系是:

```
main.o : main.c defs.h
```

大的工程项目, 这种依赖关系很难在Makefile当中维护. 为了避免这种问题, 大多数 C/C++ 编译器都支持一个 `-M` 的选项, 即
自动找寻源文件中包含的头文件, 并生成依赖关系.

```
cc -M main.c
```

其输出是:
```
main.o : main.c defs.h
```

由于编译器自动生成的依赖关系, 这样就不必手写文件的依赖关系了.

> GNU 的 C/C++ 编译器, 得使用 `-MM` 参数. (`-M` 参数会把一些标准库的头文件也包含进来)


如何在 Makefile 当中使用该特性?

GNU 组织建议把编译器为每一个源文件的自动生成的依赖关系放到一个文件中, 为每一个 `name.c` 的文件都生成一个 `name.d` 的
Makefile 文件, `.d` 文件中存放对应 `.c` 文件的依赖关系.

于是, 可以写出 `.c` 文件 和 `.d` 文件的依赖关系, 并让 make 自动更新或生成 `.d` 文件, 并把其包含在主 Makefile 中,
这样就可以自动化地生成每个文件的依赖关系了.

```
%.d : %.c
    @set -e; rm -f $@; \
    $(CC) -M $(CFLAGS) $< > $@.$$$$; \
    sed "s,\($*\)\.o[ :]*,\1.o $@ :,g" < $@.$$$$ > $@; \
    rm -f $@.$$$$
```

所有的 `.d` 文件依赖于 `.c` 文件, `rm -rf $@` 是删除所有的目标文件.
`$(CC) -M $(CFLAGS) $< > $@.$$$$` 为每个依赖文件 `$<` (`.c`文件) 生成依赖文件(`.d` 文件). `$$$$` 表示随机号
`sed "s,\($*\)\.o[ :]*,\1.o $@ :,g < $@.$$$$ > $@`



于是, 将 `.d` 文件加入到主 Makefile 当中.

```
sources = foo.c bar.c

include	$(sources:.c=.d)
```

`$(sources:.c=.d)`, `.c=.d` 意思是做一个替换, 把变量 `$(sources)` 所有的 `.c` 的字符串替换成 `.d`


## 书写命令



