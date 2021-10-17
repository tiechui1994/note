## 开发当中常见的问题

### 在 Ubuntu 16.04 版本中, 无法输入中文的问题.

默认情况下, Ubuntu 16.04 使用的键盘输入法是 `IBus`. 可以选择安装键盘输入法是 `fcitx` 的 `sogoupinyin`. 删除掉系
统默认的 `IBus` (可选, 小心操作).

在使用 `fcitx` 键盘输入法的基础上, 可以修改 GoLand 的启动执行脚本, 从而解决上述的问题. 操作步骤如下:

- 安装 `sogoupinyin`

首先从搜狗拼音官网上下载最新版本的 `sogoupinyin`, 官网地址: https://pinyin.sogou.com/linux/?r=pinyin

```bash
sudo dpkg -i sogoupinyin_2.2.0.0108_amd64.deb
```

如果安装出现问题, 一般情况下是 `fcitx` 没有安装出现的问题, 修复操作如下:

```bash
sudo apt-get install -f
```

- 修改 `系统设置` 当中 `语言支持` 的 `键盘输入法` 为 `fcitx`

进入 **System Settings**, 依次选择 **Language Support**, **Keyboard input method system**, 选中 `fcitx`

![image](/images/develop_goland_language.png)


![image](/images/develop_goland_input.png)


- 修改 GoLand 启动执行脚步 `golang.sh`, 增加如下内容( `注意位置` ): 

```
...

# user setting
export GTK_IM_MODULE=fcitx 
export QT_IM_MODULE=fcitx 
export XMODIFIERS=@im=fcitx

# ---------------------------------------------------------------------
# Run the IDE.
# ---------------------------------------------------------------------
IFS="$(printf '\n\t')"
"$JAVA_BIN" \
  ${AGENT} \
  "-Xbootclasspath/a:$IDE_HOME/lib/boot.jar" \
  -classpath "$CLASSPATH" \
  ${VM_OPTIONS} \
  "-XX:ErrorFile=$HOME/java_error_in_GOLAND_%p.log" \
  "-XX:HeapDumpPath=$HOME/java_error_in_GOLAND.hprof" \
  -Didea.paths.selector=GoLand2017.3 \
  "-Djb.vmOptionsFile=$VM_OPTIONS_FILE" \
  ${IDE_PROPERTIES_PROPERTY} \
  -Didea.platform.prefix=GoLand \
  com.intellij.idea.Main \
  "$@"
```

### 在 Ubuntu 16.04 版本中, 经常出现 GoLand (版本 GoLand 2017.3)崩溃的问题. 

在 Ubuntu 16.04 当中, 经常会出现 GoLand 无缘无辜的崩溃. `Keyboard problems meta issue`

解决方法:

修改 GoLand 的 `goland64.vmoptions` jvm 配置选项:

```
-Xms128m
-Xmx750m
-XX:ReservedCodeCacheSize=240m
-XX:+UseConcMarkSweepGC
-XX:SoftRefLRUPolicyMSPerMB=50
-ea
-Dsun.io.useCanonCaches=false
-Djava.net.preferIPv4Stack=true
-XX:+HeapDumpOnOutOfMemoryError
-XX:-OmitStackTraceInFastThrow
-Dawt.useSystemAAFontSettings=lcd
-Dsun.java2d.renderer=sun.java2d.marlin.MarlinRenderingEngine
-Dawt.ime.disabled=true 
```

其中 `-Dawt.ime.disabled=true` 为增加的内容.

### pip 中国源列表

- 清华, 中科大, 阿里云, 豆瓣

```
https://pypi.tuna.tsinghua.edu.cn/simple
https://pypi.mirrors.ustc.edu.cn/simple
http://mirrors.aliyun.com/pypi/simple
http://pypi.douban.com/simple
```

- 设置默认的 pip

```
1. 创建 .pip
mkdir ~/.pip

2. 创建文件 ~/.pip/pip.conf

[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
[install]
trusted-host = pypi.tuna.tsinghua.edu.cn
```


- 使用 pip 安装具体 Python 版本的包

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

### snap 应用安装问题

- 常规安装

```
sudo snap install hello_world 
```

> 存在的问题: 安装的过程是先下载应用, 后安装. 一旦连接断开, 无法自动重连, 对于大安装包, 很难成功


- 非常规安装

1) 查看snap包的信息
```
snap info hello-world
```

里面包含了snap-id和channels(相应的版本号)

2) http下载snap包

```
https://api.snapcraft.io/api/v1/snaps/download/{snap-id}_{channels}.snap
```

3) 安装snap包

```
sudo snap install /path/filename.snap
```

### virtualbox 复制已经安装的文件导致的问题

