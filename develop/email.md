# CloudFlare Email

CloudFlare 自定义域名邮箱 API. 即通过 CloudFlare 的 Worker 去发送自定义域名的邮件.

首先, 你需要有一个自己的域名, 并放到 CloudFlare 上进行脱管, 接下来是搭建邮件发送的 API Server.

### SPF

SPF 是一种 DNS 记录, 有助于防止电子邮件欺骗. 需要向你的域名添加 SPF 记录, 以允许 MailChannels 发送电子邮件.

1) 添加 TXT 记录到您的域:

```
- name: "@"
- value: "v=spf1 a mx include:relay.mailchannels.net ~all"
```

2) 添加 TXT 记录到您的域:

```
- name: "_mailchannels"
- value: "v=mc1 cfid=NAME.workers.dev" 
```

> 其中的 NAME 在 CloudFlare 首页进入 `Workers & Pages` 页面的右下方 `Subdomain` 当中可以找到. 
> 注: 该记录值可以是多行, 每一行的格式是 `v=mc1 cfid=xxx`. 其中的域名限定了请求 API 使用的域名, 如果只是使用 
> worker 提供的 `xxx.workers.dev` 域名发送邮件, 则 TXT 记录的值只是一行. 如想为 worker 添加自定义域名, 则需要
> 再增加自定义域名的值

### DKIM

DKIM 是有助于防止电子邮件欺骗的 DNS 记录.

1) 使用 openssl 生成私钥

```
openssl genrsa 2048 | tee priv_key.pem | openssl rsa -outform der | openssl base64 -A > priv_key.txt
```

其中 priv_key.txt 当中保存了私钥内容, 后续会使用到.

2) 获取公钥内容

```
echo -n "v=DKIM1;p=" > pub_key_record.txt && \
openssl rsa -in priv_key.pem -pubout -outform der | openssl base64 -A >> pub_key_record.txt
```

其中 pub_key_record.txt 当中的内容是后续 TXT 记录的值.

3) 向域添加 TXT 记录

```
- name: "noreply._domainkey"
- value: pub_key_record.txt 文件的内容
```

注: 到此为止, DKIM 记录已经添加完毕, 需要记住一组数据的值, 后续要使用

```
dkim_selector="noreply"
dkim_domain=你添加TXT记录的域名
dkim_private_key=priv_key.txt内容
```

### worker

在 CloudFlare 首页 `Workers & Pages` 的页面当中添加新的 worker. worker 的内容如下:

```JavaScript
export default {
    async fetch(request, env) {
        if (request.method !== 'POST') {
            return new Response('Method not supported', {status: 405})
        }
    
        const body = await request.json()
        const email_body = {
            personalizations: [{
                to: [{
                    "email": "xxx@gmail.com"
                }],
                dkim_domain: $dkim_domain,
                dkim_selector: $dkim_selector,
                dkim_private_key: $dkim_private_key,
            }],
            from: {
                'email':'noreply@yourdomian'
            },
            subject: "hello subject",
            content: [{
                "type":"text/plain",
                "value": "hello world"
            }, {
                "type": "text/html",
                "value": "<h1> hello world </h1"
            }],
        }
    
        const email_request = new Request('https://api.mailchannels.net/tx/v1/send', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(email_body),
        })
    
        const res = await fetch(email_request)
        return new Response(`${res.status} ${res.statusText}`, {status: res.status})
    }
}
```

> 上述就是发送邮件 API 的测试, 可以根据需要进行完善. 这里就使用了前面 dkim_xxx 相关的参数.
> 关于 `https://api.mailchannels.net/tx/v1/send` API 的文档地址 "https://api.mailchannels.net/tx/v1/documentation"

### worker 自定义域名

转到已经添加的 worker 页面, 里面有个 `triggers` Tab 页面, 里面就包含了 Custom Domains, 可以将自己的域名添加进
去, 这样就可以使用自己的域名(默认是使用 worker 自带的域名)去请求API

### 小结

上述就是关于 CloudFlare 自定义域名邮箱的全部内容.
