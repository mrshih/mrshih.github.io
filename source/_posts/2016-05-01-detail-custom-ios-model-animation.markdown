---
layout: post
title: "有關製作iOS客製化Animation的詳細過程"
date: 2016-05-01 03:05:19 +0800
comments: true
categories: 巧匠集
---

##為何寫這篇
前幾篇有寫到如何[製作SlideMenu](http://mrshih.github.io/blog/2016/01/08/first-presentation-flow/)，大概講了cocoa framework在客製化`UIView`動畫的世界觀，這裡則寫一個手把手的詳細步驟，這樣搭配比較有感覺，不然Apple把class之間解構的這麼徹底，實在是東一個西一個的，一時之間不好下手。

##手把手開始

0.建segue並且設立id  
1.segue kind選custom  
2.建立subclass(UIStoryboardSegue)  
3.override perform function  

>how to override perform function  

1.取得self.sourceViewController  
2.取得self.destinationViewController  
3.set destVC 的setModalPresentationStyle = UIModalPresentationCustom//顯示面積客製化  
4.誰提供客製化的資訊呢？在這裡！ 建立一格subclass UIViewControllerTransitioningDelegate class(裡面怎麼實作請看段A)  
5.set第四步的步驟為destVC的TransitioningDelegate  
6.srcVC presentViewController destVC，動畫animated設置為YES  

##段A  

>hwo to create a subclass `UIViewControllerTransitioningDelegate` 的object。  
>
>這裡就是實作perform跟dismiss的時候動畫要怎麼走的地方，還有系統要`UIPresentationController`的地方，簡單來說就是系統從這邊獲取怎麼客製化顯示範圍與顯示動畫的資訊。

* 1.提供override下面方法

```
- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source{

1.透過if ([presented isKindOfClass:AlbumMenuViewController class])來分別要提供對應PresentationController{
2.建立一個subclass UIPresentationController的class。(怎麼建請看段B)
3.透過UIPresentationController的父方法initWithPresentedViewController...(略)去instance這個PresentationController object。
}

}
```

* 2.override下面方法來提供prestedVC顯示時的動畫物件animator(從哪裡移動到哪裡，所以其實最後prestedVC的x,y是由這裡提供的動畫物件決定)  

```
- (id<UIViewControllerAnimatedTransitioning> _Nullable)animationControllerForPresentedController:(UIViewController * _Nonnull)presented presentingController:(UIViewController * _Nonnull)presenting sourceController:(UIViewController * _Nonnull)source{

1.用if去知道你等等要回傳那個對應的animator
if([presented isKindOfClass:[HelperTableViewController class]]){
2.SlideMenuAnimator *animator = [[SlideMenuAnimator alloc]init];//製作一個實作UIViewControllerAnimatedTransitioning協議的animator class，怎麼做看段C
3.[animator setPresenting:YES];// 我設計的animator可以同時包含出場與離場的動畫，這樣就不用寫兩個animator了，所以裡面有個參數可以選擇要回傳哪種動畫，這裡是出場就設定YES。
}

}
```

* 3.override下面方法來提供prestedVC dismiss時的動畫，功能如上，決定哪裡到哪裡

```
- (id<UIViewControllerAnimatedTransitioning> _Nullable)animationControllerForDismissedController:(UIViewController * _Nonnull)dismissed{
1.用if去知道你等等要回傳那個對應的animator
if([presented isKindOfClass:[HelperTableViewController class]]){
2.SlideMenuAnimator *animator = [[SlideMenuAnimator alloc]init];//前面解釋過
3.[animator setPresenting:NO];//前面解釋過
}
}
```

##段B 

* 1.override - `frameOfPresentedViewInContainerView`這個方法來指定prestenVC要顯示的"大小"，注意不包含位置(x,y)喔

```
(CGRect)frameOfPresentedViewInContainerView
{
CGRect presentedViewFrame = CGRectZero;//我們要回傳的數值
CGRect containerBounds = [[self containerView] bounds];//得到prestingVC的bounds
// 到這裡你已經可以運加減乘除算出你要顯示的VC的大小，下面示範的是要根據ipad跟iphone做特別處理的做法

if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
presentedViewFrame.size = CGSizeMake(floorf(containerBounds.size.width * 0.75),
containerBounds.size.height);
}else if(self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad){
presentedViewFrame.size = CGSizeMake(floorf(300),
containerBounds.size.height);
}

return presentedViewFrame;//最後當然是回傳
}
```

>補充：  
>除了override上面的方法去指定顯示大小外，你還可以override一些方法動態的去新增或拿掉view，比如切換VC時，prested如果沒有蓋滿presting，則剩下的地方可以放上一層黑色半透明的view來做區別。  
>下面是範例:  

* 2.新增`property @property (nonatomic) UIView *dimmingView;`  
* 3.複寫下面兩個方法，一個是當要切換時做什麼，另一個是當要隱藏時做什麼。搭配起來就可以動態新增刪除陰影view

```
- (void)presentationTransitionWillBegin {

self.dimmingView = [[UIView alloc]init];
[self.dimmingView setFrame:self.containerView.frame];
[self.dimmingView setBackgroundColor:[UIColor blackColor]];
[self.dimmingView setAlpha:0.3f];

// Add a custom dimming view behind the presented view controller's view
[[self containerView] addSubview:self.dimmingView];
[self.dimmingView addSubview:[[self presentedViewController] view]];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
UITapGestureRecognizer *dimmingViewSingleTap =
[[UITapGestureRecognizer alloc] initWithTarget:self.presentingViewController
action:@selector(handleDimmingViewSingleTap)];
#pragma clang diagnostic pop
[self.dimmingView addGestureRecognizer:dimmingViewSingleTap];

// Fade in the dimming view during the transition.
[self.dimmingView setAlpha:0.0];
// Use the transition coordinator to set up the animations.
[[[self presentingViewController] transitionCoordinator] animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
[self.dimmingView setAlpha:0.55];
} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {

}];
}
```
>在dismiss做一些額外coustom的事情，在這裡用讓dimmingView淡出來當例子

```
- (void)dismissalTransitionWillBegin {
[[[self presentingViewController] transitionCoordinator] animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
[self.dimmingView setAlpha:0.0];
} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {

}];
}
```

## 段C  

* 4.override下面方法，可以拿來改變一些基於class size變化的改變。 

```
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator 

//製作實作UIViewControllerAnimatedTransitioning協議的animator，系統會去這裡要VC的初始位置跟Final位置，系統再去補齊動畫。
//1 override 下面function來提供動畫內容（兩個位置）
- (void)animateTransition:(id<UIViewControllerContextTransitioning> _Nonnull)transitionContext {
1.// 主畫布
UIView *containerView = [transitionContext containerView];

2.// 對進場來說（toVC是prestedVC），拿到後可以再去拿VC的view
UIViewController *toVC   = [transitionContext
viewControllerForKey:UITransitionContextToViewControllerKey];

3.// 對進場來說（fromVC是prestingVC)，拿到後可以再去拿VC的view
UIViewController *fromVC = [transitionContext
viewControllerForKey:UITransitionContextFromViewControllerKey];

4.//取得view，後面動畫主要就是都在操作這裡
UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];

5.//取得兩個VC的最終大小，大小是在frameOfPresentedViewInContainerView決定。
// Set up some variables for the animation.
CGRect containerFrame = containerView.frame;
CGRect toViewStartFrame = [transitionContext initialFrameForViewController:toVC];
CGRect fromViewStartFrame = [transitionContext initialFrameForViewController:fromVC];
CGRect toViewFinalFrame = [transitionContext finalFrameForViewController:toVC];
CGRect fromViewFinalFrame = [transitionContext finalFrameForViewController:fromVC];

6.// 開始作畫 Add toVC's view to containerView
// 把toView加進來
[containerView addSubview:toView];

7.//決定一開始的frame
if (self.presenting) {
//這邊直接用預設的
CGSize size = toViewFinalFrame.size;
[toView setFrame:CGRectMake(0, containerFrame.size.height+toViewFinalFrame.size.height, size.width, size.height)];//size一樣。x=0,y=總高度+toView的高
}

//決定最終的frame
if (self.presenting) {
[UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
//大小一樣。位置就只要到x=0, y=總高度-toView高度
CGSize size = toViewFinalFrame.size;
CGPoint point = CGPointMake(0, containerFrame.size.height-toViewFinalFrame.size.height);
[toView setFrame:CGRectMake(point.x, point.y, size.width, size.height)];
}completion:^(BOOL finished) {
// 3.Cleaning up and completing the transition.
[transitionContext completeTransition:YES];
}];
}
}
```

5.override來提供動畫時間

```
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning> _Nullable)transitionContext {
return 0.2f;
}
```