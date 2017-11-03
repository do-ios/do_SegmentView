//
//  doYZTopScrollView.h
//  SlideView
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol doYZTopScrollViewDelegate <NSObject>
@optional
-(void)didTapSubView:(NSNumber *)currentIndex;
@end

@interface doYZTopScrollView : UIScrollView <UIScrollViewDelegate>
{
    NSArray *nameArray;
    NSInteger userSelectedChannelID;        //点击按钮选择名字ID
    NSInteger scrollViewSelectedChannelID;  //滑动列表选择名字ID
    
    UIImageView *shadowImageView;   //选中阴影
}
@property (nonatomic, retain) NSArray *nameArray;
@property (nonatomic,strong) NSArray *subViewArray;
@property(nonatomic,retain)NSMutableArray *buttonWithArray;

@property (nonatomic, assign) NSInteger scrollViewSelectedChannelID;

@property (nonatomic,weak) id <doYZTopScrollViewDelegate> yzDelegate;

@property (nonatomic,assign) BOOL isAutoWidth;

- (void)adjustScrollViewContentX:(UIView *)sender :(BOOL)isAnimation;

@end
