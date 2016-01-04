---
layout: post
title: iOS 以Serial思維執行背景任務
date: '2016-01-04 15:00:00 +0800'
comments: true
categories: 良工巧匠集
---

很多時候操作網路或者Disk的I/O，我們都會把工作丟到背景去執行，避免凍結使用者的畫面。但是這造成一個問題是一下子太多背景任務同時執行有可能導致APP崩潰。

比如影音APP使用者見獵心喜，一下子選了許多部影片要下載，如果現在把下載任務一股腦兒丟到背景，因為現在大部分下載需求都直接使用知名框架`AFNetworking`，而裡面的方法通常也都直接在背景運行，造成這些下載任務用Concurrent的方式併發執行，這下子產生大量的網路還有Disk I/O Request同時在背景跑。

UI是不會被凍結沒錯，但很有可能背景操作網路或Disk I/O的量太多（通常是Disk），導致APP崩潰。

這時候就非常建議一次下載並儲存一部影片就好。也就是確保上個任務執行完畢，Queue在推送下一個任務去執行。

##混亂的完成順序

直觀的實作方式就是建立一個Serial Queue，把需要列隊執行的任務用`dispatch_async`加入進去，就像以下方法：

```Objective-C
// 建立一個唯一的Serial Queue
dispatch_queue_t _uploadToParseInBackgroundQueue() {
    static dispatch_once_t queueCreationGuard;
    static dispatch_queue_t queue;
    dispatch_once(&queueCreationGuard, ^{
        queue = dispatch_queue_create("com.shih.secureMedia.uploadToParseInBackgroundQueue", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

// 包含一個異步方法的Method
(void)addTaskUploadMovie(NSDate *)movie
dispatch_async(_uploadToParseInBackgroundQueue(), ^{

    NSLog(@"%@上傳Start.......",movie.name);
    // 某個很花時間，但本身已經是丟到背景處理的方法
    [self uploadMovieInBackground:movie withCompleteBlock:^(BOOL succeeded, NSError * _Nullable error) {
        NSLog(@"%@上傳Done",movie.name);
    }];
});
```

實際執行：

```Objective-C
[self addTaskUploadMovie:a];
[self addTaskUploadMovie:b];
[self addTaskUploadMovie:c];
[self addTaskUploadMovie:d];
```

這裡有個大問題是uploadMovieInBackground本身已經是跑在背景，所以四個上傳任務實際上在後台是以併發Concurrent/Parallel的方式執行。

而多個高I/0負載任務被同時執行就有可能造成APP崩潰。

已Serial Queue的角度來看，你只可以控制任務執行的順序，但不能決定任務完成的順序，也就不能讓任務按照Serial的思維去執行，失去用Serial Queue的初衷。

實際執行結果不可預測，但大概會像這樣：

```
a上傳Start.......
b上傳Start.......
a上傳Done
c上傳Start.......
c上傳Done
d上傳Start.......
d上傳Done
b上傳Done
```

##可控制的完成順序  

而如果你希望上傳程序按照以下Serial的邏輯去跑:

```
a上傳Start.......
a上傳Done
b上傳Start.......
b上傳Done
c上傳Start.......
c上傳Done
d上傳Start.......
d上傳Done
```

###加入`dispatch_resume`與`dispatch_suspend`

加入這兩個操控Queue的方法就是做兩個目的：     
- 當某個在Serial Queue的上傳任務Block被執行的時候，此任務在Block內馬上呼叫Queue的Suspend方法，來暫停這個Queue繼續執行下個上傳任務   
- 而當前上傳任務執行完成之後，在該任務的call back block裡面馬上呼叫Queue的Resume，來讓下個上傳任務被執行。

反覆上述行為就達到我們要的一次在背景做一件事情的效果了。

```Objective-C
(void)addTaskUploadMovie(NSDate *)movie
dispatch_async(_uploadToParseInBackgroundQueue(), ^{

    NSLog(@"%@上傳Start.......",movie.name);
    // 某個很花時間，但本身已經是丟到背景處理的metod
    [self uploadMovieInBackground:movie withCompleteBlock:^(BOOL succeeded, NSError * _Nullable error) {
        NSLog(@"%@上傳Done",movie.name);

        // 這個Task執行完了，讓Queue resume，讓排在下一個的Task可以被執行
        dispatch_resume(_uploadToParseInBackgroundQueue());
    }];

    // 上面的uploadMovieInBackground開始後，就暫停這個Queue，不再執行Task(外部依然可以隨時用dispatch_async Passing Task)
    dispatch_suspend(_uploadToParseInBackgroundQueue());
});
```

[dispatch_resume與dispatch_suspend的官方參考文件](https://developer.apple.com/library/ios/documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationQueues/OperationQueues.html#//apple_ref/doc/uid/TP40008091-CH102-SW14)
