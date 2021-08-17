# Shell 数据结构(map,array)

> 简介: shell 编程当中, 除了对常用的命令 `awk`, `sed`, `grep`, `find` 等命令要非常熟悉之外, 对于 map, array 
等常用数据结构的操作也需要熟练掌握, 这样你的编程能力才有一个飞跃. 本文就简单的介绍下 shell 当中 map, array 这两种数
据结构的操作, 以及如何解决 shell 编程数学计算的小数点问题.

## map

**使用 map 的时候, 需要先声明**, 否则结果可能与预期不同. array可以不声明. 

**map 的遍历的结果是无序的, 但是对于同一个 map 多次遍历的结果的顺序是一致的**

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

**所有的key**: `${!m[@]}`, 带有 `!`. 注意这里的结果是一个元组

**所有的value**: `${m[@]}`, 不带 `!`. 注意这里的结果是一个元组

**长度**: `${#m[@]}`, 带有的是 `#`

> 顺便说一下, 元组是可以直接使用 `for...in` 的方式进行遍历的

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

# 递增索引初始化
arr=("en" "us")

# 自定义索引初始化. 这里的初始化方式和map很类似
arr=([1]="en" [3]="zh" [0]="cn")
```

案例: 通过正则匹配结果创建数组

```bash
arr=($(grep -n -o -E '^session' sshd))
echo "len: ${#arr}"
```

注: `$(grep -n -o -E '^session' sshd)` 的内容是换行输出.

- array 赋值与获取

与 map 的方式很类似.

```bash
# 赋值
arr[index]=val

# 获取, 获取的方式很固定. 
# ${arr} 代表的是数组的第一个元素.  
# "$arr[key]" 这种方式是错误的.  
_=${arr[index]}  
```

> 注意: ${arr} 获取的是数组的第一个元素, 不是所有的元素. 数组元素获取的方式只能是 ${arr[index]}. `$arr[index]` 
这种方式看似正确, 其实是错误的. (map也遵循相同的规则)


- array 的长度, 所有value

**长度**: `${#arr[@]}`, 使用 `#`. 与 map 的方式是一致的

**所有的value**: `${arr[@]}` 或者 `${arr[*]}`. 推荐使用前一种方式. 注意这里的结果是一个元组

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
