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


## 打开开发者选项

- 正常手机或平板

```
am start -n com.android.settings/com.android.settings.DevelopmentSettings
```

- 电视TV

```
am start -n com.android.tv.settings/com.android.tv.settings.system.development.DevelopmentActivity
```

## 调用 activity 管理器

adb 使用详情: https://developer.android.com/studio/command-line/adb

在 `adb shell` 中, 可以使用 activity 管理器(`am`) 工具发出命令以执行各种操作系统操作, 例如启动 activity, 强制
停止进程, 广播 intent, 修改设备屏幕属性等.

- Activity

```
start [options] intent    启动由 intent 指定的 Activity

选项参数:
- '-D', 启动调试功能
- '-W', 等待启动完成
- '--start-profile file', 启动性能分析器并将结果发送至file
- '-P file', 类似 '--start-profile', 但当应用进入空闲状态时剖析停止.
- '-R count', 重复启动 Activity count 次. 在每次重复前, 将完成顶层 Activity.
- '-S', 在启动 Activity 前, 强行停止目标应用.
- '--userid user_id | current', 指定作为哪个用户运行. 默认是作为当前用户执行.
```

- Service

```
startservice [options] intent   启动由 intent 指定的 Service
选项参数:
- '--userid user_id | current', 指定作为哪个用户运行. 默认是作为当前用户执行.
```

- Broadcast

```
broadcast  [options] intent   发出广播 intent.
选项参数:
- '--userid user_id  | all | current', 指定要发送给哪个用户. 默认是发送所有用户. 
```

- Debug

```
set-debug-app [options] package  设置要调试的应用 package.

选项参数:
- '-w', 等待启动完成


clear-debug-app    清除之前使用 set-debug-app 设置的用于调试的软件包.
```
