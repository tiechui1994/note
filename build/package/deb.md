## deb 包构建

deb包的文件结构:

- DEBIAN目录
- 具体安装目录(模拟安装目录, 如etc, usr, opt, tmp等).

在DEBIAN目录至少有control文件, 还可能有 preinst(preinstallation), postinst(postinstallation), prerm
(preremove), postrm(postremove) copyright(版权), changelog(修订目录) 和 conffiles等.

### DEBIAN目录下的文件说明

- `control文件`: 描述软件包的名称(Package), 版本(Version), 描述(Description)等. 是deb包必须具备的描述性文件, 
以便于软件的安装和索引.

control 文件当中所需要的条目.

```
Package: 软件名称(中间不能有空格)
Version: 软件版本(必要参数)
Description: 软件描述
Section: 申明软件的类别, 常见的有 'utils', 'net', 'mail', 'text', 'x11'等
Priority: 申明软件对于系统的重要程度, 'required', 'standard', 'optional', 'extra'等.
Essential: 申明是否是系统最基本的软件包(选项为yes/no).
Architecture: 软件支持的平台架构. 'i586', 'amd64', 'powerpc'等.
Source: 软件包的源代码名称.
Depends: 软件所依赖的其他软件包和库文件. 如果是依赖多个软件包和库文件, 彼此之间采用逗号隔开.
Pre-Depends: 软件安装前必须安装,配置依赖性的软件饱和库文件, 它常常用于必须的预运行脚本需求.
Recommends: 推荐安装的其他软件包和库文件.
Suggests: 建议安装的其他软件和库文件.
Install-Size: 安装大小
Maintainer: 打包人和联系方式(必要参数)
Provides: 提供商
```

案例(mongobooster):

```
Package: mongobooster
Version: 3.2.1
License: commercial
Vendor: qinghai <qinghai@mongobooster.com>
Architecture: amd64
Maintainer: qinghai <qinghai@mongobooster.com>
Installed-Size: 141509
Depends: libappindicator1, libnotify-bin
Section: default
Priority: extra
Homepage: http://www.mongobosoter.com
Description: Essential admin GUI for mongodb
        (此处必须空一行再结束)
```

- `preinst`: 文件安装前的需要执行的脚本

- `postinst`: 包含了软件在正常目录拷贝到系统后,所需要执行的配置工作的脚本

- `prerm`: 软件卸载前需要执行的脚本.

- `postrm`: 软件卸载后需要执行的脚本.


### 打包的目录结构(执行 dpkg-deb 前的目录结构)

文件目录:

```
software
    |----DEBIAN
        |----control
        |----postinst
        |----postrm
    |----xxx
        |----binary-sofware
```

xxx 表示安装后的文件的目录, software目录对应文件的根目录.

打包操作: dpkg-deb.

### dpkg-deb 命令介绍

dpkg-deb: 打包成deb

命令使用:

```
dpkg-deb [OPTION...] COMMAND
```


COMMAND:

- `-b, --build directory [archive|directory]`

从存储在目录中的文件系统树创建debian存档. directory必须有一个DEBIAN子目录, 其中包含control(软件信息)文件. 该目录不
会出现在二进制包的文件系统存档中, 而是将其中的文件放在二进制包的控制信息区域中.

除非指定--nocheck, 否则dpkg-deb将读取DEBIAN/control并解析它.它将检查control文件是否存在语法错误和其他问题, 并显
示正在构建的二进制包的名称. dpkg-deb还将检查维护者的脚本权限和DEBIAN/control当中出现的其他文件的权限.

如果没有指定archive, dpkg-deb会将包写入 `{directory}.deb`

如果要创建的deb存档已存在, 则将覆盖该存档.

如果第二个参数是directory, 当control文件中没有Architecture字段时, 则dpkg-deb将写入文件 `{package}_{version}.deb`,
否则dpkg-deb将写入文件{package}_{version}_{arch}.deb, 写入的文件的目录是directory.

如果第二参数是archive(归档文件), 则dpkag-deb将文件写入archive.


- `-W, --show archive`

提供有关二进制包版本信息.

- `-I, --info archive [control-file-name...]`

提供有关二进制包文件内容的信息.

如果未指定 control-file-name, 则它将打印包的内容及其control文件的摘要.

如果指定了 control-file-name, 则dpkg-deb将按照指定的顺序打印它们. (preinst,postinst,prerm,postrm)

- `-f, --field archive [control-field-name...]`

从二进制包归档中提取control文件信息.

如果未指定control-field-name, 则它将打印整个control文件.

如果指定了control-field-name, 则dpkg-deb将按照它们的顺序打印起其内容.(version,depends,package,...)


- `-c, --comments archive`

列出程序包归档文件系统树的内容. 它目前以tar的详细列表生成的格式生成.


- `-e, --control archive [directory]`

将control文件从包存档中提取到指定目录中.

如果未指定directory, 则使用当前目录中的子目录DEBIAN

- `-x, --extract archive directory`

将文件系统树从包存档中提取到 '指定目录' 中.

> 注意: 将包解压缩到根目录不会导致正确的安装! 请使用dpkg去安装包

在解压的时候会创建directory, 并修改其权限以匹配包的内容.

- `-X, --vextract archive directory`

等价于 --extract -v, 展示详情

- `-R, --raw-extract archive directory`

将文件系统树从包存档中提取到 '指定目录' 中. 并且 control 解压到指定目录的 DEBIAN 子目录中


OPTION:

- `-z compress-level`

在构建程序包时指定压缩级别(对于gzip和bzip2, 默认值为9, 对于xz和lzma,默认值为6). 接受的值为0-9,其中: 0映射到压缩器
none用于gzip, 0映射到1用于bzip2.

- `-S compress-strategy`
在构建程序包时指定压缩策略(自dpkg-1.16.2起). 针对gzip类型,允许值有none(自dpkg-1.16.4), filtered,huffman, rle
和fixed. 针对xz类型, 允许的值有extrme,

- `-Z compress-type`
指定构建包时要使用的压缩类型. 允许的值为gzip,xz(自dpkg-1.15.6起), bzip2(不建议使用), lzma(自dpkg-1.14.0起; 不建
议使用)和none. 默认为xz.
