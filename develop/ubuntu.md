## ubuntu 

### 从 ubuntu-server 构建 ubuntu-unity

- 替换 apt 源

```
sudo sed -i '/^[^#]/ s|http://us.archive.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|' /etc/apt/sources.list
```

- 安装 `ubuntu-unity-desktop`

```
sudo apt-get install ubuntu-unity-desktop --no-install-recommends --no-upgrade
```

- 卸载系统自带的 `snapd`

- 安装 `中文包` (主要是解决中文乱码问题)

```
sudo apt-get install `check-language-support -l zh-hans` --no-install-recommends

sudo apt-get install fcitx-config-gtk
```

> 这里已经安装了输入法框架 `fcitx`, 与后面 `sogoupinyin` 进行对应. 安装好之后, 在 `语言` 当中配置输入法为 fcitx

- 系统语言配置.

在文件 `/var/lib/locales/supported.d` 目录下的文件增加 `local` 文件:

```
en_US.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8
```

然后使用 `locale-gen` 或 `dpkg-reconfigure locales` 生成系统语言.


- 安装 `unity-tweak-tool` (可以对系统的icon, theme, font配置)

```
sudo apt-get install unity-tweak-tool
sudo apt-get install unity-gtk3-module hud indicator-session unity-lens-files unity-lens-applications
```

上述的 `hud`, `indicator-session`, `unity-lens-files`, `unity-lens-applications` 分别是解决下面的问题:

```
hud (com.canonical.indicator.appmenu.hud)
indicator-session (com.canonical.indicator.session)
unity-lens-files (com.canonical.Unity.FilesLens)
unity-lens-applications (com.canonical.Unity.ApplicationLens)
```

- 安装 `courier 10 patch` 字体.

将下载好的字体放置到 `/usr/local/share/fonts` 目录下, 然后执行命令:

```
sudo fc-cache -fv
```

- 安装开发工具 `git`, `ssh`

```
sudo apt-get install git
sudo apt-get install openssh-server
```

- 安装常用工具 `google-stable`, `sogoupinyin`, `thunderbird`

google-stable, sogoupinyin, thunderbird 需要到各自官方下载最新版本, 然后使用 dpkg 进行安装.


> `sogoupinyin` 安装好之后, 在 `fcitx configuration` 当中配置.

- 安装系统工具 `gedit`(文本编辑), `gnome-system-monitor`(监控), `deepin-screenshot`(截屏), `deepin-image-viewer`(图片查看器)

```
sudo apt-get install gedit
sudo apt-get install gnome-system-monitor
sudo apt-get install deepin-screenshot
sudo apt-get install deepin-image-viewer
```

> 在 `deepin-screenshot` 安装好之后, 最好设置下快捷键.

- 安装可选工具 `wireshark`(抓包工具)

```
sudo apt-get install wireshark
```