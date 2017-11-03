//
//  doYZTopScrollView.m
//  SlideView
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "doYZTopScrollView.h"
#import "doDefines.h"

//按钮空隙
//#define BUTTONGAP 5
#define VIEWGAP 5
//滑条宽度
#define CONTENTSIZEX 320
//按钮id
#define BUTTONID (sender.tag)
//滑动id
#define BUTTONSELECTEDID (scrollViewSelectedChannelID - 100)

@implementation doYZTopScrollView
{
    NSMutableArray *_subViewArray;
}

@synthesize nameArray;
@synthesize scrollViewSelectedChannelID;
@synthesize isAutoWidth;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = self;
        self.backgroundColor = [UIColor clearColor];
        self.pagingEnabled = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.scrollsToTop = NO;
        self.buttonWithArray = [NSMutableArray array];
        _subViewArray = [NSMutableArray array];
    }
    return self;
}
//重写set方法
- (void)setSubViewArray:(NSArray *)subViewArray
{
    _subViewArray = [NSMutableArray arrayWithArray:subViewArray];
    int viewHeight = 44;
    int viewWidth = 0;
    int currentX = 0;
    CGFloat currentY = 0;
    NSMutableArray *array = [NSMutableArray array];
    for (int index = 0; index < subViewArray.count; index ++) {
        UIView *subView = subViewArray[index];
        viewWidth = CGRectGetWidth(subView.frame);
        viewHeight = CGRectGetHeight(subView.frame);
        CGFloat X = CGRectGetMinX(subView.frame);
        currentY = CGRectGetMinY(subView.frame);
//由模板决定
//        if (viewHeight > CGRectGetHeight(self.frame)) {
//            viewHeight = CGRectGetHeight(self.frame);
//        }
        //原模板外加一个父view，防止redraw之后位置变回模板的默认值，如{0，0}
        UIView *superView = [UIView new];
        
        currentX += X;
        CGRect r = CGRectMake(currentX, currentY, viewWidth, viewHeight);
        superView.frame = r;

        [superView addSubview:subView];
        currentX += viewWidth;

        [array addObject:superView];
    }
    if (self.isAutoWidth) {
        [self autoSize:currentX];
    }
    self.contentSize = CGSizeMake(currentX,viewHeight);
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self addSubview:(UIView *)obj];
    }];
}

- (void)autoSize:(CGFloat)xPos
{
    CGRect r = self.frame;
    r.size.width = fmin(xPos, DEVICE_WIDTH);
    self.frame = r;
    r = self.superview.frame;
    r.size.width = fmin(xPos, DEVICE_WIDTH);
    self.superview.frame = r;
}

- (void)adjustScrollViewContentX:(UIView *)sender :(BOOL)isAnimation
{
    CGPoint center = sender.superview.center;
    CGFloat offsetX = self.contentOffset.x;
    CGFloat halfW = self.frame.size.width/2;
    CGFloat xdisplay = center.x - offsetX ;

    if (xdisplay == halfW) {
        return;
    }else if (xdisplay > halfW){
        CGFloat w =self.contentSize.width - offsetX-CGRectGetWidth(self.frame);
        if (w<=0) {
            return;
        }
        if (w<(xdisplay - halfW)) {
            [self setContentOffset:CGPointMake(self.contentSize.width - CGRectGetWidth(self.frame), 0)  animated:isAnimation];
            return;
        }
    }else{
        if (self.contentOffset.x<(halfW-xdisplay)) {
            [self setContentOffset:CGPointMake(0, 0)  animated:isAnimation];
            return;
        }
    }
        
    [self setContentOffset:CGPointMake(self.contentOffset.x+(xdisplay-halfW), 0)  animated:isAnimation];
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.count==1) {
        UITouch *touch = touches.anyObject;
        CGPoint touchPoint = [touch locationInView:self];
        
        for (UIView *v in _subViewArray) {
            if (CGRectContainsPoint(v.superview.frame, touchPoint)) {
                if (_subViewArray.count>0) {
                    [self adjustScrollViewContentX:v :YES];
                    NSInteger index = [_subViewArray indexOfObject:v];
                    if ([self.yzDelegate respondsToSelector:@selector(didTapSubView:)]) {
                        [self.yzDelegate performSelector:@selector(didTapSubView:) withObject:@(index)];
                    }
                }
                break;
            }
        }
    }
}


@end