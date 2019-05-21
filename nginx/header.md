# Security Header 配置

## Content-Security-Policy (内容安全策略)

内容安全策略(CSP)是一个额外的安全层, 用于`检测并削弱某些特定类型的攻击`, 包括跨站脚本(XSS)和数据注入攻击等.
无论是数据盗取, 网站内容污染还是散发恶意软件, 这些攻击都是主要的手段.

### 威胁

- 跨站脚本攻击

- 数据包嗅探攻击

### 使用 Content-Security-Policy