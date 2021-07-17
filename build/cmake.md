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


## 常用函数

- cmake_minimum_required

指定CMake的最低版本.

语法: 
```
cmake_minimum_required(VSERSION major[.minor[.patch[.tweak]]]  [FALT_ERROR])
```

cmake_minimum_required(VSERSION 3.0)

- aux_source_directory

将dir目录下所有源文件的名称保存再变量var中

语法:
```
aux_source_directory(<dir> <var>)
```

aux_source_directory(. DIR_SRC)


- add_executable

用于指定从一组源文件source1, source2... sourceN编译出一个可执行文件且命名为name

语法:
```
add_executable(<name> [WIN32] [MACOS_BUNDLE] [EXCLUDE_FROM_ALL] source1 source2 ...)  
```

- add_libiary

用于指定从一组源文件source1, source2... sourceN编译出一个库文件且命名为name

语法:
```
add_libiary(<name> [STATIC|SHARED|MOUDLE] [EXCLUDE_FROM_ALL] source1 source2 ...)  
```

- add_dependencies

用于指定某个目标(可执行文件或者库文件)依赖于其他的目录. 这里的目标必须是add_executable, add_library, add_custom_target
命令创建的目标

语法:
```
add_dependencies(target-name denpend-target1 denpend-target2 ...)
```


- add_subdirectory

用于添加一些需要进行构建的子目录

语法:
```
add_subdirectory(source_dir [binary_dir] [EXCLUDE_FROM_ALL])
```

add_subdirectory(lib)


- target_link_libraries

用于指定target需要链接 item1 item2 ..., 这里的target必须已经被创建, 链接的item可以是已经存在的target(依赖关系会自
动添加)

语法:
```
target_link_libraries(<target> item1 item2 ... [debug|optimized|general])
```

- message

输出信息

语法:
```
message([STATUS | WARNING | AUTHOR_WARNING | FATAL_ERROR | SEND_ERROR] "message")
```

- include_directories

用于设置目录, 这些设定的目录被编译器用于查找include文件

语法:
```
include_directories([AFTER | BEFORE] [SYSTEM] dir1 dir2 ...)
```

- find_path

用于查找包含文件name1的路径, 如果找到则将路径保存到VAR(此路径为一个绝对路径), 如果没有找到则结果为<VAR>-NOTFOUND.
默认情况下, VAR会被保存再Cache中, 这时候我们需要清除VAR才可以进行下一次查询

语法:
```
find_path(<VAR> name1 [path1 path2 ...])
```

find_path(LUA_INCLUDE_PATH lua.h ${LUA_INCLUDE_FIND_PATH})
if(NOT LUA_INCLUDE_PATH)
    message(SEND_ERROR "Header file lua.h not found")
endif()


- find_library

用于查找库文件name1的路径, 如果找到则将路径保存在VAR中(此路径为一个绝对路径), 如皋没有找到则结果为<VAR>-NOTFOUND. 一
个类似的命令link_directories已经不太建议使用了.

语法:
```
find_library(<VAR> name1 [path1 path2 ..])
```

> 注意: find_path 和 find_library 如果提供了path路径, 只有name1在提供的路径(作为父级目录)才算找到.

- add_definitions

用于添加编译器命令行标志(选项), 通常的情况下我们使用其来添加预处理器定义

```
add_definitions(-DFOO -DBAR ...)
```

- file

丰富的文件和目录的相关操作

a. 目录的遍历
b. GLOB用于产生一个文件(目录)路径列表并保存再var中
c. 文件路径列表中的每个文件的文件名都能匹配globbing expressions(非正则表达式, 但是类似)
d. 如果指定了 REVATIVE 路径, 那么返回的文件路径列表中的路径相对于 REVATIVE 的路径

```
file(GLOB var [RELVATIVE path] [globbing expressions] ...)
```

file(GLOB VAR RELATIVE ${PROJECT_BINARY_DIR} "${PROJECT_BINARY_DIR}/*/*.c")


## 常用的变量

CMAKE_SIZEOF_VOID_P 表示void*的大小(例如4或者8), 可以使用其来判断当前构建为32位还是64位

CMAKE_CURRENT_LIST_DIR 表示正则处理的CMakeLists.txt文件所在的目录的绝对路径

CMAKE_ARCHIVE_OUTPUT_DIRECTORY 用于设置ARCHIVE目标的输出路径

CMAKE_LIBRARY_OUTPUT_DIRECTORY 用于设置LIBRARY目标的输出路径

CMAKE_RUNTIME_OUTPUT_DIRECTORY 用于设置RUNTIME目标的输出路径
