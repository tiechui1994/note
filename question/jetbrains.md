# JetBrains 系列软件的中文输入和显示的问题

- 启动的脚本当中添加如下设置:

```
export GTK_IM_MODULE=fcitx 
export QT_IM_MODULE=fcitx 
export XMODIFIERS=@im=fcitx
```

- jvm设置 (vmoptions文件), 追加如下设置: 

```
-Dfile.encoding=UTF-8
```

- 文件编辑器的设置 (Editor -> File Encodings), 全部选择成UTF-8
