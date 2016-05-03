---
layout: post
title: "iOS Fastlane打造快速TestFlight部署"
date: 2016-05-03 14:59:51 +0800
comments: true
categories: 
---

老生常談得一件事情，如果一個團隊花一個禮拜的時間寫好自動部署的工具，比如用shell，把平常又臭又長或者很繁瑣的指令集結起來，這後再做這些繁瑣重複工作的時間就可以省下來。

>表面上看起來或許一年之後你才能把剩下來的那幾秒鐘累積成一個禮拜，達成回本的動作，但是如果你不這樣做，你把那一個禮拜的時間打散到一年裡面，換來的就是你一年的開發效率都低落。
>
>長期下來，有沒有做瑣碎事情自動化的團隊之間的差距可謂天與地。

知道了自動化的重要性，首先我會先請你到官方文件那裡安裝必要的工具，之後我在介紹你tips，讓你可以快速達到自動部署上TestFlight的要求。當然你之後可以串接Test的流程，確認沒問題了再上TestFlight。

首先到[Fastlane](https://github.com/fastlane/fastlane)的GitHub上依照最新的`Installation`章節安裝好Fastlane。接著依照`Quick Start`章節的步驟建好初步的文件。

接著看到目錄裡面的Fastfile文件，下面文件已經是我改好可以Run的版本，跟初始化的版本會不太一樣，而下面我會介紹是怎麼改過來的，要知其然：

```
desc "Submit a new Beta Build to Apple TestFlight"
  desc "This will also make sure the profile is up to date"
  lane :beta do
    increment_build_number
    # match(type: "appstore") # more information: https://codesigning.guide
    gym(scheme: "SecureMedia", use_legacy_build_api: true) # Build your app - more options available
    pilot(team_name: "CUTE LIMITED")

    # sh "your_script.sh"
    # You can also use other beta testing services here (run `fastlane actions`)
  end
```

看到`lane :beta do`，代表之後我們只要下`fastlane beta`就可以指定執行一直到`end`包起來的這個區塊的動作。

我們先定義我們的beta要做什麼事情:  
1. 把cocoapod裝一次  
2. 把build號碼+1  
3. 用Production的Provisioning Profiles，build一個ipa出來  
4. 把這個版本送到TestFlight上，並送給tester  

基本上如果上述都手動的話，大約要花上15分鐘左右（切換Provisioning Profiles, 上傳時間, 還有等iTunes connect處理新版build, 最後再手動送出分發測試版本到tester手上），透過自動化工具可以做到打一行指令後就可以不理了。

上述流程在Fastlane裡面被寫成三行，這三行的設定tips就分三項介紹   

###increment_build_number

Literally，`increment_build_number `就是自動增加build版號，別小看這個功能，以前常常是都發布出去了才發現沒有新增版號！  

需要配合設定Xcode參數`Current Project Version`。參照圖片或[這邊](http://www.markschabacker.com/blog/2013/01/04/agvtool_with_new_projects/)。

![image](http://mrshih.github.io/images/ios-fastlane-1.png)

###gym

這是幫我們產生ipa檔案的。後面跟上兩個參數`scheme`通常就是你得App名稱，`use_legacy_build_api`，則是因為[Xcode 7.0的上傳API更改了，所以在使用時有時候會錯](https://github.com/fastlane/gym/issues/104)，這時候要改用舊的。  

###pilot

這是幫我們自動部署到TestFlight的，使用時需要加上`team_name`參數是因為筆者帳號下有兩個Team，你如果不填上這個Fastlane跑到一半就會問你，這樣自動化就沒意義了。

然後Xcode要配合在`info.plist`加上下面這個屬性：

```
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```
討論串是說iTunes connect建議手動上傳要使用這個參數。相關討論在這個[issue](https://github.com/fastlane/pilot/issues/156)頁。

##後記

之後可以串接上Slack做完成時的顯示，再更進一步可以搭配Hubot，這樣連`fastlane beta`都省了。然後因為沒接觸CI Server，之後也可以研究兩者如何搭配。

其實筆者在用octopress發布文章的時候，明明指令沒幾行也硬是寫了三個shell來發布(new, preview, publish)，但實在是幫我省了很多時間，不然每次我可都要去google指令，很煩的。

只能說工程師的懶沒有極限，但正是這種懶造就了人類文明的進步（？）。