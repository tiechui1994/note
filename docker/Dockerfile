FROM ubuntu:16.04

MAINTAINER user user@gmail.com

RUN echo "deb http://mirrors.aliyun.com/ubuntu/ trusty main restricted universe multiverse \
deb http://mirrors.aliyun.com/ubuntu/ trusty-security main restricted universe multiverse \
deb http://mirrors.aliyun.com/ubuntu/ trusty-updates main restricted universe multiverse \
deb http://mirrors.aliyun.com/ubuntu/ trusty-proposed main restricted universe multiverse \
deb http://mirrors.aliyun.com/ubuntu/ trusty-backports main restricted universe multiverse \
deb-src http://mirrors.aliyun.com/ubuntu/ trusty main restricted universe multiverse \
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-security main restricted universe multiverse \
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-updates main restricted universe multiverse \
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-proposed main restricted universe multiverse \
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-backports main restricted universe multiverse" \
> /etc/apt/sources.list

RUN apt-get update
