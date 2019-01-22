# 跨域解决方案

跨域通信的解决手段大致分为两类:

- 一类是Hack. 比如通过 `title`, `navigation` 等对象传递信息. JSONP可以说是最优秀的Hack.
- 另一类是HTML5支持. 一个是 `Access-Control-Allow-Origin` 响应头，一个是 `window.postMessage`

## 设置 document.domain

- 原理: 相同主域名不同子域名下的页面, 可以设置 `document.domain` 让它们同域

- 限制: 同域 document 提供的是 `页面间的互操作`, 需要载入iframe页面.

- 案例:

下面几个域名的页面都是可以通过 `document.domain` 跨域操作的: `http://a.com/foo, http://b.a.com/bar, 
http://c.a.com/bar`. 但只能以页面嵌套的方式进行页面互操作, 比如常见的 `iframe` 方式完成页面的嵌套.

```js
// URL http://a.com/foo
let ifr = document.createElement('iframe');
ifr.src = 'http://b.a.com/bar'; 
ifr.onload = function(){
    let ifrdoc = ifr.contentDocument || ifr.contentWindow.document;
    ifrdoc.getElementById("foo").innerHTML;
};

ifr.style.display = 'none';
document.body.appendChild(ifr);
```

注意: 上述代码所在的URL是http://a.com/foo, 它对http://b.a.com/bar的DOM访问要求后者将 document.domain 
往上设置一级, 代码如下:

```js
// URL http://b.a.com/bar
document.domain = 'a.com'
```

注: `document.domain` 只能从子域设置到主域, 往下设置以及往其他域名设置都是不允许的.

## 具有 src 属性的标签

- 原理: 所有具有 `src` 属性的HTML标签都是可以跨域的, 包括 `<image>`, `<script>`.

- 限制: 需要创建一个DOM对象, 只能用于GET方法.

在 `document.body` 中 `append` 一个具有 `src` 属性的HTML标签, `src` 属性值指向的
URL会以GET方法被访问, 该访问是可以跨域的.

注: 其实样式表的 `<link>` 标签也是可以跨域的, 只要有 `src或href` 的HTML标签都有跨域的能力.

不同的HTML标签发送HTTP请求的时机不同. `<img>` 在更改 `src` 属性时就会发送请求, 而 `<script>, 
<iframe>, <link rel=stylesheet>` 只有在添加到DOM树之后才发送HTTP请求:

```jquery
let img = new Image();
img.src = "http://some/picture";　// 发送HTTP请求

let frame = $('iframe', {src:'http://some/picture'});
$('body').append(frame);          // 发送HTTP请求
```

## JSONP

- 原理: `<script>` 是可以跨域的, 而且在跨域脚本中可以直接回调当前脚本函数.

- 限制: 需要创建一个DOM对象并且添加到DOM树, 只能用于GET方法.

JSONP利用的是 `<script>` 可以跨域的特性, 跨域URL返回的脚本不仅包含数据, 还包含一个回调:

```js
// URL: http://b.a.com/foo

let data = {
    foo: 'foo',
    bar: 'bar'
};
callback(data);
```

注: 该例子只用于示例, 实际情况应当 `考虑名称隐藏等` 问题.

然后, 在主站 `http://a.com` 中, 可以这样来获取 `http://b.a.com` 的数据:

```jquery
// URL: http://a.com/foo

let callback = function(data) {
  // 处理跨域请求得到的数据
};

let script = $('script', {src: 'http://b.a.com/bar'});
$('body').append(script);
```

其实jQuery已经封装了JSONP的使用:

```jquery
$.getJSON('http://b.a.com/bar?callback=callback', function(data) {
    // 处理跨域请求得到的数据
}
```

注: `$.getJSON` 与 `$.get` 的区别是前者会把 `responseText` 转换为 JSON, 而且当
URL具有 `callback` 参数时, jQuery将会把它解释为一个 JSONP 请求, 创建 一个 `<script>`
标签来完成该请求.

## window.postMessage

- 原理: HTML5 允许窗口之间发送消息

- 限制: 浏览器需要支持 HTML5, 获取窗口句柄后才能互相通讯.

`postMessage(message, targetOrigin)` 是HTML5 引入的特性. 可以给任何一个 window 发送
消息, 不论是否同源. 第二个参数可以是 `*`, 但如果你设置了一个URL,但不相符, 那么该事件不会被分
发.

```js
// URL: http://a.com/foo
let win = window.open('http://b.com/bar');
win.postMessage('Hello, bar!', "http://b.com"); 
```

```js
// URL: http://b.com/bar
window.addEventListener('message',function(event) {
    console.log(event.data);
});
```

## Access-Control-Allow-Origin

参考: [cors](./cors.md)

## nginx代理跨域

- 原理: 同源策略是浏览器的安全策略, 不是HTTP协议的一部分. 服务端调用HTTP接口只是使用了HTTP协议. 不会
执行JS脚本, 不需要同源策略, 也就不存在跨域问题.

- 限制: 配置比较麻烦

- 思路: 前端页面的域名是frontend, api的域名是backend. 通过nginx配置一个代理服务器(域名与backend相同,
但是端口号不同)做跳板机, 反向代理访问frontend接口, 并且可以修改cookie中的domain信息, 方便前端cookie的
写入.

案例实现:
```
server {
    listen      81;
    server_name www.backend.com;
    
    location / {
        proxy_pass    http://www.backend.com:80; # 反向代理
        proxy_cookie  www.backend.com www.frontend.com; # 修改cookie里的域名
        index index.html, index.htm;
        
        add_header Access-Control-Allow-Origin http://www.backend.com;
        add_header Access-Control-Allow-Credentials true;
    }
}
```