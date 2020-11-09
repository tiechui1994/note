# adb 常用的小技巧

### 修改手机的代理方式(root权限)

- set

```
adb shell settings put global http_proxy IP:PORT
adb shell settings put global https_proxy IP:PORT
```

例如:

```
adb shell settings put global http_proxy 192.168.50.14:8888
```

- get 

```
adb shell settings get global http_proxy
adb shell settings get global https_proxy
```

- delete

```
adb shell settings delete global http_proxy
adb shell settings delete global https_proxy
```
