# makefile 编译

## makefile 规则

```
target ... : prerequisities ...
    command
    ...
    ...
```

target, 可以是一个 object file(目标文件), 也可以是一个执行文件, 还可以是一个标签(label). 对于标签这种特性, 在后续
的 `伪目标` 中有介绍.

prerequisites, 生成该 target 所依赖的文件或target

command, 该target要执行的命令(任意的shell命令)

> 这是一个文件的依赖关系, 也就说, target 这一个或多个的目标文件依赖于 prerequisites 中的文件, 其生成规则定义在 
command 中.


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


案例: (make自动推倒)
```makefile
objects = main.o command.o

edit : $(objects)
	cc -o edit $(objects)

# 可以省略
main.o : main.c
command.o : command.c

clean :
	rm edit $(objects)
```

### 引用其他的 Makefile

在 Makefile 使用 `include` 关键字可以把别的 Makefile 包含进来, 这很像 C 语言的 `#include`, 被包含的文件会原模原
样的放在当前文件的包含位置. 

```
include <filename>
```

> `filename` 可以是当前操作系统 shell 的文件模式 (可以包含路径和通配符). 
>
> 在 `include` 前面可以有一些空字符, 但是绝对不能是 `TAB` 键开始. `include` 和 `<filename>` 可以用一个或多个空格
隔开.

```makefile
bar = e.mk f.mk
include foo.make *.mk $(bar)
```

make 命令开始时, 会寻找 `include` 所指出的其他 Makefile, 并把其内容安置到当前的位置. 如果文件没有指定绝对路径或者相
对路径的话, make 会在当前目录下首先寻找, 如果当前目录没有找到, 那么, make 会在以下几个目录查找:

1. 如果make执行时, 有 `-I` 或 `--include` 参数, 那么 make 就会在这个参数所指定的目录下去寻找.

2. 如果目录 `<prefix>/include` (一般是: `/usr/local/bin` 或 `/usr/include`) 存在的话, make 也会去找.

如果没有找到文件的话, make 会产生一条警告信息, 但是不会马上出现致命错误. 它会继续载入其他的文件, 一旦完成 makefile 的
读取, make 会再重试这些没有找到, 或者不能读取的文件, 如果还是不行, make才会出现一条致命信息.

## 规则

规则包含两个部分: 一个是"依赖关系", 一个是"生成目标的方法".

在 Makefile 中, 规则的顺序很重要. 因为 Makefile 中只应该有一个最终目标, 其他的目标都是被目标这个目标所带出来的, 所以
一定要让 make 知道你的最终目标是什么. 一般来说, 定义在 Makefile 中的目标可能会有很多, 但是第一条规则中目标将被确定为最
终的目标. `如果第一条规则中的目标有很多个, 那么第一个目标目标就会成为最终的目标.`

### 规则的语法

```
target : prerequisities 
    command
    ...
```

target 是文件名, 以空格分开, `可以使用通配符`. 一般来说, 目标基本上是一个文件, 但也有可能是多个文件.

command 是命令行, 必须以 `TAB` 键开头.

prerequisities 是目标所依赖的文件(或依赖目标). 如果其中的某个文件要比目标要新, 那么, 目标就被认为是 "过时的", 被认为
是需要重生成的.

