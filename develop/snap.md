## 关于 snap 应用安装问题

### 常规安装

```
sudo snap install hello_world 
```

> 存在的问题: 安装的过程是先下载应用, 后安装. 一旦连接断开, 无法自动重连, 对于大安装包, 很难成功


### 非常规安装

- 查看snap包的信息
```
snap info hello-world
```

里面包含了snap-id和channels(相应的版本号)

- http下载snap包

```
https://api.snapcraft.io/api/v1/snaps/download/{snap-id}_{channels}.snap
```

- 安装snap包

```
sudo snap install /path/filename.snap
```