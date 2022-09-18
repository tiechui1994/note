## NATS

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

## Google Protoc 安装

```
# protoc 
curl -L https://github.com/protocolbuffers/protobuf/releases/download/v21.6/protoc-21.6-linux-x86_64.zip -o protoc.zip

# protoc-gen-go-grpc
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# protoc-gen-go
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
```

## 应用

### NATS gRPC

github.com/cloudwebrtc/nats-grpc/pkg/rpc, nats-grpc-server, 实现了 grpc.GRPCServer, 使用 NATS 作为通信传输层来进行 RPC 调用.


```protobuf
syntax = "proto3";

option go_package = ".;echo";

package echo;

service Echo {
    rpc SayHello(HelloRequest) returns (HelloReply) {}
    rpc Echo(stream EchoRequest) returns (stream EchoReply) {}
}

message HelloRequest {
    string msg = 1;
}

message HelloReply {
    string msg = 1;
}

message EchoRequest {
    string msg = 1;
}

message EchoReply {
    string msg = 1;
}
```


- echo 实现

```golang
type echoServer struct {
	echo.UnimplementedEchoServer
}

func (e *echoServer) Echo(stream echo.Echo_EchoServer) error {
	i := int(0)
	for {
		req, err := stream.Recv()
		if err != nil {
			log.Errorf("err: " + err.Error())
			return err
		}
		i++
		log.Infof("Echo: req.Msg => %v, count => %v", req.Msg, i)
		stream.Send(&echo.EchoReply{
			Msg: req.Msg + fmt.Sprintf(" world-%v", i),
		})

		if i >= 100 {
			//stop loop now, close streaming from server side.
			return nil
		}
	}
}

func (e *echoServer) SayHello(ctx context.Context, req *echo.HelloRequest) (*echo.HelloReply, error) {
	fmt.Printf("SayHello: req.Msg => %v\n", req.Msg)
	return &echo.HelloReply{Msg: req.Msg + " world"}, nil
}
```

- 原生 gRPC 的 Server 与 Client

// Server

```golang
import (
    "google.golang.org/grpc"
)

func main() {
    listen, err := net.Listen("tcp", ":8080")
    if err != nil {
        log.Fatalf("failed to listen: %v", err)
    }

    s := grpc.NewServer()
    echo.RegisterGreeterServer(s, &echoServer{})
    
    log.Printf("server listening at %v", listen.Addr())
    if err := s.Serve(listen); err != nil {
        log.Fatalf("failed to serve: %v", err)
    }
}
```

// Client

```golang
import (
    "google.golang.org/grpc"
)

func main() {
    conn, err := grpc.Dial("127.0.0.1:8080", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()
	
    client := echo.NewGreeterClient(conn)

	// Contact the server and print out its response.
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
    
    // Request
    reply, err := client.SayHello(ctx, &echo.HelloRequest{Msg: "hello"})
    if err != nil {
        log.Infof("SayHello: error %v\n", err)
        return
    }
    log.Infof("SayHello: %s\n", reply.GetMsg())

    // Streaming
    stream, err := client.Echo(ctx)
    if err != nil {
        log.Errorf("%v", err)
    }

    stream.Send(&echo.EchoRequest{
        Msg: "hello",
    })

    i := 1
    for {
        reply, err := stream.Recv()
        if err != nil {
            log.Errorf("Echo: err %s", err)
            break
        }
        log.Infof("EchoReply: reply.Msg => %s, count => %v", reply.Msg, i)

        i++
        if i <= 100 {
            stream.Send(&echo.EchoRequest{
                Msg: fmt.Sprintf("hello-%v", i),
            })
        }
    }


}
```

- gRPC over NATS 的 Server 与 Client

// Server

