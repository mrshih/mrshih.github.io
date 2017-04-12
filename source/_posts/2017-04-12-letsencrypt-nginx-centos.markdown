---
layout: post
title: "letsencrypt在nginx與centos環境下實作tips"
date: 2017-04-12 14:20:09 +0800
comments: true
categories: 
---

基本上我認為現在[HTTPS](https://lynn1205.wordpress.com/2017/01/18/什麼是伺服器憑證ssl/)的功用只是用來加密連線，在CA亂發或誤發的時代，不能指望CA這樣的盈利民間機構能盡責的做到驗證申請者的角色。
但然而能做到加密Server與Clint之間的通訊內容其實也就已經足夠了。

與其繳錢給盈利CA，現在你有更好的選擇-[letsencrypt](https://letsencrypt.org)，免費開源自動化更新的CA。

網路上的教學文章不少，而我這邊整理幾個好用的tip，主旨在於自動化與降低維運的難度。

##Step0. CentOS+Nginx
因為自己的Server是用這樣的環境，加上這個環境也非常普遍可靠穩定，所以本文章就以這個環境當做基底。

##Step1. Nginx強制指定/.well-known/acme-challenge/檔案路徑

```
/etc/nginx/nginx.conf

server {
	listen       80;
	
	location ^~ /.well-known/acme-challenge/ {
		default_type	"text/plain";
		root	/var/www/letsencrypt;
	}
}
```
你必須向letsencrypt證明DNS指向的這台server是你host的，等等letsencrypt會去你domain下的`/.well-known/acme-challenge/`path查找文件，如果找得到就能證明是你host，也才能簽發證書給你。

而這裡統一指向`/var/www/letsencrypt`是因為有可能你現在用單純的html環境，有可能之後換成`proxy_pass`反向代理到node.js等，這都會使得`/.well-known/acme-challenge/`這個url路徑指向的檔案在你host的server上產生變動，這種業務上變動跟HTTPS是無關且可以切開來降低兩邊的耦合度，而隨著日後的domain變多，統一指定路徑這樣的做法也能夠降低後續維運的難度。

##Step2. 申請憑證
去下載官方的驗證tool [certbot](https://certbot.eff.org)並安裝，下面例子自行把abc代換成你的domain
```
certbot certonly --webroot -w /var/www/letsencrypt/ -d abc.com.tw -d www.abc.com.tw
```
成功的話會出現包含Congratulations!一大段話，憑證會被存在`/etc/letsencrypt/live/abc下`。

##Step3. 安裝憑證到Nginx
/etc/nginx/conf.d/abc.conf

```
listen       443 ssl;
server_name  www.abc.com.tw;

ssl_certificate      /etc/letsencrypt/live/abc/fullchain.pem;
ssl_certificate_key  /etc/letsencrypt/live/abc/privkey.pem;
```

##Step4. 強制導流HTTP連線到HTTPS
/etc/nginx/nginx.conf

```
server {
	listen 80;
	server_name _;
	return 301 https://$host$request_uri;
}
```

##Step5. 把更新任務加入crontab自動化更新憑證
以下為更新腳本，我是命名為renewCerts.sh，並存放在/etc/letsencrypt/下

```
#!/bin/sh
# This script renews all the Let's Encrypt certificates with a validity < 30 days

if ! /usr/bin/certbot renew > /var/log/letsencrypt/renew.log 2>&1 ; then
    echo Automated renewal failed:
    cat /var/log/letsencrypt/renew.log
    exit 1
fi
nginx -t && nginx -s reload
```

##Step6. 把sh加入crobtab

打開crontab設定檔

```
sudo crontab -e
```

加入sh設定每日自動執行然後儲存

```
@daily sh /etc/letsencrypt/renewCerts.sh
```