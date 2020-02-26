## virtualbox 直接复制安装文件导致的的问题

操作描述 - 当前已经安装了一个名称为 ubuntu 的vbox. 操作如下:

1.将 ubuntu 安装文件复制并修改为 arm. 

2.修改了 arm 目录当中的文件名称为 arm.vbox, arm.vbox-prev, arm.vdi. 并且将 arm.vbox-prev 删除掉.

3.修改arm.vbox的内容:
```
<Machine uuid="{92130f55-3a6c-4f16-a43c-6d8eea13d9d2}" name="ubuntu" OSType="Ubuntu_64" snapshotFolder="Snapshots" lastStateChange="2020-02-26T01:55:55Z">
 
<Machine uuid="{92130f55-3a6c-4f16-a43c-6d8eea13d9d2}" name="arm" OSType="Ubuntu_64" snapshotFolder="Snapshots" lastStateChange="2020-02-26T01:55:55Z">
  

<HardDisk uuid="{e490b3a6-0936-4b5b-bf46-67a788f827ac}" location="ubuntu.vdi" format="VDI" type="Normal"/>

<HardDisk uuid="{e490b3a6-0936-4b5b-bf46-67a788f827ac}" location="arm.vdi" format="VDI" type="Normal"/>
```

4.上述修改之后打开arm.vbox, 出现问题:

```
Failed to open virtual machine [...]
Trying to open a VM config [...] which has the same UUID as an existing virtual machine.
```


解决问题 

1.调用命令 `run VBoxManage internalcommands sethduuid <VDI/VMDK file>` 两次, 生成两个uuid

2.修改arm.vbox文件
```
① 将带 <Machine uuid="{92130f55-3a6c-4f16-a43c-6d8eea13d9d2}" ...> 当中的uuid修改为第一次生成的uuid的值
② 将带 <HardDisk uuid="{89ee191f-b444-412f-91e8-e5f4f7ec7005}" ...> 和 <Image uuid="{b0e50340-6df2-4b55-8d70-54adca362dbf}" ...> 部分的uuid修改为
第二次生成的uuid的值
③ 删除<HardDisks>标签内的内容, 使其变成为 <HardDisks></HardDisks>
```

3.在上述修改之后重新打开arm.vbox即可.


