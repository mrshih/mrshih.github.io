---
layout: post
title: iOS在不同ViewController指定Status Bar
date: '2015-12-10 01:36:49 +0800'
comments: true
categories: 良工巧匠集
---
查看文擋很容易發現viewController有個`preferredStatusBarStyle `接口，搭配語意明顯的`setNeedsStatusBarAppearanceUpdate`，看起來可以指定回調的`UIStatusBarStyle `比如白色與黑色。但時常調用了卻沒有回應。

這時候查一查文擋內相同Section附近的API會是個好習慣。在Managing the Status Bar裡發現下面這個接口：

```Objective-C
- (UIViewController *)childViewControllerForStatusBarStyle;
```

按照苹果官方的解释：

> If your container view controller derives its status bar style from one of its child view controllers, implement this method and return that child view controller. If you return nil or do not override this method, the status bar style for self is used. If the return value from this method changes, call the setNeedsStatusBarAppearanceUpdate method.

調用`setNeedsStatusBarAppearanceUpdate`時，系統默認會去調用application.rootViewController的`preferredStatusBarStyle`方法，所以這時候當前自己的viewController的`preferredStatusBarStyle`方法根本不會被調用。

這個接口很重要，這種情況下`childViewControllerForStatusBarStyle`就有用了。一般我們常用navigationController作為rootViewController，利用此接口便可以很方便自訂各個viewController的statusBarStyle。 子類化一個navigationController，並且override`childViewControllerForStatusBarStyle`

```Objective-C
- (UIViewController * _Nullable)childViewControllerForStatusBarStyle {
    return self.topViewController;
}
```

意思就是說不要調用我自己application.rootViewController（navigationController）的`preferredStatusBarStyle`方法，去調用｀childViewControllerForStatusBarStyle｀回傳的UIViewController的`preferredStatusBarStyle`。這裡回傳self.topViewController就可以保證當前顯示的viewController的`preferredStatusBarStyle`會被系統調用且正確的顯示。