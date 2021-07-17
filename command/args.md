## linux 下命令行解析

### shell 下命令行解析

shell 下提供解析命令参数的命令有两个 getopts(内置命令) 和 getopt (系统命令), 其中 getopts 只能解析基本的命令选项(
只支持短选项, 例如 `-c`, `-h` 等), getopt 可以解析长选项和短选项, 更为强大. 


getopt的命令形式:

```
getopt <optstring> <parameters>
getopt [options] -o|--options <optstring> [--] <parameters>
```

其中 `<optsring>` 是短命令选项字符串, `<parameters>` 是命令参数.

常用的 options 选项包括:

- `-o, --options <optstring>` 表示短命令选项(单个字母作为一个选项)
- `-l, --longoptions <longopts>` 表示长命令选项(一个单词作为命令选项, 需要使用符号 "," 进行分割)
- `-n, --name <program>` 应用程序名称

什么是命令选项?

命令选项, 就是在执行命令的时候提供的参数. 例如 `curl -h`, 当中的 `-h` 就是一个选项, 表示打印当前的 curl 的版本. 命令
选项有长短之分, 短命令选项一 `-` 开头, 长命令选项以 `--` 开头. 长的命令选项往往是一个单词, 更容易解释参数的含义, 短的命
令选项就是一个简称. 

命令选项例子:

```
短命令选项 "hc:x::"

长命令选项 "help,code:,x-long"

解析: -h, --help
     -c, --code CODE
     -x, --x-long [XX]
```

命令选项含义(在表示同一参数时, 长,短命令选项格式上需要保持统一)

a   表示选项 a 没有参数. 合法格式: -a 或 --a-long

a:  表示选项 a 必须有一个参数. 合法格式: -a22 或 -a 22 或 --a-long=22 或 --a-long 22

a:: 表示选项 a 可以有参数, 也可以没有参数. 合法格式: -a22 或 --a-long=22

> 注: 上面的 -a 表示短选项, --a-long 表示长选项. 在后续的处理过程中需要遵照参数.


完整的案例:

```bash
TEMP=`getopt --options ab:c:: --longoptions a-long,b-long:,c-long:: \
     -n 'param.bash' -- "$@"`
if [[ $? != 0 ]]; then
    echo "Terminating..." >&2
    exit 1
fi

# ${TEMP} 的输出格式为 arg1 [val1] arg2 [val2]
# set 会重新设置 shell 的命令参数, 使其形式统一格式为 arg1 [val1] arg2 [val2] ..., 为后面参数解析打基础.
set -- ${TEMP}


while true ; do
    case "$1" in
        -a|--a-long)
            echo "Option a"
            shift ;;
        -b|--b-long)
            echo "Option b, argument [$2]"
            shift 2 ;;
        -c|--c-long)
            case "$2" in
                "")
                    echo "Option c, no argument" # 没有参数
                    shift 2 ;;
                *)
                    echo "Option c, argument [$2]" # 带有参数
                    shift 2 ;;
             esac ;;
        --)
            shift
            break ;;
        *)
            echo "Internal error!" ;
            exit 1 ;;
    esac
done


echo "other arguments:"
for arg do
   echo "--> [$arg]"
done
```

### C 库命令行解析

命令选项参数解析:

```C
头文件: <getopt.h>

函数:
int getopt_long(int argc, char* const argv[], const char *optstring,
				const struct option *longopts, int *longindex);

argc: 命令参数个数
argv: 命令行参数
optstring: 短选项参数字符串(与前面的shell当前 getopt 的短选项参数是一致的)
longopts: 长选项参数配置
longindex: 当前参数在长选项参数配置当中的索引.

返回值: 等于0表示成功


option 结构体:

struct option {
    const char *name;    // 长选项名称
    int         has_arg; // 三个值, 0表示没有参数值, 1表示必须有参数值, 2表示可以有参数值,也可以没有参数值
    int        *flag;    // 一个标记位(默认参数值)
    int         val;     // 值, 一般选择短选项字符, 如果没有短选项, 填写 0
}

当调用此函数后, 会通过 `optarg` 设置当前参数的值(如果有参数值的状况下)
```
