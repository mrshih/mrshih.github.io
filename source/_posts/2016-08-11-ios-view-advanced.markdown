---
layout: post
title: "從零到穩固的基礎 - 談iOS刻畫UI"
date: 2016-08-11 22:02:46 +0800
comments: true
categories: 
---

MVVM是iOS開發近來熱門的開發架構，最近工作上不停用到這個架構去建立各種頁面，對於如何從零開始架構出一個方便開發與維護的MVVM架構有些實作上總結出的Tips或稱為想法在，這裡記錄下來與回顧。

系列第一篇會先從MVVM裡面的View開始講，通常這也是我開發的第一也是很重要的步驟，這裡一開始沒規劃好浪費的時間絕對是最多的，因為方向就錯了麻。

##看UI圖然後先想想

第一步當然就是看著UI出好的圖，然後想想這個畫面上會用的什麼`UIKit`的控件。大部分不外乎是`TableView`, `CollectionView`, `PageView`，互相搭配即可組出框架。某些例外比如登入登出註冊頁面則通常就會一張空白`View`自己拉畫面，不太用到上面提到的控件。

真的有問題比如需要重新打造一個控件，或不好實作，卡到時間等，都在這裡即時反應給UI是最好的。不會先做下去遇到問題卡住再來溝通，這樣事倍功半真的也很浪費時間。

##先大致上命名好

曾經有看過程式設計裡面在資深開發人員裡排名第一的難題是命名。這是因為如果一開始沒有想好階層式的命名方式，等到架構一大你就會開始需要在腦袋裡面Dump一堆記憶體來存這些Name的意義，久了也一定會忘記。

比如常見的新聞頁面

![YahooNews](http://sah.tw/images/2016-08-11-ios-view-advanced.png)

這個頁面大致需要下面幾個控件:

1. 主要`ViewController`
2. 一個`CollectionView`來當Indicator，顯示有那些類別
3. 一個`PageController`來橫向翻頁在不同類別的新聞頁面
4. 多個`TableView`拿來顯示新聞

那在命名上就要先大致想好：

1. `SHReaderViewController`
2. `SHReaderCategoryIndicatorViewController` - `SHReaderCategoryIndicatorCell`
3. `SHReaderPageViewController`
3. `SHReaderNewsViewController` - `SHReaderNewsCell`

只要名字的Prefix按照大方向一樣，階層想好定下來後，不管是要新增Coustom Class，或是要在`Storyboard`上標註對應的`Storyboard Identifier`都很方便，之後再開發與維護上會因為也脈絡可循的命名而容易許多。

##多使用StackView

在iOS9加入`StackView`之後，整個畫面裡面`Autolayout`所需要的`Constraints`大幅的減少很多，事實上官方也建議最好`Autolayout`任何畫面可以考慮直接用`StackView`開始。

`StackView`的強項在於可以定義一個母區塊，讓裡面的`SubView`能Depend在母區塊的邊界上設定`Constraints`與做`Autolayout`，同時也限制這裡面的`StackView`裡的`SubView`改動不會影響到`StackView`之外的其他`View`。

在沒有`StackView`之前只有一個`RootView`要給整個畫面上一堆`SubView`當做參照，這樣在設計`Autolayout`上往往牽一髮動全身，一個`SubView`的更改常常就會連帶影響一大推其他的`View`。

##用Storyboard Reference切割不同功能的畫面
比如`Tabbar`分出來的全部連到`Storyboard Reference`，或多次在不同地方會單獨`M	odel`出來的畫面要拆分出來。這樣一個團隊才可以同時協作開發多個頁面，解決了`Storyboard `一開始被大家詬病的`Git`協作問題。

##還有一些比較瑣碎的Tips

###適時用Xib搭配Storyboard
當我們有時候要自製一個小控件比如`Segment Control`，裡面的`Cell`便可以用xib。掌握住`initWithCoder`用來再`Storyboard`載入，比如：

```Objective-C
// If you are loading it from a nib file (or a storyboard), initWithCoder: will be used.
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self addSubview:[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] objectAtIndex:0]];
    }
    return self;
}
```

`initWithFrame`則是有時候不得已用Code的方式呼叫：

```Objective-C
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.autoresizesSubviews = YES;
    }
    return self;
}
```

並且記得如果用Code呼叫要`Frame`，要在`viewDidAppear`這裡面做，因為根據`ViewController`這裡才是`Frame`經過`Autolayout`等計算後真正確定的地方。

###利用SizeClass
比如轉向的需求，利用`Storyboard`的`SizeClass`在不同情境下就可以很輕易漂亮的適配出你要的螢幕Layout，比如影片橫幅要佔滿全螢幕等。

##Then...

其實在Xcode裡面刻畫環境真的是很享受的過程，當你刻畫出的UI在`Storyboard`上跟UI出的圖一樣時，那樣的成就感很高。尤其Apple近幾年推出的`Autolayout`跟`SizeClass`其實都走在很前端的地方，給開發者很大的彈性與方便。

這裡也推薦這個網站Zeplin，我現在配合的設計師可以很方便地更新圖給大家，上面尺寸也都可以標註到很細，甚至這個網站還有Mac的APP，裡面有個特異功能是可以把素材匯進到專案的`Assets.xcassets`真的很棒！


