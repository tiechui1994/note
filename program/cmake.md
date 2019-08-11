# cmake 语法

## 构建可执行程序

hello.c 源代码:
```
#include <stdio.h>

int main() {
    printf("Hello, World!\n");
    return 0;
}
```

CMakeLists.txt
```
# 设置cmake最低版本 和 CMAKE_C_STANDARD (C版本)
cmake_minimum_required(VERSION 3.5)
set(CMAKE_C_STANDARD 11)

# 指定工程名称
project(hello)

# 打印系统的变量
message(STATUS "this is PROJECT_SOURCE_DIR " ${PROJECT_SOURCE_DIR})
message(STATUS "this is PROJECT_BINARY_DIR " ${PROJECT_BINARY_DIR})

# set指令, 设置变量SOURCE_FILES的值
set(SOURCE_FILES main.c)
# 打印 SOURCE_FILES 变量
message(STATUS "this is SOURCE_FILES " ${SOURCE_FILES})

# 生成可执行文件 hello, ${SOURCE_FILES}是引用变量
add_executable(hello ${SOURCE_FILES})
```

## 构建动态库

目录结构:
```
src
 |-add.c
include
 |-add.h
lib
 |-libmath.so (目标生成文件)
```

CMakeLists.txt
```
# 设置cmake最低版本 和 CMAKE_C_STANDARD (C版本)
cmake_minimum_required(VERSION 3.5)
set(CMAKE_C_STANDARD 11)

# 指定工程名称
project(hello)

# 把当前工程下的src目录下的所有的.c文件赋值给 SRC_LIST
# aux_source_directory(${PROJECT_SOURCE_DIR}/src SRC_LIST)
file(GLOB SRC_LIST "${PROJECT_SOURCE_DIR}/src/*.c")

# 打印 SRC_LIST
# message(STATUS ${SRC_LIST})

# 指定头文件目录
include_directories(${PROJECT_SOURCE_DIR}/include)

# 设置输出 .so 动态库的目录位置 (LIBRARY_OUTPUT_PATH是系统变量)
set(LIBARY_OUTPUT_PATH ${PROJECT_SOUCRE_DIR}/lib)

# 指定生成动态库
add_library(math SHARED ${SRC_LIST})

# 设置生成版本 VERSION 指动态库版本, SOVERSION指API版本
# set_target_properties(math PROPERTIES VERSION 1.2 SOVERSION 1)
```

## 链接外部动态库和头文件

在 **构建动态库** 的基础上, 将lib目录和include目录copy到 hello.c 同级目录下, 重新修改 hello.c 源码:
```
#include <stdio.h>
#include "add.h"

int main(int argc, char* argv[]){
        int a = 20;
        int b = 10;
        printf("%d+%d=%d\n",a,b,add(a,b));
        return 0;
}
```

CMakeLists.txt
```
cmake_minimum_required(VERSION 3.5)

project(hello)

# 指定头文件目录位置
include_directories(${PROJECT_SOURCE_DIR}/include)

# 添加共享库搜索路径(很重要)
link_directories(${PROJECT_SOURCE_DIR}/lib)

set(SOURCE_FILES hello.c)
add_executable(hello ${SOURCE_FILES})

# 为hello添加共享库链接(很重要)
target_link_libraries(hello math)
```

