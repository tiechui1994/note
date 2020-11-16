# Charles 抓包

> 简介: Charles 抓包是日常开发当中经常会用到的技术, 在 Android 6 之前, 手机系统既信任系统内置的证书, 也信任用户自己
安装的证书, 但是在 Android 7 之后, 却发生了变化, 手机系统只信任系统内置的根证书. 当然了, 这是为了手机系统更安全. 但是
这样以来, 原来抓包的方法就失效了. 本文主要全面讲解 IOS 和 Android 系统如何去配置根证书. 彻底解决抓包所遇到的最头疼的问
题.

## Charles 抓包前的准备工作

1. 下载 `Charles`, 官网的地址: https://www.charlesproxy.com

2. 配置要抓包的站点, 进入 `Proxy > SSL Proxying Settings > SSL Proxying`, 启用 `Enable SSL Proxying`, 同
时在 `Include` 当中添加 `Location` (站点配置), 如下图所示(这是个通配符配置, 一般状况下, 这个这个已经能够满足绝大数
抓包的需求了)

![image](/images/develop_charles_sslproxy.png)

3. 配置代理服务器的端口, `Proxy > Proxying Settings`, 设置端口(这个端口会在后面使用到的哦).

![image](/images/develop_charles_setport.png)

> 一般情况下, 上述配置已经满足了大部分抓包的需求, 当然还需要更详细的内容, 请参考其他教程内容

---

## Charles 在 Android 7.0(及其以上的版本) 上安装证书方法

1. 下载应用 `VMOS`, 官网地址是: http://www.vmos.cn. 

> 注: `VMOS` 应用就是一台 Android 虚拟机, 目前好像只支持 32 位系统, 大部分应用都可以使用, 如果有的应用明确需要 64位
系统, 可以使用 `VMOS Pro`, 当然了这个 root 功能是收费的了.

2. 导出 Charles 的证书, 这个证书是抓包的时候安装在手机上的证书. 方法有两种:

**方法一:**

- 在 Android 手机上配置代理, 主机是你安装 Charles 的主机的 IP (注意: Android 手机需要和安装的Charles的电脑在同一
网段下), 端口号 `8888`. (这个可以自行百度各种手机的配置方法.)

- 在 Android 手机的浏览器上输入网址 `chls.pro/ssl`, 然后下载并保存证书文件.

- 将下载好的证书文件拷贝到电脑上, 进行如下的操作:

```
openssl x509 -subject_hash_old -in Charles-proxy-ssl-proxying-certificate.crt
```

> `charles-proxy-ssl-proxying-certificate.crt` 是拷贝的证书文件的名称.

上面输出的结果类似于:

```
faf57fe3
-----BEGIN CERTIFICATE-----
MIIFMDCCBBigAwIBAgIGAXWqowQPMA0GCSqGSIb3DQEBCwUAMIGbMSwwKgYDVQQD
....
aXDrm30UE6+dWdQ3n0ePVLNcHV+ZrIqwka94M/t8HavZpm4y
-----END CERTIFICATE-----
```

然后将 `charles-proxy-ssl-proxying-certificate.crt` 重命名为 `faf57fe3.0`(`faf57fe3` 需要根据你自己生成的
结果进行调整)

**方法二:**

- Charles 当中进入 `Help > SSL Proxying > Save Charles Root Certificate`, 导出 PEM 格式证书文件.

- 然后进行如下的操作:

```
openssl x509 -subject_hash_old -in Charles-proxy-ssl-proxying-certificate.pem
```

> Charles-proxy-ssl-proxying-certificate.pem 是导出的证书文件

上面输出的结果类似于:

```
faf57fe3
-----BEGIN CERTIFICATE-----
MIIFMDCCBBigAwIBAgIGAXWqowQPMA0GCSqGSIb3DQEBCwUAMIGbMSwwKgYDVQQD
....
aXDrm30UE6+dWdQ3n0ePVLNcHV+ZrIqwka94M/t8HavZpm4y
-----END CERTIFICATE-----
```

然后将 `Charles-proxy-ssl-proxying-certificate.pem` 文件重命名为 `faf57fe3.0`( `faf57fe3`需要根据你自己生成
的结果进行调整)


3. 将生成好的证书文件拷贝到 `/system/etc/security/cacerts/` 目录下, 并且修改文件权限(默认状况下权限是644):

```
# adb 连接到 vmos 虚拟机
adb connect 192.168.50.100:5666
 
# 拷贝文件
adb push faf57fe3.0 /system/etc/security/cacerts/
```

> `192.168.50.100:5666` 是 `VMOS` 虚拟机的ADB地址. 在进入 `VMOS` APP后, 进入 `设置 > 其他设置` 当中, 按照下
图所示进行设置, 然后重启 `VMOS` APP 即可生效: 

![image](/images/develop_charles_root.jpg)

4. 设置全局代理. 到此为止, 证书已经安装好了. 接下来需要设置 `VMOS` 的全局代理地址为当前的 Charles 的代理服务器的地址. 
设置操作如下:

```
# adb 连接到 vmos 虚拟机(如果之前已经连接过可以省略)
adb connect 192.168.50.182:5666 

# 设置 vmos 的全局代理
adb shell settings put global http_proxy 192.168.50.14:8888 
```

> `192.168.50.14:8888` 是我的 Charles 的主机IP地址+端口号, 这个需要根据自己设置的情况修改.
> 这一步很重要的, 如果没有这一步操作, 前面的准备工作都白搭了.
>
> 题外话, 当要修改 `全局代理` 的时候, 依然可以使用 `adb shell settings put global http_proxy ip:port` 的形式.
> 但是, 如果要移除 `全局代理`, 注意了, 这里是移除全局代理, 则使用的命令是 `adb shell settings put global http_proxy :0`
> 这个很重要的, 希望大家注意. 如果操作不对, 很有可能导致你的手机无法正常上网.

5. 到处为止, 大家就可以愉快的抓包了. 要么去 `VMOS` 的应用商店下载应用, 要么自己把应用传递到 `VMOS` 当中. 这个大家自己
去探索吧, 是非常简单的操作.

---

## Charles 在 iphone 上安装证书方法

- Charles 当中点击 `Help > SSL Proxying > Install Charles Root Certificate on a Mobile Device or 
Remote Browser`

![image](/images/develop_charles_ready.png)


- 点击 `iPhone` 手机的 **Safari** 或者 **Safari浏览器**, 输入网址 `http://chls.pro/ssl`, 点击下载 Charles 
的证书.

- 进入 `iPhone` 手机的 **Settings > General > Profile(s)** 或者 **设置 > 通用 > 描述文件**:

![image](/images/develop_charles_profile.png)

- 点击 **Install** 或者 **安装**, 安装 `chls` 证书.

![image](/images/develop_charles_install.png)

- 进入 `iPhone` 手机的 **Settings > General > About > Certificate Trust Settings** 或者 **设置 > 通用 >
关于本机 > 证书信任设置**,  启用已经安装好的 `Charles Proxy CA` 证书.

![image](/images/develop_charles_confirm.png)
