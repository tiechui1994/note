# Python3 

## pip 中国源列表

- 清华

```
pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple 
```
- 中科大

```
pip3 install -i https://pypi.mirrors.ustc.edu.cn/simple
```

- 阿里云

```
pip3 install -i http://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com
```

- 豆瓣

```
pip3 install -i http://pypi.douban.com/simple --trusted-host pypi.douban.com
```

## 设置默认的 pip

```
1. 创建 .pip
mkdir ~/.pip

2. 创建文件 ~/.pip/pip.conf

[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
[install]
trusted-host = pypi.tuna.tsinghua.edu.cn
```


## 使用 pip 安装具体 Python 版本的包

```
pip3 install --only-binary=:all: --python-version=36 --abi=cp36m \
--platform=manylinux1_x86_64 -t . -i https://pypi.tuna.tsinghua.edu.cn/simple \
numpy==1.18.5
```

> 参数说明:
> --only-binary=:all: 不要使用源程序包. 可以多次提供, 每次都增加到现有值.
> `:all:`, 禁用所有源软件包, `:none:`, 清空集合, 或者 `一个或多个软件包名称,并且它们之间用逗号分隔`.
> 如果没有二进制分发包, 则在使用此选项时将无法安装.
>
> --python-version=36, 指定python版本, 例如 34, 35, 36 等
>
> --abi=cp36m, 与指定的python版本对应的api
>
> --platform, 指定平台, linux一般都是 manylinux1_x86_64
>
> -t . 安装到当前目录
>
> numpy==1.18.5, 指定安装的包 numpy 的版本是 1.18.5
