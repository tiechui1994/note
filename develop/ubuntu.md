## 最小化安装 ubuntu  

### 从 ubuntu-server 构建 ubuntu-unity

下面是 20.04 为例

- 替换 apt 源

```
sudo sed -i '/^[^#]/ s|http://us.archive.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|' /etc/apt/sources.list
```

- 卸载系统自带的 `snapd`

```
# 列出所有已安装的 snap
snap list

# 按照列表逐一卸载（必须先卸载应用，最后卸载 core）
# 常见的包卸载顺序参考：
sudo snap remove --purge lxd
sudo snap remove --purge core20
sudo snap remove --purge snapd

# 卸载服务
sudo systemctl stop snapd
sudo apt purge snapd -y

# 文件夹
rm -rf ~/snap
sudo rm -rf /snap
sudo rm -rf /var/snap
sudo rm -rf /var/lib/snapd
```

- 安装 `ubuntu-unity-desktop`

```
sudo apt-get install ubuntu-unity-desktop --no-install-recommends --no-upgrade
```

- 安装 `unity-tweak-tool` (可以对系统的icon, theme, font配置)

```
sudo apt-get install unity-tweak-tool --no-install-recommends --no-upgrade
sudo apt-get install unity-gtk3-module hud \
    unity-lens-files unity-lens-applications \
    unity-schemas indicator-appmenu indicator-session --no-install-recommends --no-upgrade
```

上述的 `hud`, `indicator-session`, `unity-lens-files`, `unity-lens-applications` 分别是解决下面的问题:

```
hud (com.canonical.indicator.appmenu.hud)
indicator-session (com.canonical.indicator.session)
unity-lens-files (com.canonical.Unity.FilesLens)
unity-lens-applications (com.canonical.Unity.ApplicationLens)
```

- 安装 `中文包` (解决中文乱码问题)

```
# 安装依赖
sudo apt-get install `check-language-support -l zh-hans` fcitx-config-gtk --no-install-recommends --no-upgrade

# Language Support 当中修改输入法 `fcitx`, 应用中文, 地区选择中文.
```

> 这里已经安装了输入法框架 `fcitx`, 与后面 `sogoupinyin` 进行对应.

- 系统语言配置(可选).

在文件 `/var/lib/locales/supported.d` 目录下的文件增加 `local` 文件:

```
en_US.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8
```

然后使用 `locale-gen` 或 `dpkg-reconfigure locales` 生成系统语言.


- 增加安装 `courier 10 patch` 字体.

将下载好的字体放置到 `/usr/local/share/fonts` 目录新建文件夹下, 然后执行命令:

```
# 字体安装
sudo fc-cache -fv

# tweak 当中进行字体设置
```

- 安装 sougoupinyin

```
# 卸载 fcitx-ui-qimpanel
sudo apt purge fcitx-ui-qimpanel

# 安装 sogoupinyin
sudo dpkg -i sogoupinyin.deb

# 依赖解决
sudo apt-get install -f
```

> `sogoupinyin` 安装好之后, 在 `fcitx configuration` 当中配置.


### 启动优化配置

- tweak 优化配置项
```
1. General 当中硬件加速改为 'fast'

2. General 当中 Window 动画 '关闭'
```


- 启动项配置优化
```
# 在 /etc/xdg/autostar 目录下列出对文件移动到 /etc/xdg/autostart_backup
tracker-extract.desktop         # 持续扫描文件并建立索引
tracker-miner-fs.desktop        # Tracker 索引服务
update-notifier.desktop         # 软件包更新通知

# 禁用 GNOME Online Accounts
sudo chmod -x /usr/libexec/goa-daemon

# 禁用 Evolution 相关服务
# 停止并禁用 Evolution 相关后台服务
systemctl --user mask evolution-addressbook-factory.service \
               evolution-calendar-factory.service \
               evolution-source-registry.service \
               evolution-user-prompter.service \
               evolution-alarm-notify.service

# 禁用自动更新检查, 编辑文件
sudo vim /etc/apt/apt.conf.d/20auto-upgrades

# 将所有值改为 "0":
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Unattended-Upgrade "0";

# 禁用通知
sudo systemctl disable unattended-upgrades
sudo chmod -x /usr/lib/update-notifier/update-notifier
```

