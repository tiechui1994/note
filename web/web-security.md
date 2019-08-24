# Web API 安全设计

## RESTful架构风格下的4大常见安全问题

- 遗漏了对资源从属关系的检查

- HTTP响应中缺失必要的 Security Headers

**X-Frame-Options**
为了防止应用遭受点击劫持攻击, 可以使用X-Frame-Options:DENY明确告知浏览器, 不要把当前HTTP响应中
的内容在HTML Frame中显示出来。

**X-Content-Type-Options**
在浏览器收到HTTP响应内容时, 它会尝试按照自己的规则去推断响应内容的类型, 并根据推断结果执行后续操作, 
而这可能造成安全问题. `例如，一个包含恶意JavaScript代码的HTTP响应内容, 虽然其Content-Type为image/png, 
但是浏览器推断出这是一段脚本并且会执行它.`

X-Content-Type-Options就是专门用来解决这个问题的Header. 通过将其设置为X-Content-Type-Options:nosniff,
浏览器将不再自作主张的推断HTTP响应内容的类型, 而是严格按照响应中Content-Type所指定的类型来解析响应内容.

**X-XSS-Protection**
避免应用出现跨站脚本漏洞(Cross-Site Scripting,简称XSS)的最佳办法是对输出数据进行正确的编码, 不过除此之外,
现如今的浏览器也自带了防御XSS的能力.

要开启浏览器的防XSS功能,只需要在HTTP响应中加上X-XSS-Protection:1;mode=block. 其中,数字1代表开启浏览
器的XSS防御功能，mode=block是告诉浏览器, 如果发现有XSS攻击, 则直接屏蔽掉当前即将渲染的内容.

**Strict-Transport-Security**
使用TLS可以保护数据在传输过程中的安全, 而在HTTP响应中添加上Strict-Transport-Security这个Header,可以告
知浏览器直接发起HTTPS请求, 而不再像往常那样, 先发送明文的HTTP请求, 得到服务器跳转指令后再发送后续的HTTPS请求.
并且, 一旦浏览器接收到这个Header, 那么当它发现数据传输通道不安全的时候, 它会直接拒绝进行任何的数据传输, 不再允
许用户继续通过不安全的传输通道传输数据, 以避免信息泄露.


- 不经意间泄露的业务信息

**会说话的ID**: 暴露业务能力

**返回多余的数据**: 敏感数据

- API缺乏速率限制的保护









