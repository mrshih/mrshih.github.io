---
layout: post
title: "iOS Model-View-ViewModel 實作"
date: 2015-07-02 16:30:05 +0800
comments: true
categories: 
---
##MVC架構遭遇困境
在iOS SDK的設計下開發者都會走向apple安排好的MVC架構，即便你不知道MVC但SDK早幫你切好view controller，很自然你也會走向類似架構。但隨著開發時間越長有幾個MVC框架問題越來越不可忽視。本文會先討論遇到的問題，並介紹最近我實作過覺得很棒的另一套架構MVVM，可以輕易讓程式碼彼此耦合降低，進而增加可維護性與易開發性，可以說是替代MVC更先進好用的架構。

在Model裡可能是Core data，也可能是sqlite，其中往往是提供幾個API回傳需要的資料，並且用NSArray等等簡單的包裝好後就丟給Controller去轉換成View需要的格式，在這裡Model的某些工作被丟給了Controller。

在View層就是xib，或是storyboard。用上面兩種起碼在排版上跟Controller分離，但如果沒有用Auto-layout就會需要設定freme，在這裡View該自己做的事丟給了Controller。還有一個狀況是透過IBAction直接在Controller裡面操作Model取得狀態，比如登入按鈕！這會讓登入邏輯落在許多不同地方，本身也增加了View跟登入功能細節的耦合，很明顯View不該接觸Model。

最大的問題是Controller負擔的工作實在太多，要從Model去轉換資料來更新管理的View，還要協調View與Model之間的互動，還有Loading狀態，各式各樣的Delegate與NSNotification，這引出了MVC的大問題

* 過於肥大的Controller，動輒數千行
* 無論如何View跟Controller會互相交錯，最後牽一髮動全身

##用MVVM架構優化
MVVM是從MVC基礎上改進而來，所以可以很容易從現有MVC去做改進，以下範例就可以看到整合進MVVM是非常容易的
把所有資料轉換的邏輯寫到View Model

下面是一個範例的Calendar model還有配合得View Controller

```
@interface Calendar : NSObject

- (instancetype)initwithToday:(NSDate *)today;

@property (nonatomic, readonly) NSString *month;
@property (nonatomic, readonly) NSString *day;
@property (nonatomic, readonly) NSString *year;
@property (nonatomic, readonly) NSDate 	*today;

@end
```
假設我們單純把Calendar裡面的日期印在cell上

```
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMdd";
	NSString *date = [[dateFormatter stringFromDate:today] capitalizedString];
	
	[cell.todayLabel date];
	
}
```
以上是標準MVC普遍寫法。現在看看MVVM如何改進。以下使一個CalendarViewModel
```
@interface CalendarViewModel : NSObject

- (instancetype)initWithCalendar:(Calendar *)calendar;
@property (nonatomic, readonly) Calendar *calendar;
@property (nonatomic, readonly) NSString *today;

@end
```
CalendarViewModel.m我們大致這樣實作
```
@implementation PersonViewModel

- (instancetype)initWithCalendar:(Calendar *)calendar
{
	self = [super init];
    if (!self) return nil;
    
    _calendar = calendar;
    
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMdd";
	NSString *date = [[dateFormatter stringFromDate:today] capitalizedString];
	
	return self;
}

@end
```
現在我們已經把資料轉換邏輯放到View Model裡面了，這時候我們table view controller就會非常輕量

```
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	[cell.todayLabel     setText:viewModel.today];
}
```
這樣一來並沒有改動太多架構，但透過我們把資料產生邏輯從Controller抽出來，獨立放到View Model，很明顯看到程式可維護性提高許多，整個架構耦合性降低更易於測試除錯修改。

##And then ...資料的更新與VIEW的刷新
整個流程是由ViewModel要發現source資料變化了，更新自己的property，接著通知Contorller根據ViewModel做更新UI的動作。這個通知學問就大了，可以有很多種方法。

很明顯我們可以只要修改ViewModel就指定Controller做刷新的動作，更大範圍來說這可以用KVO來時做追蹤View Model裡面的直有無變化來做畫面的更新。但這裡推薦最近發現的框架ReactiveCocoa，這個框架也是用來做數值追蹤，但本質上與之前的KVO, NSNotificationCenter都是截然不同的東西，我們在後續文章再來討論。
