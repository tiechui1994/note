# 变量

### 变量声明与定义

- 使用 `declare`

```bash
# 定义一个只读的变量(变量只能使用, 无法更新和删除), 需要定义的时候立即初始化
declare -r x=100

# 定义一个数组/字典
## 声明一个数组/字典
declare -A any
declare -A any=()

## 声明并且初始化一个字典/数组
declare -A map=(['java']=1 ['css']=2 ['go']=3)
declare -A arr=([1]='java' [2]='css' [3]='go')
declare -A arr=('java' 'css' 'go')

# 定义一个数值类型的变量
declare -i int=10    # int 的值是 10
declare -i int='1+1' # int 的值是 2
declare -i int='A'   # int 的值是 0

# 定义一个环境变量. 可供shell以外的程序使用
declare -x CMD='/bin/bash'
```


- 直接定义赋值

```bash
A=100
```

### 修改变量

- 修改变量为只读

```bash
readonly VAR
```

> VAR 是变量名称. 使用 readonly 将变量定义为只读, 只读意味着不能改变.

- 删除变量

```bash
unset VAR
```

> VAR 是变量名称. 使用 unset 删除变量, 变量删除以后不能再次使用, 且不能删除只读变量.

- 变量的使用

这个应该是非常常见的, 一般推荐的做法如下:

1. 在带双引号的字符串当中使用 `$var` 的形式获取变量值.

2. 在其他状况下, 推荐使用 `${var}` 的形式获取变量的值.

> 上述两条规则是 Shell 编程的标准规范. 在一些特殊的变量名称(变量名称带有 `_`), 全部使用 `${var}` 的方式去获取变量的
值, 这样会避免出现一些莫名奇怪的错误.


### 位置参数变量

- `$n`: `$0` 代表命令本身, `$1`-`$9` 代表第1到9个参数, 10以上参数要使用大括号`{}`, 例如: `${11}`
- `$*`: 命令行所有参数, 且把所有参数看为一个整体.
- `$@`: 命令行所有参数, 且把每个参数区分对待.
- `$#`: 所有参数个数.

> `$?` 这个代表的是函数/脚本的返回值. 如果函数/脚本正常返回, 则值为0, 如果函数当中有return语句或者异常, 则返回值是非0
> `$$` 这个代表的是当前进程的PID
> `$!` 这个代表后台运行的最后一个进程的PID, 一般不常用.
>
> 注意: `$0` 代表当前执行的脚本/程序. `$#` 是参数个数, 从参数 `$0` 之后开始算起(不包括`$0`), 使用空格(至少是一个)进
行分割开. 例如 `bash arg.sh 11 22 33`, 其中 `$0` 是 `arg.sh`, 参数的个数 `$#` 是 3. 同理 `sudo arg.sh 11 22 33 44`,
`$0` 也是 `arg.sh`, 参数个数 `$#` 是 4.
