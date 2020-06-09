## if 用法

### if 条件当中的字符串

```bash
A="A"
B="AB"
C=""

## 等于 (=) , 不等于(!=)
if [[ ${A} = ${A} ]]; then
    echo '等于 if [[ ${A} = ${A} ]]'
fi

if [[ ${A} != ${B} ]]; then
    echo '不等于 if [[ ${A} != ${B} ]]'
fi


## 小于(<),  大于(>)
if [[ ${A} < ${B} ]]; then
    echo '小于 if [[ ${A} < ${B} ]]'
fi

if [[ ${B} > ${A} ]]; then
    echo '大于 if [[ ${B} > ${A} ]]'
fi
```

> Bash下的正则匹配: `if [[ ${V} =~ ${regex} ]]` 模式匹配, 其中 ${regex} 要么是引用的变量, 要么是字面量
> 此操作只能在 bash 下执行成功.

```bash
## 正则匹配 (=~)
A="A"
B="AB"
C=""
regex='^A.*'
if [[ ${B} =~ ${regex} ]]; then
    echo '正则 if [[ ${V} =~ ${regex} ]]'
fi

if [[ ${B} =~ A.* ]]; then
    echo '正则 if [[ ${V} =~ ${regex} ]]'
fi
```

### if 条件当中的变量空值, 非空值

```bash
A="A"
B="AB"
C=""

## 空 -z , 非空 -n
if [[ -z ${C} ]]; then
    echo '为空 if [[ -z ${V} ]]'
fi

if [[ -n ${A} ]]; then
    echo '非空 if [[ -n ${V} ]]'
fi
```

### if 条件当中的数字

```bash
## 等于(-eq),  不等于(-ne)
X=1
Y=2

if [[ ${X} -eq ${X} ]];then
    echo '等于 if [[ ${X} -eq ${X} ]]'
fi

if [[ ${X} -ne ${Y} ]]; then
    echo '不等于 if [[ ${X} -ne ${Y} ]]'
fi



## 大于(-gt), 小于(-le)
if [[ ${Y} -gt ${X} ]]; then
    echo '大于 if [[ ${Y} -gt ${X} ]]'
fi

if [[ ${X} -lt ${Y} ]]; then
    echo '小于 if [[ ${X} -lt ${Y} ]]'
fi
```

> 大于等于(-gte), 小于等于(-lte), 类比上面


### if 条件中的文件操作

```bash
## 文件/目录存在 (-e)
if [[ -e '/root' ]]; then
    echo '存在 if [[ -e ${PATH} ]]'
fi


## 文件类型判断: 文件(-f), 目录(-d), 链接(-L)
if [[ -f '/proc/cpuinfo' ]]; then
    echo '文件 if [[ -f ${PATH} ]]'
fi

if [[ -d '/root' ]]; then
    echo '目录 if [[ -d ${PATH} ]]'
fi


# 文件权限: 可读(-r). 可写(-w), 可执行(-x)
if [[ -r '/root' ]]; then
    echo '可读 if [[ -r ${PATH} ]]'
fi
```

### if多个条件

```bash
## 且 (&&, -a),  或 (||, -o)

a=10
b=100

if [[ a > 0 && b > 0 ]];then
    echo '且 [[ ${A} > 0 && ${B} > 0 ]]'
fi

if [[ a > 0 || b > 0 ]];then
    echo '或 [[ ${A} > 0 || ${B} > 0 ]]'
fi
```