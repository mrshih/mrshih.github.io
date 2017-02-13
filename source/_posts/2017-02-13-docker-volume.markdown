---
layout: post
title: "Docker 運用Volume達成資料分離"
date: 2017-02-13 14:23:05 +0800
comments: true
categories: 
---
##為什麼要用volume？
Docker的Container有個重要的原則是不儲存資料。為什麼呢？比如你做一個Web Service的Image，你把NPM,前端分流Nginx等軟體都安裝好了，這時候要把網頁的檔案放進去，一種做法是在`Dockerfile`裡面用`COPY`把網頁檔給複製進Image裡面，然後再Run起來。

可是這種把`資料`存在Image裡的做法會帶來許多問題，我如果改一行Code我不就要重新Build或新Commit一個Image嗎？我如果有好多個網站要跑在不同的Container上，我不就要做好多個Image？如果是DB的Image，把`資料`放在Image裡面，那不就隨著時間過去Image就要一直更新了?

所以在製作Image上，常見的best practice是把執行環境打包成Image，而時常會修改的檔案比如網頁檔案或資料庫檔案這些`資料`就與Image分開，放在外掛上去的volume，與Image分離。這樣就可解決上面所提及的問題。

底下我們就以網頁服務常見的/var/www資料夾與資料庫常見的/var/lib/mysql為例，說明怎麼把這兩個存`資料`的地方給另外存在volume上。

##製作data volume container

```
docker create -v absolute/path/to/host/dir:/var/lib/mysql --name dbdata mysql   //產生一個container, 掛載host資料夾(absolute/path/to/host/dir)到container的/var/lib/mysql
```
這裡的-v用法就是用來掛載volume的，去mount一個host資料夾為container的data volume。並且把這個container指名為dbdata，這種container又稱作為`data volume container`。

這種container特別在於本身只是用來記載那個host資料夾對應mount到container的那個資料夾，所以container本身是不用啟動(run)的。

PS. 如果Host的dir沒有指定，則docker會在系統的某個陰暗角落建立一個新的資料夾。可以用`docker inspect container-id`指令回傳結果裡key`Mounts`的Dictionary裡找到那個陰暗角落。

##使用data volume container
有了data volume container後，只要以後在run container時透過`--volumes-from`參數，就可以直接把指定的`data volume container`的volume給掛載進來。

```
docker run --name=mysqldb -d -p 3306:3306 --volumes-from= dbdata mysql
```
這時候新產生名為mysqldb的container，cd到`/var/lib/mysql`就會發現與host的`absolute/path/to/host/dir`資料夾是連動的，也就是mount再一起了。

舉個實用情境，假如資料庫版本要升級，只要在`Dockerfile`裡面升級資料庫版本，然後把新的container啟動時掛載dbdata，資料就還是一樣。而如果當初沒有把`資料`從Image分離出來，是要不原本DB的資料給匯出，再匯入新Image，非常麻煩，而不這麼做DB的紀錄就消失不見囉。

這裡的效果也就是[官方介紹](https://docs.docker.com/engine/tutorials/dockervolumes/)的volume主要用途，把`資料`與container分開，達到data persistence的目的。

`Data volumes are designed to persist data, independent of the container’s life cycle.`

##同理可證的Web Service
一但建構好基本環境，比如NPM, PM2, Nginx...etc，打包成一個Image後創建Container，以後Run這個Container只要搭配以下參數，就可以在本地修改，然後在container裡面實際測試了。

```
-v absolute/path/to/host/web/dir/project:/var/www/project
```
比如以下指令就是啟動一個已經安裝所需運行環境的image（npm-ready），然後指定Host資料夾（/Users/shih/Desktop/lab/PSControlCenter）掛載到Container的/var/www上。

```
docker run -i -t --name center -p 9453:3001 -v /Users/shih/Desktop/lab/PSControlCenter:/var/www npm-ready
```

##FYI

* https://docs.docker.com/engine/tutorials/dockervolumes/
* https://jiajially.gitbooks.io/dockerguide/content/chapter_fastlearn/docker_run/data_manager.html
