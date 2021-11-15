## ubuntu 

### 从 ubuntu-server 构建 ubuntu-unity

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

- 安装 `google-stable`, `sogoupinyin`, `git`, `ssh`

google-stable, sogoupinyin 需要到各自官方下载最新版本, 然后使用 dpkg 进行安装.

```
sudo apt-get install git
sudo apt-get install openssh-server
```

> `sogoupinyin` 安装好之后, 在 `fcitx configuration` 当中配置.

- 安装 `gedit`(文本编辑), `gnome-system-monitor`(监控), `deepin-screenshot`(截屏)

```
sudo apt-get install gedit
sudo apt-get install gnome-system-monitor
sudo apt-get install deepin-screenshot
```

> 在 `deepin-screenshot` 安装好之后, 最好设置下快捷键.
