## ubuntu x86_64 机器上编译 arm 库文件

- C 编译静态库(.a) 和 动态库(.so), arm32

1.安装 gcc-arm-linux-gnueabihf 
```
sudo apt-get update
sudo apt-get install gcc-arm-linux-gnueabihf
```

2.编译

```
arm-linux-gnueabihf-gcc -c *.c
arm-linux-gnueabihf-gcc-ar rcs libxxx.arm32.a *.o  或者 arm-linux-gnueabihf-ar rcs libxxx.arm32.a *.o
```

> *.c 是所有库文件的实现, 不包括测试文件和调用库文件


- C 编译静态库(.a) 和 动态库(.so), arm64

```
wget https://releases.linaro.org/components/toolchain/binaries/5.3-2016.02/aarch64-linux-gnu/gcc-linaro-5.3-2016.02-x86_64_aarch64-linux-gnu.tar.xz 

tar xvf gcc-linaro-5.3-2016.02-x86_64_aarch64-linux-gnu.tar.xz -C /usr/lib/

echo 'export PATH="$PATH:/usr/lib/gcc-linaro-5.3-2016.02-x86_64_aarch64-linux-gnu/bin"' >> ~/.bashrc

source ~/.bashrc
```

2.编译

```
aarch64-linux-gnu-gcc -c *.c
aarch64-linux-gnu-gcc-ar rcs libxxx.arm64.a *.o  或者 aarch64-linux-gnu-ar rcs libxxx.arm64.a *.o
```

## golang 交叉编译

```
export CGO_ENABLED=1 # 是否启用CGO
export GOOS=linux 
export GOARCH=arm
export GOARM=7
export CC=arm-linux-gnueabihf-gcc
export CXX=arm-linux-gnueabihf-g++
```

> GOOS 是操作系统,常见值包括 android, darwin, darwin, windows 等

> GOARCH 是目标架构, 常见的值有 amd64, 386, arm, arm64等

> GOARM 只是针对arm架构的版本

> CC是C编译器, 默认是gcc, 在amd64上面针对arm32可以使用 arm-linux-gnueabihf-gcc, 针对arm64可以使用aarch64-linux-gnu-gcc, 进行交叉编译

> CC是C++编译器, 默认是g++, 在amd64上面针对arm32可以使用 arm-linux-gnueabihf-g++, 针对arm64可以使用aarch64-linux-gnu-g++, 进行交叉编译

