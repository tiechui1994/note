## Shell 循环

shell 当中循环命令存在三种, 分别是: for, while 和 until. for和while属于"当型循环", until属于"直到型循环".

> **注意: 在循环结构体作用域内要想修改外部作用域的变量, 需要使用 `let` 命令. 否则修改无效.**

### for 循环

for 循环有三种结构: 列表for循环, 不带列表for循环, 类C风格的for循环.

- 列表for循环

常用的 for 循环:

```bash
# 1到5的循环
for v in {1..5}; do
    echo "$v"
done

# 1到100的奇数循环
for v in {1..100..2}; do
    echo "$v"
done

# 对字符串的的循环操作
for i in $(ls); do
    echo "file: $i"
done

# 对参数的循环操作
for i in $@ ; do
    echo "param: $i"
done
```

- 不带列表的循环

由用户制定参数和参数个数. 与上面的 `对参数的循环操作` 类似.

```bash
for argument; do
    echo "$argument"
done
```

- 类C风格的for循环

```bash
# 计数
for (( i = 0; i < 100; ++i )); do
    echo "$i"
done
```

### while 循环

- 计数控制的 while 循环

```bash
i=1
while (( i <= 100 )); do
    echo "$i"
    let i+=1 # 必须使用 let
done
```

- 结束标记控制的 while 循环

```bash
read num
while [[ "$num" -ne 4 ]]; do
    if [[ "$num" -lt 4 ]]; then
        echo "num to small"
        read num
    else
        echo "num to big"
        read num
    fi
done
```

- 命令行控制的的while循环

```bash
while [[ "$*" != "" ]]; do
    echo "$1"
    shift
done
```

### until 循环

```bash
i=0

until [[ "$i" -gt 5 ]]; do
    echo "$i"
    let ++i # 必须使用 let
done
```

### case 循环

```bash
arg=$0
case "$arg" in 
    "a")
        echo "a" ;;
    "b")
        echo "b" ;;
     *)
        echo "*" ;;
esac
```

在每个 `case` 必须以 ";;" 结尾, 表示当前 case 执行完毕.


### 其他结构

**select**, bash的扩展结构, 用于交互式菜单显示. 注意书写的格式, `do` 最好另起一行.

- select 带参数列表

```bash
select color in "red" "blue" "green"
do
    break
done

echo "color is: $color"
```

- select 不带参数列表

```bash
select color
do
    break
done

echo "color is $color"
```

> 注意: `select 不带参数列表` 需要在命令行执行的时候带上参数列表. 推荐使用第一种方式.