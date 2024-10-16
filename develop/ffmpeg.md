# ffmpeg

[ffmpeg静态编译下载](https://ffmpeg.org/download.html)

[相关的文档](https://www.kancloud.cn/zhenhuamcu/ffmpeg/758350)

## 视频加速/减速

可以通过更改每个视频帧的呈现时间戳 (PTS) 来更改视频流的速度. 可以通过两种方法完成: 使用 'filter:v' 选项 setpts (需要重新编码)
或通过将视频导出为原始比特流格式并在创建新时间戳时复用到容器来擦除时间戳.


- setpts 视频过滤器

```
ffmpeg -i input.mkv -filter:v "setpts=0.5*PTS" output.mkv
```

通过更改每个视频帧的呈现时间戳 (PTS) 来工作. 例如, 在时间戳1和2处连续显示2个帧, 并且加速视频速度, 则时间戳需要分别
变为 0.5, 1, 因此乘以 0.5. *此方法将丢帧以达到所需的速度*.

可以通过指定比输入更高的输出帧速率来避免丢帧. 例如, 从 4FPS 的输入加速到 4倍(16FPS)的输入:

```
ffmpeg -i input.mkv -r 16 -filter:v "setpts=0.25*PTS" output.mkv
```

要减慢视频速度, 乘以的系数必须大于1


- 原始比特流(无损)

1) 视频复制为原始比特流格式

```
# H.264
ffmpeg -i input.mp4 -map 0:v -c:v copy -bsf:v h264_mp4toannexb raw.h264

# H.265
ffmpeg -i input.mp4 -map 0:v -c:v copy -bsf:v hevc_mp4toannexb raw.h265
```

2) 封装到容器时生成新的时间戳

```
ffmpeg -fflags +genpts -r 30 -i raw.h264 -c:v copy output.mp4
```

`-r` 为目标帧速率


平滑

使用插值视频过滤器平滑慢/快视频, 运动插值.

```
ffmpeg -i input.mkv -filter:v "minterpolate='mi_mode=mci:mc_mode=aobmc:vsbmc=1:fps=120'" output.mkv
```

`mi_mode` 运动差值模式, `mc_mode` 运动补偿模式, 在 `mi_mode=mci` 下生效. `fps` 指定输出帧速率, 默认是60

详情参考 `https://ffmpeg.org/ffmpeg-all.html#minterpolate`


## 音频加速/减速

可以使用 `atempo` 音频过滤器加快或减慢音频

音频加速:
```
ffmpeg -i input.mkv -filter:a "atempo=2.0" -vn output.mkv
```

`atempo` 过滤器仅限于使用 0.5 到 2.0 之间的值. 如果需要, 可以通过将多个 `atempo` 过滤器串在一起来绕过此限制. 例如
音频加速4倍:

```
ffmpeg -i input.mkv -filter:a "atempo=2.0, atempo=2.0" -vn output.mkv
```

总结: 音视频加速/减速

```
ffmpeg -i input.mkv -filter_complex "[0:v]setpts=0.5*PTS[v]; [0:a]atempo=2.0[a]" -map "[v]" -map "[a]" output.mkv
```


```
ffmpeg -fflags +genpts -r 15 -i raw.h264 -i input.mp4 -map 0:v -c:v copy -map 1:a -af atempo=0.5 -movflags faststart output.mp4
```

## 常见音频格式转换

```
# mp3 -> wav 
ffmpeg -i in.mp3 -acodec pcm_s16le -ac 1 -ar 16000 out.wav

# wav -> mp3
ffmpeg -i in.wav -acodec mp3lame -y out.mp3


# amr -> wav
ffmpeg -i in.amr -acodec amr_nb  out.wav

# wav -> amr
ffmpeg -i in.wav -acodec amr_nb -ac 1 -ar 8000 -ab 12.20k -y out.amr


# mp3 -> amr
ffmpeg -i in.mp3 -ac 1 -ar 8000 -ab 12.20k out.amr

# amr -> mp3
ffmpeg -i in.amr -ac 1 -ar 44100 -ab 128k out.mp3



# pcm -> wav
ffmpeg -i input.pcm -f s16be -ar 8000 -ac 2 -acodec pcm_s16be  output.wav

# wav -> pcm
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

## FFmpeg 编译

使用 NVIDIA 硬件加速

- compile ffmpeg with NVIDIA we need ffnvcodec

```
mkdir ~/nvidia/ && cd ~/nvidia/
git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git

cd nv-codec-headers && sudo make install
```

- compile ffmpeg

```
cd ~/nvidia/
git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg

sudo apt install build-essential yasm cmake libtool libc6 libc6-dev unzip wget libnuma1 libnuma-dev

cd ~/nvidia/ffmpeg/
./configure --enable-nonfree --enable-cuda-nvcc --enable-libnpp --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64

make -j $(nproc)

ls -l ffmpeg
```