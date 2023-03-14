## systemd-networkd

systemd-networkd 是管理网络的系统服务. 它检测并配置出现的网络设备, 以及创建虚拟网络设备.

systemd-networkd 根据 systemd.netdev 文件中的配置创建网络设备, 并遵循文件中的 `[Match]` 部分. 对于


配置文件读取的顺序:

- /lib/systemd/network, 系统网络
- /run/systemd/network, 运行时网络
- /etc/systemd/network, 本地管理网络

network 配置文件是以 `.network` 结尾文件, 详情参考 `systemd.network`, virtual network device 配置文件是以 
`.netdev` 结尾文件.


### network 配置选项





