//
//  SCHGridViewCell.m
//  数米基金宝HD
//
//  Created by 晨豪 沈 on 12-9-14.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SCHGridViewCell.h"
#import "DeleteButton.h"
#import <QuartzCore/QuartzCore.h>
@interface SCHGridViewCell ()

- (void)pressDeleteButton:(id)sender;

/*长按*/
- (void)pressedLong:(UILongPressGestureRecognizer *)gestureRecognizer;

/*点击*/
- (void)handleSingleTap:(UITapGestureRecognizer *)gestureRecognizer;

@end

@implementation SCHGridViewCell

@synthesize delete_button      = _delete_button; 
@synthesize delegate           = _delegate;
@synthesize view_center_point  = _view_center_point;

@synthesize view_location_rect = _view_location_rect;

@synthesize zoom_in_scale      = _zoom_in_scale;
@synthesize zoom_out_scale     = _zoom_out_scale;

#pragma mark - 
#pragma mark - 长按
- (void) pressedLong:(UILongPressGestureRecognizer *) gestureRecognizer
{
   
    CGPoint point;
    switch (gestureRecognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            point = [gestureRecognizer locationInView:self];
            [_delegate gridDidEnterMoveMode:self withLocation:point moveGestureRecognizer:gestureRecognizer];
            //放大这个item
           // NSLog(@"press long began");
            break;
        case UIGestureRecognizerStateEnded:
            point = [gestureRecognizer locationInView:self];
            [_delegate gridDidEndMoved:self withLocation:point moveGestureRecognizer:gestureRecognizer];
            //变回原来大小
            //NSLog(@"press long ended");
           
            break;
        case UIGestureRecognizerStateFailed:
            //NSLog(@"press long failed");

            break;
        case UIGestureRecognizerStateCancelled:
    
            point = [gestureRecognizer locationInView:self];
            [_delegate gridDidEndMoved:self withLocation:point moveGestureRecognizer:gestureRecognizer];
            break;
        case UIGestureRecognizerStateChanged:
            //移动
            point = [gestureRecognizer locationInView:self];
            [_delegate gridDidMoved:self withLocation:point moveGestureRecognizer:gestureRecognizer];
            //NSLog(@"press long changed");
            break;
        default:
            //NSLog(@"press long else");
            break;
    }
    
    //CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform"];
    
}


#pragma mark -
#pragma mark - 删除事件
- (void)pressDeleteButton:(id)sender;
{
    /*响应删除事件*/
    if([_delegate respondsToSelector:@selector(deleteGridCell:)])
        [_delegate deleteGridCell:(DeleteButton *)sender];
}

#pragma mark -
#pragma mark - 初始化
- (id)init
{
    self = [super init];
    
    if(self)
    {

        
    }
    
    return self;
}


- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if(nil != _delete_button)
    {
        _delete_button.grid_view_cell = self;
        _delete_button.hidden         = YES;
        /*增加 删除事件*/
        [_delete_button addTarget:self action:@selector(pressDeleteButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    /*增加长点击事件*/
    UILongPressGestureRecognizer *long_press = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(pressedLong:)];
    [self addGestureRecognizer:long_press];
    [long_press release],long_press = nil;
    
    /*增加单击事件*/
    UITapGestureRecognizer *single_tap = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(handleSingleTap:)] ;
    single_tap.numberOfTapsRequired    = 1;
    single_tap.cancelsTouchesInView    = NO;
    single_tap.numberOfTouchesRequired = 1;
    single_tap.delegate                = self;
    [self addGestureRecognizer: single_tap];
    [single_tap release], single_tap = nil;
    
    _zoom_out_scale = 1.2f;
    _zoom_in_scale  = 0.8f;
}



- (void)handleSingleTap:(UITapGestureRecognizer *)gestureRecognizer
{

    switch (gestureRecognizer.state)
    {
        case UIGestureRecognizerStateBegan:

            break;
        case UIGestureRecognizerStateEnded:

            /*点击结束*/
            [_delegate gridTouch:self];
            break;
        case UIGestureRecognizerStateFailed:
        
            break;
        case UIGestureRecognizerStateChanged:
 
            break;
        case UIGestureRecognizerStateCancelled:
          
            break;
        default:

            break;
    }
    
}

#pragma mark -
#pragma mark - UIGestureRecognizerDelegate 

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    // 过滤掉UIButton，也可以是其他类型
    if ( [touch.view isKindOfClass:[UIButton class]])
    {
        return NO;
    }
    
    return YES;
}



#pragma mark -
#pragma mark - dealloc 
- (void)dealloc
{
    [_delete_button release], _delete_button = nil;
    
    [super dealloc];
}


@end
