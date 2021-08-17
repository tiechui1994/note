## read

read 从键盘读取变量的值, 通常在 shell 脚本中与用户进行交互的场景. 该命令可以一次读取多个变量的值, 变量和输入的值需要使
用空格隔开. 在 read 命令后面, 如果没有指定变量名, 读取的数据将自动赋值给特定的变量 REPLY.

使用:

```
read [选项] (参数) 
```

### 选项

- `-p prompt` 指定读取值的提示符

- `-t timeout` 指定读取值等待的超时时间

- `-d delim` 指定结束符(默认是换行符号)

- `-a array` 读取的内容按照空格分割形成数组 array 

- `-n N` 读取 N 个字符

- `-s` 密码内容

- `-r` 只读内容


### 案例

- 带有提示符

```bash
read -p "Enter your name: " name

echo "name: $name"
```

- 密码输入

```bash
read -p "Enter password: " -s pwd

echo "pwd: $pwd"
```

- 多个变量(使用空格分割)

```bash
read one two three

echo "one=$one, two=$two, three=$three"
```

- 多个变量(使用空格分割, 使用":"结束输入)

```bash
read -d ":" one two three 

echo "one=$one, two=$two, three=$three"
```

- 数组(使用空格分割)

```bash
read -a arr 

echo "one=${arr[*]}"
```

- 设置读取的超时时间

```bash
read -p "Enter password: " -t 30 -s pwd

echo "pwd: $pwd"
```
