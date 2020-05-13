## Linux 上文件压缩

### tar

tar 命令不是专门的压缩命令. 它通常用于将多个文件拉入一个单个文件中, 以便容易地传输到另一个系统, 或者将文件作为一个相关的组
进行备份. 它也提供了压缩的功能, 附加一个 `z` 压缩选项能够实现压缩文件.

当使用 `z` 选项为 tar 命令附加压缩的过程时, tar 使用 `gzip` 来进行压缩.
 
当使用 `j` 选项为 tar 命令附加压缩的过程时, tar 使用 `bzip2` 来进行压缩.

当使用 `J` 选项为 tar 命令附加压缩的过程时, tar 使用 `xz` 来进行压缩.

```
tar cfz file.tgz file1 file2 ...

tar cfj file.tar.bz2 file1 file2 ...

tar cfJ file.tar.xz file1 file2 ...
```

### zip

zip 命令创建一个压缩文件, 与此同时保留原始文件的完整性. 语法和 `tar` 一样简单, 只是必须记住, 原始文件名称应该是命令行上的最
后一个参数.

```
tar file.zip file1 file2 ...
```

### gzip

gzip 命令非常容易使用, 只需要输入 gzip, 紧跟之后的是要压缩的文件. gzip 将 "就地" 压缩文件. 换句话说, 原始文件将被压缩文件
所替换.

```
gzip file1 file2 ...
```

### bzip2

像使用 gzip 命令一样, bzip2 将选择的文件 "就地" 压缩, 不留下原始文件. 

```
bzip2 file file2 ...
```

## xz

xz 和 `gzip`, `bzip2` 一样, 将选择的文件 "就地" 压缩, 不留下原始文件.

```
xz file file2 ...
```


## 解压缩

- tar 

```
tar xfz file.tar.gz

tar xfj file.tar.bz2

tar xfJ file.tar.xz
```

- zip

```
unzip file.zip
```

- gzip

```
gunzip file.gz
```
- bzip2

```
bunzip2 file.bz2
```

- xz

```
unxz file.xz
```


