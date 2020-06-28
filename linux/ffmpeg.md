# ffmpeg

[ffmpeg静态编译下载](https://ffmpeg.org/download.html)

- mp3 -> wav 

```bash
ffmpeg -i in.mp3 -acodec pcm_s16le -ac 1 -ar 16000 out.wav
```

- amr -> wav

```bash
ffmpeg -i in.amr -acodec amr_nb  out.wav
```

- wav -> amr

```bash
ffmpeg -i in.wav -acodec opencore_amrnb -ac 1 -ar 8000 -ab 12.20k -y out.amr
```

- wav -> mp3

```bash
ffmpeg -i in.wav -acodec mp3lame -y out.mp3
```

> 说明:
> 
> - `-ar`, 设置输出文件的音频频率. 常用值 22050 Hz, 44100 Hz, 48000 Hz
> - `-ac`, 设置音频通道的数目
> - `-ab`, 设置音频比特率, 值 96kbps, 112kbps, 128kbps, 160kbps, 192kbps, 256kbps, 320kbps
> - `-acodec`, 编码器, 通过 `ffmpeg -codecs` 可以查看支持的所有的编码器