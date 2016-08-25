---
layout: post
title: "In-App-Purchase交易模組設計"
date: 2016-08-24 23:30:18 +0800
comments: true
categories: 
---

網路上很多介紹如何運用`StoreKit`裡面的API在iOS上付款的文章，但實務上因為`In-App-Purchase`是程式裡面需要密集配合業務需求的部分，如果沒有一個良好抽象化的設計，在高可維護性與彈性，可擴展能力下功夫，一旦業務需求一複雜或反覆迭代更改，就會讓IAP相關的邏輯變得難以修改與維護。

以上原因，所以如何在APP中設計一套可維護可擴展易整合的IAP架構，是開發大型APP與進階開發者應該關心的議題。接下來的文章把IAP付款架構有關執行交易與交易結果處理的這部分，抽象成TNStoreObserver類別。

##StoreObserver
付款流程是APP根據一組定義在iTunesConnect的商品ID，向Apple Server請求對應的`SKPayment`物件，裡面包含了Localization的商品名稱與價錢，把這個想成一個商品。而一旦把這個`SKPayment`物件放到由系統維護的`SKPaymentQueue`時，這時候就開始進入按指紋，輸入iTunes Store帳密的程序。

而`StoreKit`說明，當`SKPayment`加入到`SKPaymentQueue`後，開發者需要實作一個adopt`SKPaymentTransactionObserver`protocol的物件，並加入到`SKPaymentQueue`裡。之後這個Observer就是負責處理各種交易結果。比如成功時就要開啟對應的功能等。

所以這個Class就取名叫StoreObserver，職責是實作`SKPaymentTransactionObserver`protocol，處理交易完成的後續行為。並負責與`SKPaymentQueue`互動，比如購買，取回過去的購買紀錄。最後可方便的在任何地方發動購買，然後在需要的地方容易接收到結果。

基於以上需求，開去構思這個模組。

先處理交易的部分，這就是單純與StoreKit串接。以下兩個Public方法：

```
// 購買SKProduct
// Create and add a payment request to the payment queue
-(void)buy:(SKProduct *)product
{
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

// 取回過去完成交易的非消耗品購買與自動續訂紀錄
-(void)restore
{
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}
```

實作上會把這個`StoreObserver`做成`Singleton`，因為APP裡面可能會有許多頁面允許付款，只要`[[StoreObserver sharedInstance] buy:product];`就可以購買商品。然後因應上面的`restore`方法，這裡需要一個`NSArray`來裝取回的商品們，命名為`productsRestored`。

```
+ (StoreObserver *)sharedInstance
{
    static dispatch_once_t onceToken;
    static StoreObserver * storeObserverSharedInstance;
    
    dispatch_once(&onceToken, ^{
        storeObserverSharedInstance = [[StoreObserver alloc] init];
    });
    return storeObserverSharedInstance;
}


- (instancetype)init
{
	self = [super init];
	if (self != nil)
    {
        _productsRestored = [[NSMutableArray alloc] initWithCapacity:0];
    }
	return self;
}
```

這邊重要的來了，如果程式的某個地方呼叫了`StoreObserver`的`buy`發法，之後`StoreObserver`收到交易完成的資訊，而APP裡面可能會有很多地方因為這個交易而產生UI上的變化，比如買了一部影片，影片要開始播放，影片櫃需要新增新影片，會員的購買紀律需要增加一筆。該怎麼通知那麼多地方？這裡用了`NSNotificationCenter`。

為什麼呢？因為在上述一對多的狀況下，`StoreObserver`會被設計成它不關心那些畫面或地方需要這些訊息。但它會把資料準備好，接著廣播。

當通知的人不關心他會通知到誰，但可能需要被通知的人很多時，`NSNotificationCenter`機制就派上用場了。

```
NSString * const TNIAPPurchaseNotification = @"TNIAPPurchaseNotification";
```

再來是讓接收廣播的地方容易做處理。在這個Class裡面我們設置三個Property，`status`，`message`和`purchasedID`。當這個Class實作`SKPaymentTransactionObserver`時，根據收到的資訊做整理，讓接收的人可以很方便利用交易結果。

```
typedef NS_ENUM(NSInteger, TNIAPPurchaseNotificationStatus)
{
    TNIAPPurchaseFailed, // Indicate that the purchase was unsuccessful
    TNIAPPurchaseSucceeded, // Indicate that the purchase was successful
    TNIAPRestoredFailed, // Indicate that restore products was unsuccessful
    TNIAPRestoredSucceeded // Indicate that restore products was successful
};

@property (nonatomic) TNIAPPurchaseNotificationStatus status;
@property (nonatomic, copy) NSString *purchasedID;
@property (nonatomic, copy) NSString *message;
```

比如當我們實作的`SKPaymentTransactionObserver`方法被`SKPaymentQueue`呼叫時，整理一下再POST Notification出去

```
// Called when an error occur while restoring purchases. Notify the user about the error.
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    if (error.code != SKErrorPaymentCancelled)
    {
        self.status = IAPRestoredFailed;
        self.message = error.localizedDescription;
        [[NSNotificationCenter defaultCenter] postNotificationName:TNIAPPurchaseNotification object:self];
    }
}
```

##實際運作
這邊我們不考慮要怎麼取得到SKPayment物件，因為這部分邏輯不在`StoreObserver`負責範圍內。

###在任何地方容易的發動購買

```
SKProduct *product = (SKProduct *)productRequestResponse[indexPath.row];
        // Attempt to purchase the tapped product
        [[TNStoreObserver sharedInstance] buy:product];
```

###在需要的地方容易收到並做處理

```
[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePurchasesNotification:)
                                                 name:TNIAPPurchaseNotification
                                               object:[StoreObserver sharedInstance]];

// Update the UI according to the purchase request notification result
-(void)handlePurchasesNotification:(NSNotification *)notification
{
    StoreObserver *purchasesNotification = (StoreObserver *)notification.object;
    
    IAPPurchaseNotificationStatus status = (IAPPurchaseNotificationStatus)purchasesNotification.status;
    NSString *message = purchasesNotification.message;
    NSString *purchasedID = purchasesNotification.purchasedID;
   

	switch (status)
    {
        case IAPPurchaseFailed:
            //購買失敗...
        	break;
            
        case IAPDownloadSucceeded:
        {
            //購買成功...
        }
        	break;
        
        case IAPRestoredSucceeded:
        {
            //回復成功...
        }
            break;
            
        case IAPRestoredFailed:
            //回復失敗...
            break;
	} 
}
```