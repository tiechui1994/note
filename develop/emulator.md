# Google Android 模拟器

主要的步骤如下:

- 安装 jdk8

- 安装 [cmdline-tools](https://developer.android.com/studio/command-line?hl=zh-cn)

- 设置环境变量

- 使用 sdkmanager 安装 emulator, system-images

- 使用 avdmanager 创建 avd

- 使用 emulator 启动创建的 AVD

详细的脚本如下:

```
WORKDIR=$PWD

# download jdk8, android sdk depends jdk8
cd $WORKDIR
wget -O jdk-8u202-linux-x64.tar.gz \
'https://github.abskoop.workers.dev/https://github.com/tiechui1994/actions/releases/download/jdk_8/jdk-8u202-linux-x64.tar.gz'

tar xvf jdk-8u202-linux-x64.tar.gz
mv jdk1.8.0_202 jdk8 && rm -rf jdk-8u202-linux-x64.tar.gz

export JAVA_HOME=$WORKDIR/jdk8
export CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib

# Download Command Tools
wget -O sdk-tools.zip https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip
unzip sdk-tools.zip && rm sdk-tools.zip

# Set Env
mkdir -p $WORKDIR/Android/sdk
mv tools $WORKDIR/Android/sdk/tools
export ANDROID_SDK_ROOT=$WORKDIR/Android/sdk
export ANDROID_HOME=$WORKDIR/Android/sdk

# Setup init
cd $WORKDIR/Android/sdk/tools/bin && yes | ./sdkmanager --licenses

# Install  platform-tools, emulator, system-images
cd $WORKDIR/Android/sdk/tools/bin && ./sdkmanager platform-tools emulator

cd $WORKDIR/Android/sdk/tools/bin && ./sdkmanager "system-images;android-28;google_apis;x86"

# Create AVD Device
# 系统将询问您是否要更改某些配. 你可以稍后在文件 config.ini 中修改这些配置, 该文件位于 avd 文件夹(通常在
# $HOME/.android 目录下). 当前活动的配置可以在文件 hardware-qemu.ini 中找到(该文件将在模拟器首次运行后创建)
cd $WORKDIR/Android/sdk/tools/bin && ./avdmanager create avd --name android28 --package "system-images;android-28;google_apis;x86"

# Run (二选一)
cd $WORKDIR/Android/sdk/tools && ./emulator -avd android28
cd $WORKDIR/Android/sdk/tools && ./emulator @android28
```

> 注: 在 VirtualBox 上的 KVM 上的 CPU 必须支持 vmx or svm.
 
