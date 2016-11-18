---
layout: post
title: "Binary search與Obj-C"
date: 2016-11-18 16:41:19 +0800
comments: true
categories: 
---

## Binary search概念
Binary search概念其實很簡單，recursive版本實際寫起來很像[Quick sort in-place](http://sah.tw/blog/2016/11/09/objc-quick-sort/)版本前面divide的味道。每次的遞迴都把排序後的數列對切一半然後去其中一半來繼續處理，詳細可以看[Wiki](https://zh.wikipedia.org/wiki/二分搜索算法)的介紹。

## Binary search概念轉換成Code
```
/**
 * @return Retrun index of number in array.
 * If number not found in array return false.
 */
- (NSNumber *)binarySearchIndexInArray:(NSArray <NSNumber *>*)array forNumber:(NSNumber *)number leftRange:(NSInteger)left rightRange:(NSInteger)right {
    
    if (left > right) {
        return [NSNumber numberWithBool:false];
    }
    
    NSInteger midIndex = (left+right)/2;
    NSNumber* mid = array[midIndex];
    
    if (number.floatValue > mid.floatValue) { // 對切的右邊
        return [self binarySearchIndexInArray:array forNumber:number leftRange:midIndex+1 rightRange:right];
    }else if (number.floatValue < mid.floatValue){ // 對切的左邊
        return [self binarySearchIndexInArray:array forNumber:number leftRange:left rightRange:midIndex-1];
    }else{ // equal，找到了
        return  [NSNumber numberWithInteger:midIndex];
    }
}
```

## 關於搜尋
這個搜尋法的前提是你的數列要幾經排序好了。這個前置條件才讓我發現我之前一直以為搜尋是有什麼神奇的方法，能夠在一個大數列裡面找到target的位置，現在接觸演算法就理解現實運作方法是先排序之後再用方法搜尋的。