---
layout: post
title: "Docker系列3 - Container間的溝通"
date: 2017-02-14 15:53:23 +0800
comments: true
categories: 
---

這系列文章從建立Container，建立Volume，至此我們已經可以去建立提供不同的服務Micro Service了，而剩下的議題變是如何讓Micro Service之間彼此溝通。

## 不同Host間的Containers彼此溝通

如果Micro Service在不同的實體機器中，則可以透過`run`指令裡的`-p`來把Container與Host的特定給對應起來。

比如以下指令就是啟動一個Web Container並且把Host的Port 3000與Container的Port 80給串連起來

```
docker run -p 3000:80 web
```

那接下來就可以在Host用127.0.0.1:3000來訪問Web Container的Port 80。

## 同Host間的Containers彼此溝通

而當Containers都在同一個Host，比如一個是Web一個是DB，Web要如何連上DB呢？其實每個Container在run的時候預設都是走bridge模式，這裡就是docker會創建一個veth interfaces，讓該host的Containers都跑在同一個network。

只要用`inspect`指令就可以查到該Container的詳細資訊，而裡面的Key`IPAddress`就會有IP資訊。

```
docker inspect [Container-ID]
```
在同個veth環境下，有了IP，Container之間就可以彼此溝通了。

## FYI
https://docs.docker.com/engine/reference/run/#/network-settings