## awk

awk介绍:

awk是linux shell 编程的三剑客(grep, sed, awk)之一, awk是强大的文本分析工具. 相对于grep的查找, sed的编辑, awk在
其对数据分析并生成报告时, 显得尤为强大.

简单来说awk就是把文件逐行的读入, 以空格为默认分隔符将每行切片, 切开的部分再进行各种分析处理.


awk三种调用方式:

1. 命令行方式

```
awk 'bash' input-file(s)
```


2. shell脚步方式

```
将所有的awk命令插入一个文本, 并使用awk命令解释器执行
使用 `#!/bin/awk` 替换 `#!/bin/bash`
```
   
3. 将所有的awk命令插入一个单独文件,然后调用

```
awk -f awk-script input-file(s)
```

### awk 使用

语法:

```
awk [OPTIONS] 'pattern {action}' file
```

说明: BEGIN是开始控制; END是结束控制, 中间的是遍历的行控制

- OPTIONS:

1) `-F s`, 设置域分隔符
2) `-v var=value` 为程序添加外部参数变量, 可以设置多个.
3) `--`, 表示可选选项结束


AWK程序是一系列 `pattern {action} 对` 和 `用户函数定义`.

一个patern可以是:

```
BEGIN  # 只执行一次, 一般是变量初始化
END    # 只执行一次, 一般是统计, 清除工作
expression
expression, expression
```

一个action是一段可执行的代码.

`pattern {action}`, 两者中可以省略一个, 但不能都被省略. 如果省略 `{action}`, 则隐示使用 `{print}`; 
如果 `pattern` 被省略, 则对文本全匹配. `BEGIN` 和 `END` 模式需要一个动作. 可执行语句由 `换行符`,`分号`或两者终止.

例子:

```
awk '/awk/ {print $1}; /www/ {print $1}' // 其中 "/awk/" 与 "$0 ~ /awk/" 是等价的
awk '/awk/' // 省略了 action
awk '{print $1}' // 省略了 pattern
awk 'BEGIN {print}' // 特殊的 pattern, BEGIN
```


- express(正则匹配):

注: express 表达式可以为 `pattern`, 也可以是 `action` 执行代码当中的内容.

```
expr ~ /regex/
$0 ~ /regex/  <=> /regex/

regex: ^ $ . [ ] | ( ) * + ?   # 正则表达式支持的字符
```


- action(语法):

常见的 if, for, while 等表达式.

```
if ( expr ) statement
if ( expr ) statement else statement
while ( expr ) statement
do statement while ( expr )
for ( opt_expr ; opt_expr ; opt_expr ) statement
for ( var in array ) statement
```

例如:

```bash
awk '{
   if ( $0 ~ /www/ ) {
      print("Host")
   } else if ( $0 ~ /google.comm/ ) {
      print("Google")
   } else {
      print("Other")
   }
   
   if ( NR==10 || NF>9 ) {
      print("======================")
   }
}' /etc/password
```

> 上面只是以 if 的条件举例, `while`, `for` 的条件也是类似的.


- express and operators:

注: 主要是支持的操作符号. 

```
assignment: +=, -=, *=, /=, %=, ^=, =

三元表达式: ?, :

逻辑运算: ||, &&

正则匹配: ~, !~ 

数组关系: in

大小关系: <, >, <=, >=, ==, != 

数字运算: +, -, *, /, %

inc and dec: ++, --

filed: $
```


- 内置参数(可以直接使用):

```
ARGC 命令行参数个数
ARGV 命令行参数排列
ENVIRON 支持队列中系统环境变量的使用
FILENAME awk正在打开的文件名
FNR 已经浏览文件的记录数(一般和NR相同)

NR 当前正在读取的行号
NF 当前行的field的个数

FS 设置输入filed分隔符, 等价于命令行 -F 选项, 默认值是 ' '
RS 文件行分隔符, 默认是 '\n'

OFS 输出filed分隔符, 默认 ' '
ORS 输出行分隔符, 默认 '\n'

$0 当前行所有内容
$N 当前行第N个field
```

案例:

```bash
awk '{ 
   if ( NR==10 || NF>9 ) {
      print(NR, "======================")
   }
}' /etc/password

awk '/sh/ && /root/ {print $1}' /etc/passwd
```

- 内置函数(在action当中使用):

```
gsub(regex, str, repl) 全局替换, 使用repl替换regex匹配的字符串
sub(regex, str, repl) 只替换第一个
index(str, sub)
length(str)
match(str, regex)
split(str, array, separator), split(str, array)此时separator为FS
substr(str, index, length)
tolower(str)
toupper(str)
```


- awk 传入参数:

```bash
awk -v var=${value} '{}' file
awk '{}' var=${value} file

declare $(awk '{}')
```

> 注: 如果外部变量是字符串, 使用方式是 `var="$arg"`, 以避免奇怪的错误.

前两种方式, 向awk传入参数, 在awk内部使用, 但是无法修改外部参数的值
最后一种方式, 既可以使用外部参数, 又可以修改外部参数 (使用 print 拼接修改).

```bash
v=100
declare $(awk '{ print "v="1000 }' ./awk.sh)
echo ${v}

w=1
awk -v w=${w} '{ print(w); }' ./awk.sh
echo ${w}
```

## 案例

这个案例是修改 `sshd_config` 当中的内容, 如果正则匹配, 则进行修改, 最后的没有匹配到的内容, 进行追加操作 ( `END` 模式)

```bash
sshd_config() {
    awk -v challege=0 -v usepam=0 -v methods=0 '
    {
       if ( /^[#]?[\s]*ChallengeResponseAuthentication/ ) {
          print("ChallengeResponseAuthentication yes")
          challege=1
       } else if ( /^[#]?[\s]*UsePAM/ ) {
          print("UsePAM yes")
          usepam=1
       } else if ( /^[#]?[\s]*AuthenticationMethods/ ) {
          print("AuthenticationMethods publickey,keyboard-interactive")
          methods=1
       } else {
          print($0)
       }
    };
    END {
        print(challege, usepam, methods)
        if ( challege==0 ) {
            print("ChallengeResponseAuthentication yes")
        }
        if ( usepam==0 ) {
            print("UsePAM yes")
        }
        if ( methods==0 ) {
            print("AuthenticationMethods publickey,keyboard-interactive")
        }
    }' /tmp/sshd_config > /tmp/sshx
}
```