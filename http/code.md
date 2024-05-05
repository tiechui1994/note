## 30x 重定向

关于重定向的 http code 主要有以下:
 
- 301 Moved Permanently

301 状态码表明目标资源被永久的移动到了一个新的URI, 任何未来新对这个资源的引用都应该使用新的 URI.

服务器会在响应Header的Location字段中放上这个不同的URI(目标URI). 浏览器可以使用Location中的URI进行自动重定向.

> 设置 Cache-Control 可以缓存301响应

> 浏览器(没有提供明确的缓存头状况下):
> 1. 对于 Chrome, Firefox, 会缓存 301 重定向的进行永久缓存的(重启是无效的).
> 2. 对于 Safari, 会缓存 301 重定向, 但是重启之后会清除缓存.

- 302 Found

302 状态码表示 `目标资源` 临时移动到另外一个URI上. 由于重定向是临时发生的, 所以客户端在之后的请求中URI还应该使用原来的
URI.

服务器会在响应Header的Location字段中放上这个不同的URI(目标URI). 浏览器可以使用Location中的URI进行自动重定向.

注意: 历史的原因, 用户代理可能会在重定向后的请求中把POST方法改为GET方法. 如果不想这样, 应该使用 307 (Temporary Redirect) 
状态码.

> 设置 Cache-Control 可以缓存302响应

- 303 See Other

303 状态码表示服务器要将浏览器重定向到另一个资源, 这个资源的URI会被写在响应Header的Location当中. 从语义上讲, 重定向到
的资源并不是你所请求的资源, 而是对你所请求资源的一些描述.
 
303 常用于将POST请求重定向到GET请求. 例如:上传文件成功后, 服务器发回一个303响应, 将你重定向到一个上传成功的页面.

不管原请求是什么方法, 重定向的请求方法都是GET(或HEAD).

> 303 响应禁止被缓存．


- 307 Temporary Redirect

307 的定义实际上和302是一致的, 唯一的区别在于, 307 状态码不允许浏览器将原本为POST请求重定向到GET请求上. **即不允许修
改请求方法.**


- 308 Permanently Redirect

308 的定义和301是一致的, 唯一的区别在于, 308状态码不允许浏览器将原本为POST去请求重定向到GET请求上去. **不允许修改请求
方法.**


> 301 和 308 是永久重定向, 302, 303, 307 是暂时重定向


---

> 302 303 307的区别
> 1. 302 允许各种各样的重定向, `一般情况下都会实现为到GET的重定向`. 但是不能确保POST会重定向为POST
> 2. 303 只允许任意请求到(GET|HEAD)的重定向;
> 3. 307 和 302 一样, (HEAD|GET|PUT|DELETE|POST), 除了不允许POST到GET的重定向.
 
> 301 308的区别
> 1. 301 允许各种各种的重定向(HEAD|GET|PUT|DELETE). 但是不能确保POST会重定向为POST.
> 2. 308 运行各种各样的重定向(HEAD|GET|PUT|DELETE|POST)


关于HTTP缓存策略:

HTTP 主要通过请求和响应头当中 Header 字段: Expires, Cache-Control, Last-Modified, Etag 控制的.

对于强制缓存, 响应 Header 当中 Expires, Cache-Control 标名失效的规则:

- Expires, HTTP1.0的产物, 现状默认浏览器均默认使用 HTTP1.1, 所以作用基本忽略. 在 HTTP1.1 当中被 Cache-Control 
替代.

- Cache-Control, 最重要的规则. 常见的值有 private, public, no-cache, max-age, no-store. 默认值 private

1)max-age: 设置资源的可以被缓存多长时间, 单位是秒.

2)public: 指示响应可被任何缓存区缓存.

3)private: 只能针对个人用户, 而不能被代理服务器缓存.

4)no-cache: 强制客户端直接向服务器发送请求. 也就是说每次请求都必须向服务器发送. 服务器收到请求, 然后判断资源是否变更,
是则返回新内容, 否则返回 304, 未更新. 响应会被缓存的, 只不过每次在向浏览器提供数据时, 缓存都要向服务器评估缓存响应的有效
性.

5)no-store, 禁止一切缓存(这个才是响应不被缓存).


对于对比缓存.

- Last-Modified/If-Modified-Since, 服务器响应请求时, 会告诉浏览器资源的最后修改时间: Last-Modified, 浏览器之后
再请求的时候, 会带上If-Modified-Since, 这个值是服务器上一次给的 Last-Modified 的时间, 服务器会对比资源当前的最后的
修改时间, 如果大于 If-Modified-Since, 说明资源改过了, 浏览器不再使用缓存, 否则浏览器继续使用缓存, 并返回304状态码.

- Etag/If-None-Match(优先级高于 Last-Modified/If-Modified-Since), 服务器响应请求时, 会告诉浏览器当前资源的唯一
标识, 浏览器再次请求时, 会带上 If-None-Match(上一次的 Etag 的值), 服务器会对比资源当前的Etag是否与 If-None-Match
一致, 不一致说明资源改过了, 浏览器不再使用缓存, 否则浏览器继续使用缓存, 并返回304状态码.


