# NATS 学习

NATS(Message bus)是一个开源的、轻量级、高性能的，支持发布、订阅机制的分布式消息队列系统. 其核心原理就是基于消息发布订阅机制。每个台服务器上
的每个模块会根据自己的消息类别，向MessageBus发布多个消息主题; 而同时也向自己需要交互的模块，按照需要的信息内容的消息主题订阅消息.

NATS消息传递模型

NATS支持各种消息传递模型, 包括:

- 发布订阅(Publish Subscribe)

- 请求回复(Request Reply)

- 队列订阅(Queue Subscribers)

### 发布订阅

NATS 将 publish/subscribe 消息分发模型实现为一对多通信, 发布者在 Subject 上发送消息, 并且监听该 Subject 的任何订阅者都会收到该消息.

![image](/images/webrtc_nats_pubsub.svg)

> 类似组播的通信方式.

### 请求响应

NATS支持两种请求响应消息: 点对点. 点对点涉及最快或首先响应. 在一对多的消息交换中, 需要限制请求响应的限制.

1) NATS 使用其核心通信机制(发布和订阅)支持请求-回复模式. 

2) 多个 NATS 响应者可以形成动态队列组

![image](/images/webrtc_nats_req.svg)

### 队列订阅 & 分享工作

NATS提供称为队列订阅的负载均衡功能, 虽然名字为 queue(队列) 但是并不是我们所认为的那样. 他的主要功能是将具有相同 queue 名字的 subject 进
行负载均衡. 使用队列订阅功能消息发布者不需要做任何改动, 消息接受者需要具有相同的对列名.

![image](/images/webrtc_nats_queue.svg)


## 应用

