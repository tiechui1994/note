## shell 多行字符串

### 直接输出到文件

> 纯文本, 文本当中没有任何变量

```bash
# use '>' 表示清除原文件, 并进行追加操作, use '>>' 表示追加操作

FILE="~/www.txt"
cat > ${FILE} <<- EOF
www.qq.com
www.google.com
EOF

# or

cat >  ${FILE} <<- 'EOF'
www.qq.com
www.google.com
EOF
```

> 文本当中带有变量

```bash
qq="www.qq.com"
google="www.google.com"

VAR='~/var.txt'
cat > ${VAR} <<- EOF
${qq}
${google}
EOF


cat > ${VAR} <<- 'EOF'
${qq}
${google}
EOF
```

>> 注意: 上面两个文件的内容是不一样的, 对于第一种方式, 会将变量全部解析, 如果变量未定义, 则使用 "" 替换变量, 对于方
>> 式二, 不会解析变量, 直接是纯文本的方式写入.

### 输出到变量中, 即为变量赋值

> read 的方式

> 注: read 的 `-r` 选项表示变量是只读的. `-d ''` 选项表示直到读到第一个字符.(默认是 '\n'), 这个参数很关键. 如果不
设置, 则 read 变量值只有第一行.

```bash
read -r -d '' var <<- EOF
this is line 1
this is line 2
EOF

read -r -d '' var <<- 'EOF'
this is line 1
this is line 2
EOF
```

>> 使用 **EOF** 和 **'EOF'** 的区别和上面的区别是一样的.

> cat 的方式

```bash
var=$(cat <<- EOF
this is line 1
this is line 2
EOF
)

var=$(cat <<- 'EOF'
this is line 1
this is line 2
EOF
)
```

>> 使用 **EOF** 和 **'EOF'** 的区别和上面的区别是一样的.