golang测试代码
```
func main() {
    http.HandleFunc("/api/301", func(writer http.ResponseWriter, request *http.Request) {
        writer.Header().Set("Location", "http://local.net/api/"+strings.ToLower(request.Method))
        writer.WriteHeader(http.StatusMovedPermanently)
        writer.Write([]byte("OK"))
    })
    http.HandleFunc("/api/302", func(writer http.ResponseWriter, request *http.Request) {
        writer.Header().Set("Location", "http://local.net/api/"+strings.ToLower(request.Method))
        writer.WriteHeader(http.StatusFound)
        writer.Write([]byte("OK"))
    })
    http.HandleFunc("/api/303", func(writer http.ResponseWriter, request *http.Request) {
        writer.Header().Set("Location", "http://local.net/api/"+strings.ToLower(request.Method))
        writer.WriteHeader(http.StatusSeeOther)
        writer.Write([]byte("OK"))
    })
    http.HandleFunc("/api/307", func(writer http.ResponseWriter, request *http.Request) {
        writer.Header().Set("Location", "http://local.net/api/"+strings.ToLower(request.Method))
        writer.WriteHeader(http.StatusTemporaryRedirect)
        writer.Write([]byte("OK"))
    })
    http.HandleFunc("/api/308", func(writer http.ResponseWriter, request *http.Request) {
        writer.Header().Set("Location", "http://local.net/api/"+strings.ToLower(request.Method))
        writer.WriteHeader(http.StatusPermanentRedirect)
        writer.Write([]byte("OK"))
    })

    http.HandleFunc("/api/get", func(writer http.ResponseWriter, request *http.Request) {
        if request.Method != http.MethodGet {
            writer.WriteHeader(http.StatusMethodNotAllowed)
            return
        }
        writer.WriteHeader(http.StatusOK)
        writer.Write([]byte("This is GET Method"))
    })
    http.HandleFunc("/api/post", func(writer http.ResponseWriter, request *http.Request) {
        if request.Method != http.MethodPost {
            writer.WriteHeader(http.StatusMethodNotAllowed)
            return
        }
        data, _ := ioutil.ReadAll(request.Body)
        writer.WriteHeader(http.StatusOK)
        writer.Write([]byte("This is POST Method"))
        writer.Write(data)
    })
    http.HandleFunc("/api/put", func(writer http.ResponseWriter, request *http.Request) {
        if request.Method != http.MethodPut {
            writer.WriteHeader(http.StatusMethodNotAllowed)
            return
        }
        data, _ := ioutil.ReadAll(request.Body)
        log.Printf("data: %v", string(data))
        writer.WriteHeader(http.StatusOK)
        writer.Write([]byte("This is PUT Method"))
        writer.Write(data)
    })
    http.HandleFunc("/api/delete", func(writer http.ResponseWriter, request *http.Request) {
        if request.Method != http.MethodDelete {
            writer.WriteHeader(http.StatusMethodNotAllowed)
            return
        }
        data, _ := ioutil.ReadAll(request.Body)
        log.Printf("data: %v", string(data))
        writer.WriteHeader(http.StatusOK)
        writer.Write([]byte("This is DELETE Method"))
        writer.Write(data)
    })
    http.HandleFunc("/api/head", func(writer http.ResponseWriter, request *http.Request) {
        if request.Method != http.MethodHead {
            writer.WriteHeader(http.StatusMethodNotAllowed)
            return
        }
        data, _ := ioutil.ReadAll(request.Body)
        log.Printf("data: %v", string(data))
        writer.WriteHeader(http.StatusOK)
        writer.Write([]byte("This is HEAD Method"))
        writer.Write(data)
    })

    http.ListenAndServe(":1234", nil)
}
```

## 场景介绍

- 使用 301 场景 (一般是资源位置永久更改)
 
1) 更换换域名. 

2) 升级 https, HTTP -> HTTPS


- 使用 302 场景 (一般是普通的重定向需求: 临时跳转)

1) 未登录前使用302重定向到登录页面, 登录成功再跳回原来请求的页面

2) 自动刷新页面. 比如5秒后返回订单详细页面之类

3) 微博之类的使用短域名,用户浏览后重定向到真实的地址之类.

http://t.cn/RuUMBnI -> miaopai.com 302 

http://t.cn/RuOcwxn -> video.weibo.com 301 -> miaopai.com 302

4) pc端与移动端的域名转换

https://www.taobao.com/ -> m.taobao.com 302


## 20x 介绍

- 200 ok

请求成功. 成功的含义取决于HTTP方法:

GET: 资源已被提取并在消息正文中传输.
HEAD: 实体标头位于消息正文中.
POST: 描述动作结果的资源在消息体中传输.
TRACE: 消息正文包含服务器收到的请求消息.

- 201 Created

该请求已成功, 并因此创建了一个新的资源. 这通常是在POST请求, 或是某些PUT请求之后返回的响应.


- 202 Accepted

请求已经接收到, 但还未响应, 没有结果. 意味着不会有一个异步的响应去表明当前请求的结果, 预期另外的进程和服务去处理请求, 
或者批处理.