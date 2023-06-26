# git submodule

## 子模块初始化

```
# clone project, submodule status
$ git submodule status 
-edcc3323fc44ed33b8ae89a18c5dc38a0efd4885 leo

# init submodule leo(submodule ok)
$ git submodule update --init leo

# after init, submodule status
$  git submodule status
 edcc3323fc44ed33b8ae89a18c5dc38a0efd4885 leo (remotes/origin/develop)
```

## 子模块版本更新

```
# first commit submodule and push, check HEAD version
$ git commit -m "submodule"
$ git rev-parse HEAD 

# check to parent, check submodule version, check equals. commit and push
$ git submodule
$ git commit -m "xxx"
```

## 创建子模块

```

```


## 子模块 submodule 时遇到的问题

1) 问题 `fatal: Needed a single revision, Unable to find current revision in submodule path 'xxx'` 或
`Fetched in submodule path 'xxx', ... Direct fetching of that commit failed`

解决方案一: (手动 clone submodule)

```
# remove old dir
rm -rf xxx

# use recurse clone submodule git repo
git clone git@github.com:example/xxx.git --branch=develop xxx
git clone --recurse-submodules git@github.com:example/xxx.git --branch=develop xxx

# init
git submodule update --init xxx

# check submodule version
$ git submodule 
-94babad95c5832f747b14e16fbc664258c5a3919 alarm
 ed32cdbf5e778e213f78d7126159147417e3c45d xxx (v1.0.0-9-ged32cdb)
-8c8272f678bf2ab50d0e8229dc37dbc479ef7d68 testtool
user@master:/tmp/www/dx/leo$ 
```

解决方案二: (如果只是配置了 ssh 秘钥, 没有 http 拉取子模块的权限, 则可以更新 pull 代码方式)

```
[url "ssh://git@github.com"]
	insteadof = https://github.com
```

> 这种场景就是 .gitmodules 当中配置的 submodule 的 url 是 https 方式的私有仓库, 则需要转换成 git 方式去拉去代码.


注: 方式一与方式二的不同之处在于子模块下的 .git 文件, 对于方式一, .git 是一个目录, 里面单独记录子模块的信息. 对于方
式二, .git 是一个文件, 其指向更上一层级的 .git 目录.
