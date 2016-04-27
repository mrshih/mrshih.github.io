---
layout: post
title: iOS Camera Design Pattern 回顧
date: '2016-2-05 15:00:00 +0800'
comments: true
categories: 記錄集
---

##主題：要刪除某張照片?
	- Beat Practice 應該要由Model做發起去通知資料已變化。比如刪除照片： 
		1.	由某個UIButton觸發Model的Delete方法
		2.	Model做處理，處理完之後去通知相關連的ViewModel去更新（Notification）
		3.	ViewModel收到needUpdate通知，去Fetch並整理資料，最後通知View Reload
未完...
