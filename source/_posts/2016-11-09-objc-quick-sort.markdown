---
layout: post
title: QuickSort與Obj-C
date: 2016-11-09 10:24:20 +0800
comments: true
categories: 
---

## Qucik Sort概念
第一次看到快速排序的許多介紹，可能第一時間腦袋轉不太過來，因為網路介紹常常把虛擬碼翻成步驟，直接敘述，所以腦袋普通像我就會沒辦法意會為什麼要做這個動作。比如後面會提到的In-Place版本交換這個動作就常常不知為何而做。這裡有個[影片](https://www.youtube.com/watch?v=aQiWF4E8flQ)是從很高層次想法上去解釋Quick Sort，個人看了之後再想想虛擬碼，也就豁然開朗了。

## Qucik Sort概念轉換成Code

```
- (NSArray *)quickSortUseExtraMemoryWithData:(NSArray *)data {

    if (data.count <= 1) { // 到底部了, 不需要排序, 直接回傳
        return data;
    }
    
    int random = arc4random() % data.count;  // 隨機取用某index當pivot，避免比如排序已經排好的陣列，每次都取index0，會造成時間複雜度O(N^2)，worst case
    NSNumber *pivot = data[random];
    
    NSMutableArray *less = [[NSMutableArray alloc]init];
    NSMutableArray *greater = [[NSMutableArray alloc]init];
    
    for (int i=1; i<=data.count-1; i++ ) {
        if ([(NSNumber *)data[i]floatValue] >= [pivot floatValue]) {
            [greater addObject:data[i]];
        }else {
            [less addObject:data[i]];
        }
    }
    
    NSMutableArray *result = [[NSMutableArray alloc]init];
    [result addObjectsFromArray:[self quickSortUseExtraMemoryWithData:less]];
    [result addObject:pivot];
    [result addObjectsFromArray:[self quickSortUseExtraMemoryWithData:greater]];
    
    return result;
}
```

如果常寫有支援記憶體管理語言比如Java或ARC版Obj-C的人可能會直覺寫出這個版本，因為在這幾個語言裡其實常常不用太管記憶體使用量太多這個問題，除非是`UIImage`等大型物件沒有釋放，不然常常遇到比如`NSArray`分割其實也就是再開兩個NSArray去存就好了。

上面這個實作方法每次都新開`NSArray`去存放分割後的子Array，而Quick Sort比Merge Sort好的地方在於它可以改用稱作In-Place的方法，只在同一個陣列做交換，可以避免運用消耗多餘的記憶體空間，參考文獻也寫說實務上也可以增加演算法的效率。

## Qucik Sort In-Place 版本
```
- (NSMutableArray *)quickSortInPlaceWithData:(NSMutableArray <NSNumber *>*)data leftIndex:(NSInteger)left rightIndex:(NSInteger)right{
    // 使用in-place法，操作同一個陣列，避免額外消耗多餘記憶體，硬體限制嚴格的環境下使用
    
    if (left > right) { // 底部。代表上一層遞迴切出來，這個sub-array已經只有一個元素，就不用排列了，'這個元素也會是已經就定位的'。
        return nil;
    }
    
    NSNumber *pivot = data[right];
    
    NSInteger processIndexAKAWall = left;
    [data exchangeObjectAtIndex:right withObjectAtIndex:right];// 把pivot移到最後面
    for (int i=(int)left; i<right; i++ ) { // left ... right-1
        if ([data[i]floatValue] < [pivot floatValue]) {
            [data exchangeObjectAtIndex:processIndexAKAWall withObjectAtIndex:i];// 擺到牆的右邊
            processIndexAKAWall = processIndexAKAWall + 1;// 牆往前
        }
    }
    [data exchangeObjectAtIndex:processIndexAKAWall withObjectAtIndex:right];// 把pivot移到牆的右邊。這個pivot目前已經在正確的index上了。
    
    // 切兩段
    // start by left, end by processIndexAKAWall - 1
    // start by processIndexAKAWall + 1, end by right
    [self quickSortInPlaceWithData:data leftIndex:left rightIndex:processIndexAKAWall - 1];
    [self quickSortInPlaceWithData:data leftIndex:processIndexAKAWall + 1 rightIndex:right];
    
    return data;
}
```
## 更好用的呼叫方式
平均空間複雜度更好的In-Place版本，因為只有`NSMutableArray`可以交換item，所以如果傳入值是是`NSArray`則呼叫的時候要寫成以下方式：
```
NSMutableArray *result = [self quickSortInPlaceWithData:[data mutableCopy] leftIndex:0 rightIndex:data.count-1];
```
而為了可以讓`NSArray`可以使用，也方便之後做成`NSArray`的`Category`，就可以改寫成以下這種較為方便別人使用的方式，因為別人不一定知道Left與Right，也不需要懂實作細節情況下：
```
- (NSArray *)quickSort:(NSArray *)data {
    return [self quickSortInPlaceWithData:[data mutableCopy]  leftIndex:0 rightIndex:data.count-1];
}
```