> **如果命令太长, 可以使用反斜线 `\` 作为换行符.**
> **一般来说, make 会以 UNIX 的标准 Shell, 也就是 `/bin/sh` 来执行命令.**


### 在规则当中使用通配符

make 支持三个通配符: `*`, `?` 和 `~`. 这是和 Unix 的 B-Shell 是相同的.

波浪号 `~` 字符在文件名中也有比较特殊的用途. 如果是 `~/test`, 这就表示当前用户的 `$HOME` 目录下的 test 目录. 而 
`~hchen/test` 表示用户 hchen 的宿主目录下的 test 目录. (这些是 Unix 小知识, make 也支持)

通配符代表了一系列的文件, 如 `*.c` 表示所有后缀为 c 的文件.

Makefile 中的变量其实就是 C/C++ 中的宏. 如要让通配符在变量中展开, 也就是让 `*.c` 表示所有 `.c` 的文件名的集合, 那么:

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

在大的工程中, 有大量的源文件, 通常的做法是把这许多的源文件分类, 并存放在不同的目录中. 所以, 当 make 需要找寻文件的依赖
关系时, 可以在文件前加上路径, 但最好的方法是把一个路径告诉 make, 让 make 自动去查找.


Makefile 文件中的特殊变量 `VPATH` 就是完成这个功能的, 如果没有指明这个变量, make 只会在 `当前的目录` 中去找寻依赖文
件和目标文件. 如果定义了这个变量, make 就会在当前找不到的情况下, 到所指定的目录中去找寻文件了.


```
VPATH = src:../headers
```

上面的定义指定两个目录, "src" 和 "../headers", make 会按照这个顺序进行搜索. 目录由 "冒号" (`:`) 分隔. 


另一个设置文件搜索路径的方法是使用 make 的 `vpath` 关键字. 它可以指定不同的文件在不同的搜索目录中. 它的使用方法有三种:

```
1. vpath <pattern> <directories>

为符合 <pattern> 的文件指定搜索目录 <directories>

2. vpath <pattern>

清除符合 <pattern> 的文件的搜索目录

3. vpath

清除所有已经设置好了的文件搜索目录
```

> vpath 使用方法中的 <pattern> 需要包含 `%` 字符串. `%` 的意思是匹配零或若干字符串. 例如 `%.h` 表示所有以 `.h` 结
尾的文件. <pattern> 指定了要搜索的文件集, 而 <directories> 指定了 <pattern> 的文件集的搜索目录.

```
vpath %.h ../headers
```

> 要求 make 在 "../headers" 目录下搜索所有以 `.h` 结尾的文件. (如果某文件在当前目录下没有找到的话)

### 伪目标

"伪目标" 并不是一个文件, 只是一个标签, 由于 "伪目标" 不是文件, 所以 make 无法生成它的依赖关系和决定它是否要执行. 只有
显示地指明这个 "目标" 才能让其生效. 当然, "伪目标" 的取名不能和文件名重名, 不然就失去了 "伪目标" 的意义了.

为了避免和文件重名的这种情况, 可以使用一个特殊的标记 ".PHONY" 来显示地声明一个目标是 "伪目标", 向 make 说明, 不管是否
有这个文件, 这个目标就是 "伪目标".

```makefile
.PHONY: clean
clean:
	rm -rf *o
```

伪目标一般没有依赖的文件. 但是, 可以为伪目标指定依赖的文件. 伪目标同样可以作为 "默认目录", 只要将其放在第一个.

例如: 如果 Makefile 需要生成多个可执行文件, 但是只想简单地执行 make 完事, 并且, 所有的目标文件都写在一个 Makefile 中, 
可以使用 "伪目标" 的特性:

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

例如, <target-pattern> 定义为 `%.o`, 表示 target 集合中都是以 `.o` 结尾的, <prereq-patterns> 定义成 `%.c`, 
意思是对 <target-pattern> 所形成的目标集进行二次定义, 其计算方法是取 <target-pattern>, 模式中的 `%`(也就是去掉了 
`.o` 这个结尾), 并为其加上 `.c` 这个结尾, 形成新集合.


```makefile
objects = foo.o bar.o

all: $(objects)

$(objects) : %.o : %.c
	$(CC) -c $(CFLAGS) $< -o $@
```

目标是从 $objects 中获取, `%.o` 表面所有以 `.o` 结尾的目标(也就是 `foo.o bar.o`), 而依赖模式 `%.c` 则取模式 `%.o` 
的 `%`, 也就是 `foo bar`, 并为期其加上 `.c` 的后缀, 于是, 依赖的目标就是 `foo.c bar.c`.

命令中的 `$<` 和 `$@` 是自动化变量, `$<` 表示第一个依赖文件, `$@` 表示目标集合(`foo.o bar.o`)

等价形式:
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

`$(filter %.o,$(files))` 表示调用 Makefile 的 filter函数, 过滤 `$(files)` 集, 只有其中模式为 `%.o` 的内容.


### 自动生成依赖性

在 Makefile 中, 依赖关系可能会包含一系列的头文件, 比如 main.c 中的 `#include "defs.h"`, 依赖关系是:

```
main.o : main.c defs.h
```

大的工程项目, 这种依赖关系很难在Makefile当中维护. 为了避免这种问题, 大多数 C/C++ 编译器都支持一个 `-M` 的选项, 即自动
找寻源文件中包含的头文件, 并生成依赖关系.

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
sources := foo.c bar.c

include	$(sources:.c=.d)
```

`$(sources:.c=.d)`, `.c=.d` 意思是做一个替换, 把变量 `$(sources)` 所有的 `.c` 的字符串替换成 `.d`

## 命令

通常, make 会把其要执行的命令行在命令执行输出到屏幕上. 当使用 `@` 字符在命令行前, 那么, 这个命令将不被 make 显示出来.

```
@echo 'xxxx'
```

如果 make 执行时, 带入参数 `-n` 或者 `--just-print`, 那么只是显示命令, 但不执行命令. 而 make 参数 `-s` 或 `--slient` 
或 `--quite` 则是全面禁止命令的显示.

## 变量

变量在声明时候需要给予初始值, 而在使用时, 需要在变量名前添加 `$` 符号, 最好用小括号 `()` 或者大括号 `{}` 将变量名包括
起来. 如果要使用真实的 `$` 符号, 需要使用 `$$` 来表示.

### 变量中的变量

在定义变量的值的时, 可以使用其他变量来构造变量的值, 在 Makefile 中有两种方式用变量定义变量的值.

方式一: 使用 `=`

```
foo = $(bar)
bar = $(ugh)
ugh = Hug?

all:
    echo $(foo)
```

> 这种方式, 右侧的变量可以是后面定义的值.

方式二: 使用 `:=`

```
x := foo
y := $(x) bar
x := later
```

等价于:

```
y := foo bar
x := later
```

> 这种方式, 前面的变量不能使用后面的变量, 只能使用前面已经定义好了的变量

### 变量的高级用法

- 变量值的替换

替换变量值中的共有部分, 格式是 `$(var:a=b)`, 把变量 "var" 中所有以 "a" 字串 "结尾" 的 "a" 替换成 "b" 字串.

> `结尾` 意思是 "空格" 或是 "结束符"

```makefile
foo := a.o b.o c.o
bar := $(foo:.o=.c)
```

> bar的值是 `a.c b.c c.c`

"静态模式" 变量替换

```makefile
foo := a.o b.o c.o
bar := $(foo:%.o=%.c)
```

- 把变量的值再当成变量

```makefile
y = z
x = y
a := $($(x))
```

> $(x) 的值是 "y", $($(x)) 的值就是 $(y), 也就是 "z"


- 追加变量的值

使用 `+=` 操作符给变量追加值

```makefile
objects = main.o foo.o
objects += bar.o
```

> $(objects) 的值就是 "main.o foo.o bar.o"

- override (变量覆盖)

如果有变量是通常 make 的命令行参数设置的, 那么 Makefile 中对这个变量的值会被忽略. 如果想在 Makefile 中设置这类参数的
值, 可以使用 `override` 指示符.

```makefile
override <var> = <value>;
override <var> := <value>;

override <var> += <more text>;
```

- 多行变量

设置变量值的另一种方法是使用 `define` 关键字. 使用 `define` 关键字设置变量的值可以有换行.

define 指示符后面跟的是变量的名字, 而重起一行定义变量的值, 定义以 endef 关键字结束. 其工作方式和 "=" 操作符一样. 变量
的值可以包含函数, 命令, 文字, 或是其他变量.

```makefile
define two
echo bar
echo $(bar)
endef
```

- 环境变量(全局变量)

make 运行时的系统环境变量可以在make开始运行时被载入到 Makefile 文件中, 但是如果 Makefile 中已经定义了这个变量, 或者
这个变量是由 make 命令行参数带人的, 那么系统的环境变量的值将被覆盖.

在运行 make 时指定 "-e" 选项, 优先使用环境变量.

```makefile
LANGUAGE := other
test:
	@echo "LANGUAGE => $(LANGUAGE)"