- grub 优化
```
# 编辑 Grub 配置文件:
sudo vim /etc/default/grub

# 找到 GRUB_CMDLINE_LINUX_DEFAULT 这一行, 在引号内添加 mitigations=off
# eg GRUB_CMDLINE_LINUX_DEFAULT="quiet splash mitigations=off"

# 更新配置
sudo update-grub
```


- swap 优化
```
# 调低 Swappiness:  默认值为 60, 意味着系统会较早地把内存数据置换到磁盘
sudo sysctl -w vm.swappiness=10
```

- 删除不必要对内核
```
# 列出不使用对内核
dpkg --list | grep linux-image

# 删除内核
sudo apt-get purge linux-image-X.X.X-X-generic

sudo apt-get purge linux-headers-X.X.X-X
sudo apt-get purge linux-headers-X.X.X-X-generic

sudo apt-get purge linux-modules-X.X.X-X-generic
sudo apt-get purge linux-modules-extra-X.X.X-X-generic

# 更新内核
sudo update-grub
```

- 进一步优化内存
```
# 查看内存占用前 10 的服务
ps -e -o pid,ppid,cmd,%mem --sort=-%mem | head -n 11

# 进行对相关不使用对内存优化
```

### 可选工具安装

- 安装开发工具 `git`, `ssh`

```
sudo apt-get install git
sudo apt-get install openssh-server
```

- 安装常用工具 `google-stable`, `thunderbird`

google-stable, thunderbird 需要到各自官方下载最新版本, 然后使用 dpkg 进行安装.


- 安装系统工具 `gedit`(文本编辑), `gnome-system-monitor`(监控), `deepin-screenshot`(截屏), `deepin-image-viewer`(图片查看器),
`mpv 或 smplayer`(视频播放器)

```
sudo apt-get install gedit
sudo apt-get install gnome-system-monitor
sudo apt-get install deepin-screenshot
sudo apt-get install deepin-image-viewer

audo apt-get install mpv --no-install-recommends --no-upgrade
audo apt-get install smplayer --no-install-recommends --no-upgrade
```

> 在 `deepin-screenshot` 安装好之后, 最好设置下快捷键.

- 安装可选工具 `wireshark`(抓包工具), `ffmpeg`(视频处理工具)

```
sudo apt-get install wireshark
sudo apt-get install ffmpeg
```

- 安装可选工具 `SingleNote`(桌面笔记, 随时备份工具)

deb 下载地址: `https://github.com/Automattic/simplenote-electron/releases`

桌面图标: `https://github.com/Automattic/simplenote-electron/blob/develop/resources/images/icon_128x128.png`

simplenote.desktop 文件:

```
[Desktop Entry]
Comment=simplenote
Exec=/opt/local/simplenote/simplenote
Icon=/opt/local/simplenote/simplenote.png
Name=SimpleNote
StartupNotify=false
Terminal=false
Type=Application
Categories=Office;WordProcessor;Qt;
X-DBUS-ServiceName=
X-DBUS-StartupType=
X-KDE-SubstituteUID=false
X-KDE-Username=
InitialPreference=3
```

- 安装 `wps-office` (Office套件)

deb 下载地址: `https://github.com/tiechui1994/jobs/releases/download/wps-office-2019-zh-CN/wps-office_11.1.0.8392_amd64.deb`

中文语言安装: `https://gist.github.com/tiechui1994/2912e4d5990a0ab26ddd8db75c42ae57`


### 问题

1. `dbus-daemon[987]: [system] Failed to activate service 'org.bluez': timed out (service_start_timeout=25000ms)`

这个是 bluetooth(蓝牙) 服务无法启动, 可以禁用该服务.

```
systemctl stop bluetooth.service
systemctl disable bluetooth.service
```

2. `Exiting GPU process due to errors during initialization` 

这个是在 virtualbox 虚拟机当中使用 google-chrome 浏览器, Google 浏览器默认是启用 GPU 的, 但是 virtualbox 某些版本是无法使用到宿主机的
GPU, 因此需要在禁用掉 GPU, 使用参数 --disable-gpu

