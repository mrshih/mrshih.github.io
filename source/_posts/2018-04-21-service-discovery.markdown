---
layout: post
title: "微服務架構Service Discovery篇"
date: 2018-04-21 15:07:48 +0800
comments: true
categories: 
---

![2018-04-21-service-discovery](http://mrshih.github.io/images/2018-04-21-service-discovery.png)

想像一下來到一個陌生國度，你既沒有地圖也不會說當地語言，你不知道要買生活用品要去哪家店，你也不知道餓了哪裡有餐廳可以吃飯，什麼事情也不能做。

沒錯，一個沒有Service Discovery機制的微服務架構就如上面的情境，什麼事情都做不了，可以說Service Discovery機制是談微服務架構必備的基礎設施也不為過。



### 為什麼要Service Discovery?

簡而言之，一個微服務架構底下可能有數十到數萬個微服務，彼此之間是解耦合的，不會留存各自的組態資訊，所以需要一個熟門熟路的總機，要找誰、需要什麼問它就對了。

它要解決以下情境：

1. 一個服務請求(如HTTP Post)進來
   a. 有沒有微服務可以支援這個請求？
   b. 有的話，只有一個嗎？如果有多個我要請誰來執行呢？
2. 一個微服務上線
   1. 我該如何讓別人知道我這個微服務能做什麼？
   2. 如果微服務不正常或下線了，要怎麼讓別人知道？

###如何解決情境問題？

而為了以上情境問題，一個Service Discovery透過實現以下兩個邏輯層來解決問題

#### Query

要**維護**一份可用服務的清單。可以想像成一個數位電話簿，可以回答這件事情**現在**誰可以做。

不過這裡先留的伏筆，注意剛剛提到的兩個字眼**維護**與**現在**。這兩個字眼代表現在的清單比需要知道當下所有微服務的狀態，有沒有服務其實已經掛掉了？這部分是由另一個邏輯層**Registry**所負責，等等會提到。

Query這裡具體實現可以用資料庫的方式來實現清單的保存。一般來說單一MySQL就已足夠應付數千同時查詢請求，透過實體橫向 Read Scale來擴展。如再進一步有效能方面要求，可引入Cache機制，但狀態一致性就會增加空窗時間，這時候就是與業務需求之間的Trade off了。

而如果有多個微服務可提供要Pass給哪一個呢？簡單做法就是Round-robin，所以Service Discovery也會有Load balance的角色存在。

#### Registry

這裏就是用來維護當前裝態了。大致上會有Registry與Unregistry。

Registry時以Docker來說，就是紀錄Container IP與 ID等資訊。還有這個Container能夠提供那些接口API Path可使用。

Unregistry則就是把這個服務標示為無效，讓查詢時不要把這個Service也列入可用名單內做挑選。

###誰像誰註冊(Registry)？

實際在實現註冊功能時會遇到一個問題，是Service Discovery主動對新服務做註冊，還是新服務來主動對Sercice Discovery做註冊。

Service Discovery主動對新服務做註冊有以下優點
1. 讓Container對Service的存在一無所知，解偶。
2. 服務之需要當被動元件。之需要專心對Request產生Response。


但缺點就是

1. Service Discovery負擔已經繁重，還需要做掉其實可以由Container來負責的主動註冊這個動作。
2. 因為每個Container啟動有快有慢，所以所有Container需要等待統一秒數才能被註冊，比如7秒。這也意味著不能有低於7秒的，而對Container做啟動優惠7秒也沒有太大意義。

而新服務來主動對Sercice Discovery做註冊，把上面反過來看就是了。根據我的經驗，`新服務來主動對Sercice Discovery做註冊`以長期來看，會是一個較好管理彈性也較高的做法。

### 如何知道服務狀態是否正常？

這裡大致上分主動與被動做法：

主動作法如既然已經有一份清單，就可以定期對每個服務發送健康狀態檢查的請求，粗略的可以是Ping，而如果對於Container掌控度較大，則可以協調出一個專門的API接口來進行狀態檢查。

被動做法則是當選出一個服務並對其呼叫，如果沒有回應則**標示此服務為下線並報修**，同時在找從其餘可用服務中挑一個，以此類推一直到沒有服務可用為止。

兩種做法各有優缺點，Service-Discovery責任已經很重，要定期對眾多微服務做定期檢查責任略顯吃重，如要採用主動建議切出一個獨立邏輯的服務運行，主動優點當然就是發現故障服務的時間會迅速許多，尤其當微服務增多時更明顯，不會有服務已經掛掉卻躲在那裡。

被動已是可用的方案，而主動則算是好還可以再更好的方案。長期而言應在架構上選擇主動方式。

### Server-side Discover與Clint-side Discovery

Service Discovery這個主題還有分Server-side Discover(ssd)y與Clint-side Discovery(csd)。不過絕大多數方案如k8s都採行ssd作法，而我認為csd只是做了一半的ssd，實在也沒有什麼非用不可的應用情境，所以就沒多做介紹，想了解可參考附錄。

### 結論

只要談到微服務架構就必定會談到Service Discovery，這算是整個架構的核心基礎設施了，在上面幾個Section大致上把幾個實作時會考慮的問題談過一輪，看下來會發現在註冊Registry那一塊，Service與微服務不管採行什麼做法都是需要有幾個共同溝通的API來合作，而對外查詢方面則須考慮效能問題，長期規劃也會有架構設計上的考慮，而上面所說也全都要建立在業務需求上來做最後設計決策。而業務需求會一直變，架構上也就會一直演進。

所以全面了解Service Discovery的眉角可以更好的去支持業務需求。

### 附錄

[安德魯的部落格-微服務基礎建設 - Service Discovery](http://columns.chicken-house.net/2017/12/31/microservice9-servicediscovery/)

[Day 4 Service discovery 和 Service registry](https://ithelp.ithome.com.tw/articles/10193407)

[模式: 客户端服务发现](http://microservices.io/patterns/cn/client-side-discovery.html)