# adb 常用的小技巧

## 修改手机的全局代理(root权限)

- 设置

```
adb shell settings put global http_proxy IP:PORT
adb shell settings put global https_proxy IP:PORT
```

例如:

```
adb shell settings put global http_proxy 192.168.50.14:8888
```

- 获取 

```
adb shell settings get global http_proxy
adb shell settings get global https_proxy
```

- 移除(很重要, 也是很关键的, 不能使用 `delete`, 这可能导致你的手机无法正常上网)

```
adb shell settings put global http_proxy :0
adb shell settings put global https_proxy :0
```

## 私有 dns 

- 开启 `private_dns_mode` 的模式为 `hostname`, 并且设置域名主机为 `one.one.one.one`

```bash
settings put global private_dns_mode hostname
settings put global private_dns_specifier one.one.one.one
```

- 关闭

```bash
settings put global private_dns_mode off
```
