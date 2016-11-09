---
layout: post
title: MergeSort與Obj-C外加Category與OOP
date: 2016-11-07 00:18:53 +0800
comments: true
categories: 
---

## Merge Sort概念
跟我一樣原本不知道Merge Sort是什麼碗糕的可以去這個[影片](https://www.youtube.com/watch?v=mzjjRPdH9Jw)，這裡有可愛北一女的實際示範，中文的呦。如果英文好那我也是更推薦去看英文的，那資源又更多了。

## Merge Sort概念轉換成Code
在懂了Merge Sort概念之後，如果對於如何把想法轉換成程式碼沒什麼感覺，可以看一段[影片](https://www.youtube.com/watch?v=es2T6KY45cA&index=3&list=PL2aHrV9pFqNRS2b2XX2BvgQIPKh72xREP)，這段影片大概就是程式碼影片化後實際運作的樣子。

Merge Sort有分Recursive跟For loop兩種，但看完影片直覺就是用Recursive比較好做。這是因為你看Merge Sort其實是把一個大問題分成小問題，小問題再分成更小的問題，直到把問題切割成最小單元，再返回來把前一次的結果餵給上一層，之後一層一層的解回去。這是很典型的遞迴場景。
NSMutableArray
上面的問題解決思路在演算法裡面叫做Divide and Conquer，蠻傳神的解釋，把問題分解後在各個擊破。

## Objective-c Implement

* Input為一個NSArray，裡面包含N個NSNumber，NSNumber可以為Int或Flot。
* Output為一個把Input Array裡面的N個NSNumber由小排序到大的NSArray。

```
- (NSArray *)mergeSortWithData:(NSArray *)data {
    
    if (data.count == 1) {
        // div done here
        // 這裡已經把問題分解成最小單位了，所以就告一段落
        return data;
    }
    
    NSInteger divLength = data.count/2;
    NSArray *left = [data subarrayWithRange:NSMakeRange(0, divLength)];
    NSArray *rigth = [data subarrayWithRange:NSMakeRange(divLength, data.count-divLength)];
    
    NSArray<NSNumber*> *mergeArrayA = [self mergeSortWithData:left];
    NSArray<NSNumber*> *mergeArrayB = [self mergeSortWithData:rigth];
    
    NSInteger headOfMergeArrayA = 0;
    NSInteger headOfMergeArrayB = 0;
    
    NSMutableArray *resultArray = [[NSMutableArray alloc]initWithCapacity:mergeArrayA.count+mergeArrayB.count];
    
    Boolean control = true;
    while (control) {
        
        if (headOfMergeArrayA == mergeArrayA.count) {
            //MergeArrayA沒東西了
            //把剩餘的MergeArrayB直接append到resultArray後面
            [resultArray addObjectsFromArray:[mergeArrayB subarrayWithRange:NSMakeRange(headOfMergeArrayB, mergeArrayB.count-headOfMergeArrayB)]];
            control = false;
            break;
        }else if(headOfMergeArrayB == mergeArrayB.count){
            [resultArray addObjectsFromArray:[mergeArrayA subarrayWithRange:NSMakeRange(headOfMergeArrayA, mergeArrayA.count-headOfMergeArrayA)]];
            control = false;
            break;
        }
        
        if ([mergeArrayA[headOfMergeArrayA]floatValue] > [mergeArrayB[headOfMergeArrayB]floatValue]) {
            [resultArray addObject:mergeArrayB[headOfMergeArrayB]];
            headOfMergeArrayB = headOfMergeArrayB + 1;
        }else{
            [resultArray addObject:mergeArrayA[headOfMergeArrayA]];
            headOfMergeArrayA = headOfMergeArrayA + 1;
        }
    }
    
    return resultArray;
}
```

## Do more - Free Function與Method
可以看到`mergeSortWithData`是一個Function，但我自己Obj-C軟體實作的Coding style上如果一個Function的Input有指定要是某個Class，比如這裡就是指定`NSArray`，那這時候採用Method較好。

但通常很少情況會不指定Input的Clsas，所以實務上會盡量少用Free Function，附帶的好處是可以減少一堆Function散落在專案裡面，也可以盡量DRY（Don't repeat yourself）。

當然，不要過度強調DRY，因為這關係到切架構與抽象化整體的規劃能力，抽象的不好那是會用弄越糟的，但至少在這個簡單的Case裡Merge Sort做成Method絕對是make sense的。

這裡可以練習把Merge Sort用`Category`的方式做成`NSArray`的Method。基礎OOP，把一些地方改成`Self`就可以了。