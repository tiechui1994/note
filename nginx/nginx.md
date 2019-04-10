# nginx代理配置

使用nginx服务器做代理服务器.

## Frontend 服务器

```
server {
    listen 80;
    listen [::]:80;

    server_name example.com;
    root /var/www/example/public;
	
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src * data: 'unsafe-eval' 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
}
```


## PHP 服务器

```
server {
    listen 80;
    listen [::]:80;

    server_name example.com;
    root /var/www/example/public;
	
    location / {
        try_files $uri $uri/ /index.html;
    }
	
    location ~ \.php$ {
        # 404
        try_files $fastcgi_script_name =404;
        
        # default fastcgi_params
        include fastcgi_params;
        
        # fastcgi settings
        fastcgi_pass			unix:/var/run/php/php7-fpm.sock;
        fastcgi_index			index.php;
        fastcgi_buffers			8 16k;
        fastcgi_buffer_size		32k;
        
        # fastcgi params
        fastcgi_param DOCUMENT_ROOT		$realpath_root;
        fastcgi_param SCRIPT_FILENAME	$realpath_root$fastcgi_script_name;
        fastcgi_param PHP_ADMIN_VALUE	"open_basedir=$base/:/usr/lib/php/:/tmp/";
    }
    
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src * data: 'unsafe-eval' 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
}
```


## Python 服务器

```
server {
    listen 80;
    listen [::]:80;

    server_name example.com;
    root /var/www/example/public;
	
    location / {
		# default uwsgi_params
        include uwsgi_params;
        
        # uwsgi settings
        uwsgi_pass						unix:/tmp/uwsgi.sock;
        uwsgi_param Host				$host;
        uwsgi_param X-Real-IP			$remote_addr;
        uwsgi_param X-Forwarded-For		$proxy_add_x_forwarded_for;
        uwsgi_param X-Forwarded-Proto	$http_x_forwarded_proto;
    }
    
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src * data: 'unsafe-eval' 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

```


## NodeJS | Golang | C | C++ 服务器

```
server {
    listen 80;
    listen [::]:80;

    server_name example.com;
    root /var/www/example/public;
	
    location / {
		proxy_pass http://127.0.0.1:3000;
    }
    
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src * data: 'unsafe-eval' 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
}
```
