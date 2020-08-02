## Charles 在 iPhone iso 13 版本上安装证书方法

- Charles 当中点击 `Help > SSL Proxying > Install Charles Root Certificate on a Mobile Device or 
Remote Browser`

- 点击 `iPhone` 手机的 **Safari** 或者 **Safari浏览器**, 输入网址 `http://chls.pro/ssl`, 点击下载 charles 
的证书

- 进入 `iPhone` 手机的 **Settings > General > Profile(s)** 或者 **设置 > 通用 > 描述文件**:

![image](/images/charles_profile.png)

- 点击 **Install** 或者 **安装**, 安装 `chls` 证书.

![image](/images/charles_install.png)

- 进入 `iPhone` 手机的 **Settings > General > About > Certificate Trust Settings** 或者 **设置 > 通用 >
关于本机 > 证书信任设置**,  启用已经安装好的 `Charles Proxy CA` 证书.

![image](/images/charles_confirm.png)
