# ffmpeg

[ffmpeg静态编译下载](https://ffmpeg.org/download.html)

[相关的文档](https://www.kancloud.cn/zhenhuamcu/ffmpeg/758350)

## 视频格式转换

- mp3 -> wav 

```bash
ffmpeg -i in.mp3 -acodec pcm_s16le -ac 1 -ar 16000 out.wav
```

- wav -> mp3

```bash
ffmpeg -i in.wav -acodec mp3lame -y out.mp3
```

- amr -> wav

```bash
ffmpeg -i in.amr -acodec amr_nb  out.wav
```

- wav -> amr

```bash
ffmpeg -i in.wav -acodec amr_nb -ac 1 -ar 8000 -ab 12.20k -y out.amr
```

- mp3 -> amr

```bash
ffmpeg -i in.mp3 -ac 1 -ar 8000 -ab 12.20k out.amr
```

- amr -> mp3

```bash
ffmpeg -i in.amr -ac 1 -ar 44100 -ab 128k out.mp3
```

- pcm -> wav

```bash
ffmpeg -i input.pcm -f s16be -ar 8000 -ac 2 -acodec pcm_s16be  output.wav
```

- wav -> pcm

```bash
ffmpeg -i input.wav -f s16be -ar 8000 -ac 1 -acodec pcm_s16be output.pcm
```


> 说明:
> 
> - `-sample_fmt[:stream_specifier] sample_fmt` 设置音频采样格式.
> - `-ar[:stream_specifier] freq`, 设置音频采样率. 常用值 22050Hz, 44100Hz, 48000Hz
> - `-ac[:stream_specifier] channels`, 设置音频通道, 默认值是1
> - `-ab`, 设置音频编码率, 值 96kbps, 112kbps, 128kbps, 160kbps, 192kbps, 256kbps, 320kbps
> - `-acodec codec`, 编码器. `-codec:a` 的别名, 通过 `ffmpeg -codecs` 可以查看支持的所有的编码器
> - `-aq quality`, 设置音频质量(特定于编解码器), `-q:a` 的别名
> - `-aframes number`, 设置录制音频帧的个数. `-frames:a` 的别名
> - `-an` 禁止音频录制
 
 

## 生成视频缩略图

- 等比例缩放

```
ffmpeg -i input.mp4 -vf scale=320:-1 -t 0.001 -y -f mjpeg out.jpeg
```

- 固定大小 

```
ffmpeg -i input.mp4 -s 200x200 -t 0.001 -y -f mjpeg out.jpeg
```

> -t duration, 录制或转码 "duration" 秒的音频/视频
> -s size, 生成的帧大小(WxH)
> -vf filter_graph 设置视频过滤. 参数参考: https://ffmpeg.org/ffmpeg-filters.html 
> -f fmt, 强制输出的格式. 针对图片, 格式有: singlejpeg(jpeg) mpjpeg(jpeg), webp(webp), apng(png)
