---
layout: post
title: 推播結合背景更新 - 良好的使用者體驗
date: '2015-12-22 20:36:49 +0800'
comments: true
categories: 良工巧匠集
---

試想一個情境是相簿APP在後台收到伺服器傳來愛人分享的最新照片，但使用者興沖沖的打開之後面對轉阿轉不停的Loading indicator圓圈圈，多麼令人掃興。 動通知但被動下載資料顯然不是一個好方法。

這個時候可以透過推播通知APP，並在背景讓程式預載相片，載好之後再通知使用者點開APP，立即可以看到所有相片，多棒的使用者體驗。

要不打擾到使用者偷偷通知手機要實作`Silent Notification`，很簡單，只要把`title`,`body`,`sound`全部留空就好，但通常我們的APP都在後台，甚至沒有被載入到記憶體，這時候要啟用背景更新，做法就是額外在APNS Payload 加上`content-available=1`，並且在Xcode的Capabilities->Background Modes->Remotes Notification這裡把選項打勾。

這時候在手機收到有`content-available=1`的推播，而且APP有enabled the remote notifications background mode的情況下，APP不管在前台或後台甚至沒被Lunch過，都會被喚醒並呼叫到下面這個方法：

```Objective-C
- (void)application:(UIApplication * _Nonnull)application didReceiveRemoteNotification:(NSDictionary * _Nonnull)userInfo fetchCompletionHandler:(void (^ _Nonnull)(UIBackgroundFetchResult result))handler {

  // 下載資料...

  // Local Notification提示使用者下載好囉
  UILocalNotification *locNotification = [[UILocalNotification alloc] init];
    locNotification.alertBody = @"Data have arrived!";
    [[UIApplication sharedApplication]presentLocalNotificationNow:locNotification];

  //回調系統下載好了
  handler(UIBackgroundFetchResultNewData);
}
```

> ...the system launches your app (or wakes it from the suspended state) and puts it in the background state when a remote notification arrives. However, the system does not automatically launch your app if the user has force-quit it. In that situation, the user must relaunch your app or restart the device before the system attempts to launch your app automatically again......

> As soon as you finish processing the notification, you must call the block in the handler parameter or your app will be terminated. Your app has up to 30 seconds of wall-clock time to process the notification and call the specified completion handler block....

官方文件說有例外，就是使用者曾經手動殺掉過這個APP，奇怪的是在我的開發經驗裡面，就算使用者手動殺掉系統在收到推播之後還是會去喚醒這個APP。

然後系統大約會給你30的時間讓你去下載需要的資料到記憶體或硬碟，之後就必須要call handler`UIBackgroundFetchResult`告訴系統已經載入完畢。

如果成功下載了我們要的資料，就可以發一個LocalNotification來通知使用者來享用你剛下載好的檔案，一打開就有下載好的內容，多棒的使用者體驗啊。
