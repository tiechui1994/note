# cmd

Windows 下 CMD 常用的命令

### IF 条件判断

格式:

```
IF .... ( command ) ELSE  ( command )

# 文件
IF [NOT] EXIST <filename> ( command )


# 字符串, 数字
IF [/I] [NOT] item1==item2 ( command )
IF [/I] [NOT] "item1" == "item2" ( command )

IF [/I] item1 <compare-op> item2 ( command )

# 错误
IF [NOT] DEFINED <var> ( command )
IF [NOT] ERRORLEVEL <number> ( command )
IF CMDEXTVERSION  <number> ( command )
```

`item`, 文本字符串或环境变量.

`/I`, 关注字符串的大小写

`<compare-op>` 主要有:
1) EQU, 相等

2) NEQ, 不相等

3) LESS, 小于

4) LEQ, 小于等于  

5) GTR, 大于

6) GEQ, 大于等于

### 字符串操作

**字符串**:

```
%var:~<start_idx>%

%var:~<start_idx>,<end_idx>%
```

start_idx, 表示字符串的开始索引下标.
end_idx, 截取的字符串长度.

例子:
```
SET _test=123456789abcdef0

:: idx=0 之后的 5 个字符
   SET _result=%_test:~0,5%
   ECHO %_result%          =12345

:: idx=7 之后的 5 个字符
   SET _result=%_test:~7,5%
   ECHO %_result%          =89abc

:: idx=7 之后的字符
   SET _result=%_test:~7%
   ECHO %_result%          =89abcdef0

:: idx=-7 之后的字符
   SET _result=%_test:~-7%
   ECHO %_result%          =abcdef0
```

**字符串编辑**:

```
%var:<search>=<replace>%
```

`search` 是要搜索的字符串, 支持前缀匹配(即 `*xxx`). 不区分大小写

`replace` 是替换字符串

例子:
```
::Replace '12345' with 'Hello '
   SET _test=12345abcABC
   SET _result=%_test:12345=Hello %
   ECHO %_result%          =Hello abcABC

::Replace 'ab' with 'xy'
   SET _test=12345abcABC
   SET _result=%_test:ab=xy%
   ECHO %_result%          =12345xycxyC

::Delete 'ab'
   SET _test=12345abcABC
   SET _result=%_test:ab=%
   ECHO %_result%          =12345cC

::Delete '*ab'
   SET _test=12345abcabc
   SET _result=%_test:*ab=% 
   ECHO %_result%          =cabc

::Replace '*ab' and with 'XY'
   SET _test=12345abcabc
   SET _result=%_test:*ab=XY% 
   ECHO %_result%          =XYcabc
```

### FOR 循环

使用格式:

```
# 文件
FOR %%param IN (set) DO ( command )

# 根节点遍历文件
FOR /R [[drive]:path] %%param IN (set) DO ( command )

# 遍历目录
FOR /D %%param IN (folder_set) DO ( command ) 

# 
FOR /F ["options"] %%param IN (filename_set) DO ( command )
FOR /F ["options"] %%param IN ("text string to process") DO ( command )
FOR /F ["options"] %%param IN ('command to process') DO ( command )

# 数字遍历
FOR /L %%param IN (start,step,stop) DO ( command )
```