```

输出:

```
$ echo $LANGUAGE
zh_CN
$ make test 
LANGUAGE => other
$ make -e test 
LANGUAGE => zh_CN
```

- 目标变量(局部变量)

前面所讲的在 Makefile 中定义的变量都是 "全局变量", 在整个文件, 都可以访问到这些变量. 当然, "自动化变量" 除外, 如 `$<` 
等这种变量的值依赖于规则的目标和依赖目标的定义.

作用域只在指定目标以及连带规则当中的变量称为局部变量.

局部变量模式:
```
target : name = value
target : override name = value
```

1) 目标变量, 无依赖关系:
```makefile
var := var_start
test : var := var_test

test:
	@echo "test: var => $(var)"

another:
	@echo "another: var => $(var)"
```

输出:
```
$ make test 
test: var => var_test
$ make another 
another: var => var_start
```

2) 目标变量, 连带依赖:
```makefile
var := var_start
test : var := var_test

test: another
	@echo "test: var => $(var)"

another:
	@echo "another: var => $(var)"
```

输出:
```
$ make test 
another: var => var_test
test: var => var_test
$ make another 
another: var => var_start
```

> 在这种局部变量执行时, 先执行 target 局部变量, 然后执行 target 的命令块.

- 模式变量

模式变量是目标变量的扩展(也是局部变量).

模式变量的作用域只在符合模式的目标及连带规则中.

```
<pattern> : name = value
<pattern> : override name = value
```

1) 模式变量, 无依赖关系
```makefile
new := new_start
%e : override new := new_test

test:
	@echo "test: new => $(new)"

another:
	@echo "another: new => $(new)"

rule:
	@echo "rule: new => $(new)"
```


输出:
```
$ make test
test: new => new_start
$ make another 
another: new => new_start
$ make rule 
rule: new => new_test
```

2) 模式变量, 连带依赖
```makefile
new := new_start
%e : override new := new_test

test: rule
	@echo "test: new => $(new)"

another:
	@echo "another: new => $(new)"

rule:
	@echo "rule: new => $(new)"
```

输出:
```
$ make test 
rule: new => new_test
test: new => new_start
$ make another 
another: new => new_start
$ make rule 
rule: new => new_test
```

> 模式变量, 只能在匹配的模式 target 作用域内改变相关的值, 不能改变其他 target 作用域的值(即使有依赖关系).

- 变量在不同makefile之间传递的方式

1) 调用 make 时, 使用 KEY=VALUE 的方式

2) 在当前的 makefile 当中使用 export 导出要传递的变量.

## 使用条件判断

```makefile
libs_for_gcc = -l gnu
normal_libs =

foo: $(objects)
ifeq ($(CC),gcc)
	$(CC) -o foo $(objects) $(libs_for_gcc)
else
	$(CC) -o foo $(objects) $(normal_libs)