- 发现问题

操作描述 - 当前已经安装了一个名称为 ubuntu 的 vbox. 操作如下:

1.将 ubuntu 安装文件复制并修改为 arm. 

2.修改了 arm 目录当中的文件名称为 arm.vbox, arm.vbox-prev, arm.vdi. 并且将 arm.vbox-prev 删除掉.

3.修改arm.vbox的内容:

```
<Machine uuid="{92130f55-3a6c-4f16-a43c-6d8eea13d9d2}" name="ubuntu" OSType="Ubuntu_64" snapshotFolder="Snapshots" lastStateChange="2020-02-26T01:55:55Z">
 
<Machine uuid="{92130f55-3a6c-4f16-a43c-6d8eea13d9d2}" name="arm" OSType="Ubuntu_64" snapshotFolder="Snapshots" lastStateChange="2020-02-26T01:55:55Z">
  

<HardDisk uuid="{e490b3a6-0936-4b5b-bf46-67a788f827ac}" location="ubuntu.vdi" format="VDI" type="Normal"/>

<HardDisk uuid="{e490b3a6-0936-4b5b-bf46-67a788f827ac}" location="arm.vdi" format="VDI" type="Normal"/>
```

4.上述修改之后打开arm.vbox, 出现问题:

```
Failed to open virtual machine [...]
Trying to open a VM config [...] which has the same UUID as an existing virtual machine.
```


- 解决问题 

1.调用命令 `run VBoxManage internalcommands sethduuid <VDI/VMDK file>` 两次, 生成两个uuid

2.修改arm.vbox文件

```
① 将带 <Machine uuid="{92130f55-3a6c-4f16-a43c-6d8eea13d9d2}" ...> 当中的uuid修改为第一次生成的uuid的值

② 将带 <HardDisk uuid="{89ee191f-b444-412f-91e8-e5f4f7ec7005}" ...> 和
<Image uuid="{b0e50340-6df2-4b55-8d70-54adca362dbf}" ...> 部分的uuid修改为 第二次生成的uuid的值

③ 删除<HardDisks>标签内的内容, 使其变成为 <HardDisks></HardDisks>
```

3.在上述修改之后重新打开arm.vbox即可.

### virtualbox 当中使用U盘(Linux)

1. 下载 virtualbox 扩展. https://www.virtualbox.org/wiki/Downloads 地址处寻找.

一般情况下载地址是: `https://download.virtualbox.org/virtualbox/${VER}/Oracle_VM_VirtualBox_Extension_Pack-${VER}.vbox-extpack`

其中, `${VER}` 是 virtualbox 的版本.

2. 双击下载的扩展包, 进行安装.

3. 添加当前的用户到 `vboxusers`, `usbfs` 当中.

```
sudo adduser USER vboxusers
sudo groupadd usbfs
sudo adduser USER usbfs
```

4. 重启宿主机.

5. 重启之后, 先插入U盘, 在虚拟机的的 `设置 > USB设备 > USB设备筛选器` 当中添加相应的U盘.

### virtualbox 从U盘当中安装系统

1. 将当前的用户添加 `vboxusers` 当中.

```
sudo usermod -G vboxusers -a `whoami`
```

2. 创建 U 盘的虚拟磁盘

```
VBoxManage internalcommands createrawvmdk -filename /virtualbox/UsbDisk.vmdk -rawdisk /dev/sdc
```

> `/dev/sdc` 是磁盘符. 可通过 `df` 查看挂在的 U 盘的磁盘符.
> `/virtualbox/UsbDisk.vmdk` 是生成的虚拟磁盘文件.

这一步如果出现 `successfully` 字样则证明成功了.

3. 增加 U 盘的读写权限

```
sudo chmod o+rw /dev/sdc
```

4. 注册虚拟磁盘

`控制 > 注册`, 选择上面生成的 `/virtualbox/UsbDisk.vmdk` 文件.

5. 创建虚拟机时, 对于 `虚拟硬盘` 选项, 选择 `使用已有的虚拟硬盘文件(U)` 即可.

### 本地 github 加速

```
Host github.com
     User git
     HostName git.zhlh6.cn
     Port 22
     IdentityFile ~/.ssh/id_rsa
     LogLevel ERROR
```

> IdentityFile 是 github 的秘钥文件位置. HostName 配置的是远程 ssh 加速访问的代理服务器.

### ubuntu18.04 卸载 snap

1) 删除 snap 和 snap gui tool

```
sudo apt autoremove --purge snapd gnome-software-plugin-snap
```

2) 清除 snap 垃圾

```
rm -rf ~/snap
```

3) put snap on hold

```
sudo apt-mark hold snapd
```