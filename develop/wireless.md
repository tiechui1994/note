# 无线网络

## Linux 下安装 "水星UD198H" 无线网卡驱动

### 编译安装

首先, UD198H 使用的网卡驱动是 rtl8814au, 这个可以从开源的 github 获取到源码, 然后进行编译到 linux 当中去就好了.

1. 下载 rtl8814au 驱动源码

```
git clone https://github.com/aircrack-ng/rtl8814au.git
```

2. 编译

```
sudo apt-get update
sudo apt-get install make 

cd rtl8814au
make
sudo make install
```

> 如果编译失败, 自行 Google 解决问题

3. 加载 kernel 模块

```
sudo insmod /lib/modules/`uname -r`/kernel/drivers/net/wireless/8814au.ko
```

> 到此, 电脑连上无线网卡, 就会出现一个网卡名称, 然后使用图形界面去连接无线网络就好了.


### 模式切换

关于无线网卡的模式, 最初它将使用 USB2.0 模式, 这将限制 5G 11ac 吞吐量(USB2.0 带宽仅 480Mbps => 吞吐量约为 240Mbps),
当 modprobe 添加以下选项将使其在初始驱动程序选项 `8814au rtw_switch_usb_mode=1` 时切换到 USB3.0 模式.

```
# usb2.0 => usb3.0
sudo sh -c "echo '1' > /sys/module/8814au/parameters/rtw_switch_usb_mode"


# usb3.0 => usb2.0
sudo sh -c "echo '2' > /sys/module/8814au/parameters/rtw_switch_usb_mode"
```
