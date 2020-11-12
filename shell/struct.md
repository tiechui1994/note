# Shell 编程常用的数据结构

> 简介: shell 编程经常会用到 map, array 等数据结构来存储一些中间的内容. 本文就简单的介绍下 shell 当中 map, array
的常用的操作. 有了这些数据结构的辅助, 能够编写功能更加强大的脚本.

## map

使用 map 的时候, 需要先声明, 否则结果可能与预期不同. array可以不声明. 

map 的遍历是无序的. 

- map 的定义

> 方式一: 声明后再赋值

```bash
declare -A m
m["zh"]="中国"
```

> 方式二: 声明与赋值同时进行

```bash
declare -A m=(["zh"]="中国" ["cn"]="美国")
```

需要注意: `=` 的前后没有任何空格, 赋值语句也是一样的. 初始化的时候是 `小括号` + `空格` 的方式进行初始化的. 

- map 赋值与获取

```bash
# 赋值
m[key]=val

# 获取, 获取的方式很固定.  "$m[key]" 这种方式是错误的.
_=${m[key]}  
```

- map的长度, 所有key, 所有value

**所有的key**: `${!m[@]}`, 带有 `!`. 注意这里的结果是一个列表

**所有的value**: `${m[@]}`, 不带 `!`. 注意这里的结果是一个列表

**长度**: `${#m[@]}`, 使用 `#`

- map 遍历

> 根据 key 找到 value:

```bash
for key in ${!m[@]}; do
    echo "key:$key, val:${m[$key]}"
done
```

> 遍历所有的 key:

```bash
for key in ${!m[@]}; do
    echo "key:$key"
done
```

> 遍历所有的 value:

```bash
for val in ${m[@]}; do
    echo "val:$val"
done
```

## array

- array 定义

> 数组的定义初始化.

```bash
# 空数组
arr=()

# 递增方式初始化
arr=("en" "us")

# 自定义方式初始化
arr=([1]="en" [3]="zh" [0]="cn")
```

- array 赋值与获取

与 map 的方式很类似.

```bash
# 赋值
arr[index]=val

# 获取, 获取的方式很固定. ${arr} 代表的是数组的第一个元素.  "$arr[key]" 这种方式是错误的.  
_=${arr[index]}  
```

- array 的长度, 所有value

**长度**: `${#arr[@]}`, 使用 `#`. 与 map 的方式是一致的

**所有的value**: `${arr[@]}` 或者 `${arr[*]}`. 推荐使用前一种方式. 注意这里的结果是一个列表


- array 遍历

> 列表遍历的方式

```bash
for i in ${arr[@]} ; do
    echo "$i"
done
```

> 根据长度遍历 

```bash
for (( i = 0; i < ${#arr[@]}; ++i )); do
    echo "${arr[$i]}"
done
```


## 数字运算

- 整数运算, 即计算结果都是整数

```bash
m=10
n=5
echo $(echo "$n/$m" | bc)

echo $(expr "$n/$m")
```

- 浮点数运算, 即计算结果带小数

> 使用 `bc`

```bash
function div() {
    n=$1, m=$2
    echo $(echo "scale=2;$n/$m" | bc)
}
```

> 使用 awk

```bash
function div() {
    n=$1, m=$2
    echo $(awk 'BEGIN{printf "%.2f\n", '${n}'/'${m}'}')
}
```