```golang
import (
    "github.com/cloudwebrtc/nats-grpc/pkg/rpc"
    "github.com/nats-io/nats.go"
)

func main() {
    nc, err := nats.Connect("nats://127.0.0.1:4222")
    if err != nil {
        log.Errorf("%v", err)
    }
    defer nc.Close()

    s := rpc.NewServer(nc, "svcid")
    echo.RegisterEchoServer(s, &echoServer{})

    // Keep running until ^C.
    fmt.Println("server is running, ^C quits.")
    c := make(chan os.Signal, 1)
    signal.Notify(c, os.Interrupt)
    <-c
    close(c)
}
```

// Client 

```golang
import (
    "github.com/cloudwebrtc/nats-grpc/pkg/rpc"
    "github.com/nats-io/nats.go"
)

func main() {
        nc, err := nats.Connect("nats://127.0.0.1:4222")
    	if err != nil {
    		log.Errorf("%v", err)
    	}
    	defer nc.Close()
    
    	ncli := nrpc.NewClient(nc, "svcid", "nodeid")
    
    	client := echo.NewEchoClient(ncli)
    
    	ctx, cancel := context.WithTimeout(context.Background(), 100000*time.Millisecond)
    	defer cancel()
    
    	// Request
    	reply, err := client.SayHello(ctx, &echo.HelloRequest{Msg: "hello"})
    	if err != nil {
    		log.Infof("SayHello: error %v\n", err)
    		return
    	}
    	log.Infof("SayHello: %s\n", reply.GetMsg())
    
    	// Streaming
    	stream, err := client.Echo(ctx)
    	if err != nil {
    		log.Errorf("%v", err)
    	}
    
    	stream.Send(&echo.EchoRequest{
    		Msg: "hello",
    	})
    
    	i := 1
    	for {
    		reply, err := stream.Recv()
    		if err != nil {
    			log.Errorf("Echo: err %s", err)
    			break
    		}
    		log.Infof("EchoReply: reply.Msg => %s, count => %v", reply.Msg, i)
    
    		i++
    		if i <= 100 {
    			stream.Send(&echo.EchoRequest{
    				Msg: fmt.Sprintf("hello-%v", i),
    			})
    		}
    	}
}
```

小结:

原生的 gRPC 是通过 TCP 连接传递数据的, Client 通过 ip:port 来连接 Server, 然后进行请求的交互.

nats-RPC 是通过 nats 连接传递数据的, Client 和 Server 都需要先连接到 NATS 服务器. 创建 Server 时需要确定 srvid. 在 Client 进行调用
时, 是通过 srvid 来确定服务端是谁. 在这个过程中产生了节点的概念.

### NATS registry

github.com/cloudwebrtc/nats-discovery/pkg/registry, 注册中心

注册中心需要提供两个 Handler 函数:

- `handleNodeAction(action discovery.Action, node discovery.Node) (bool, error)`, 处理 Node 动作消息(Save, Update, Delete)

- `handleGetNodes(service string, params map[string]interface{}) ([]discovery.Node, error)`, 处理获取 Node 请求

> 注: `subscribe "node.publish.>"`, 每次执行完成 Save, Update, Delete 动作处理之后, 会 `publish "node.discovery.$service.$nid"`


github.com/cloudwebrtc/nats-discovery/pkg/client, 注册中心客户端:

- KeepAlive, 节点定期更新, 保证节点存活. (定期发送 Update 动作, `publish "node.publish.$service.$nid"`)

- Watch, 监测 Node 状态, 并进行 Callback. (订阅 Node 状态变更消息, 状态发生变更, 回调 callback, `subscribe "node.discovery.$service.>"`)

- Get, 获取节点信息. (`publish "node.publish.$service"`)

### ION 

![image](/images/webrtc_nats_ion.png)

islb, 注册中心, 将注册的节点存储到 redis 当中. 参考 `NATS registry` 内容.

signal, 对外统一的服务, websocket 连接, 进行 rpc 调用转发.

sfu, 提供 RTC 服务, 主要负责 WebRTC 推流, 信令协商, 信令服务等内容.

room, ROOM 服务(主要包含两部分, RoomService(服务, CreateRoom等), RoomSignal(流, Join, Leave, SendMessage, UpdateRoom)), 数据会存储到 Redis 当中