endif
```

目标 `foo` 根据变量 `$(CC)` 值来选取不同的函数库来编译程序.

## 使用函数

函数的调用语法:

```
$(<function> <args>)
```

shell 函数, 用于执行 shell 命令. 格式: `$(shell <cmd>)`

### 字符串处理函数

- subst

```
$(subst <from>,<to>,<text>)
```

字符串替换函数. 把字符串 <text> 中的 <from> 字串替换成 <to>

- patsubst

```
$(patsubst <pattern>,<replacement>,<text>)
```

模式字符串替换函数. 查找 <text> 中的单词(单词以 "空格", "Tab" 或 "换行" 分割) 是否符合模式 <pattern>, 如果匹配,
则以 <replacement> 替换. `<pattern>` 可以包含通配符 `%`(任意长度的字符串), `<replacement>` 中也包含 `%`, 那
么 `<replacement>` 中的这个 `%` 就是 `<pattern>` 中的那个 `%` 所代表的字串.


- strip

```
$(strip <string>)
```

去掉 <string> 字串中开头和结尾的空字符


- findstring

```
$(findstring <find>,<in>)
```

在 <in> 当中查找 <find> 字串


- filter 

```
$(filter <pattern ...>, <text>)
```

以 <pattern> 模式过滤 <text> 字符串中的单词, 保留符合 <pattern> 的单词. 可以有多个模式.


- filter-out

```
$(filter-out <pattern ...>, <text>)
```

以 <pattern> 模式过滤 <text> 字符串中的单词, 去除符合 <pattern> 的单词.


- sort

```
$(sort <list>)
```

给字符串 <list> 中的单词排序(升序)

- word

```
$(word <n>,<text>)
```

取字符串 <text> 中第 <n> 个单词. (从1开始)


- wordlist

```
$(wordlist <ss>,<e>,<text>)
```

取字符串 <text> 中第 <ss> 开始到 <e> 的单词.

- words

```
$(words <text>)
```

统计 <text> 中字符串的单词个数

- firstword

```
$(firstword <text>)
```

### 文件名操作函数

- dir

```
$(dir <names ...>)
```

从文件名序列 <names> 中取出目录部分.


- notdir

```
$(notdir <names ...>)
```

获取文件名字

- suffix

```
$(suffix <names ...>)
```

从文件名序列 <names> 中取出各个文件名的后缀

- addsuffix

```
$(addsufix <suffix>, <names ...>)
```

把后缀 <suffix> 加到 <names> 中的每个单词的后面

- addprefix

```
$(addprefix <prefix>, <names ...>)
```

把后缀 <prefix> 加到 <names> 中的每个单词的前面


- join 

```
$(join <list1>,<list2>)
```

把 <list2> 中的单词对应地加到 <list1> 的单词后面. 如果 <list1> 的单词个数比 <list2> 多, 那么 <list1> 中多
出来的单词保持原样. 如果 <list2> 的单词个数比 <list1> 多, 那么, <list2> 多出来的单词将被复制到 <list1> 中.


- foreach

```
$(foreach <var>,<list>,<text>)
```

Makefile 当中的 `foreach` 函数几乎是仿照于 Unix 标准 Shell 的 `for` 语句.

把参数 <list> 中的单词逐一取出放到变量 <var> 所指定的变量中, 然后再执行行 <text> 所包含的表达式. 每一次 <text> 
都会返回一个字符串, 循环过程中, <text> 的的所返回的每个字符串会以空格分割, 最后当整个循环结束时, <text> 所返回的每
个字符串所组成的整个字符串(以空格分割)将会是foreach函数的返回值.

```makefile
names := a b c d

files := $(foreach n,$(names),$(n).o)
```

- if 

```
$(if <condition>, <then-part>)

$(if <condition>, <then-part>, <else-part>)
```

- call 

call 函数是唯一一个可以用来创建新的参数化的函数. 

````
$(call <expression>,<param1>,<param2>,...<paramn>)
````

当 make 执行这个函数时, <expression> 参数中的变量, 如 $(1), $(2) 等, 会被参数 <param1>, <param2> 依次取代.
而 <expresssion> 的返回值就是 call 函数的返回值.

```
reverse = $(1) $(2)

foo = $(call reverse,a,b)
```

上面函数的返回值是 `a b`

- origin

origin 函数不会操作变量的值, 它只是返回这个变量是哪里来的

```
$(origin <var>)
```

> `<var>` 是变量的名字, 不应该是引用.

返回值有:

`undefined`, <var> 从来没有定义过

`default`, <var> 是一个默认的定义, 比如  CC 这个变量

`environment`, <var> 是一个环境变量

`file`, <var> 这个变量被定义在 Makefile 中

`command line`, <var> 是被命令行定义的

`override`, <var> 是被 override 指示符重新定义的

`automatic`, <var> 是一个运行命令重点自动化变量
