# Linux 当中常用的性能分析工具

## lsof

lsof(list open files)是一个列出当前系统打开文件的工具. 通过lsof工具能够查看这个列表对系统检测及排错,

常见的用法:

- 查看文件系统阻塞: lsof /boot
- 查看端口号被进程占用: lsof -i :3306
- 查看用户打开的文件: lsof -u <username>
- 查看进程打开的文件: lsof -p <pid>
- 查看远程已打开的网络链接: lsof -i @192.168.34.128