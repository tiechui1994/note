## GoLand 使用过程中的问题

#### 在 Ubuntu 16.04 版本中, 无法输入中文的问题.

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


#### 在 Ubuntu 16.04 版本中, 经常出现 GoLand (版本 GoLand 2017.3 )崩溃的问题. 

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
