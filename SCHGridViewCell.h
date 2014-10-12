//
//  SCHGridViewCell.h
//  数米基金宝HD
//
//  Created by 晨豪 沈 on 12-9-14.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DeleteButton;
@protocol SCHGridViewCellDelegate <NSObject>

/*删除的代理*/
- (void)deleteGridCell:(DeleteButton *)delete_button_sender;

/*编辑状态*/

- (void)gridDidEnterMoveMode:(id)sender withLocation:(CGPoint) point moveGestureRecognizer:(UILongPressGestureRecognizer *)gestureRecognizer;  /*进入移动状态*/

- (void)gridDidEndMoved:(id)sender withLocation:(CGPoint) point moveGestureRecognizer:(UILongPressGestureRecognizer *)gestureRecognizer;  /*结束移动*/

- (void)gridDidMoved:(id)sender withLocation:(CGPoint) point moveGestureRecognizer:(UILongPressGestureRecognizer *)gestureRecognizer;    /*移动中*/

/*是否点击了*/
- (void)gridTouch:(id)sender;
@end


@interface SCHGridViewCell : UIView<UIGestureRecognizerDelegate>
{
    /*删除按键*/
    DeleteButton                *_delete_button;
    
    id<SCHGridViewCellDelegate>  _delegate;
    
    /*view 所在的位置*/
    CGRect                       _view_location_rect;
    CGPoint                      _view_center_point;
    
    /*缩小的比例*/
    CGFloat                      _zoom_in_scale;
    
    /*放大的比例*/
    CGFloat                      _zoom_out_scale;
    
}

@property (nonatomic,retain) IBOutlet DeleteButton                *delete_button;

@property (nonatomic,retain)          id<SCHGridViewCellDelegate>  delegate;

@property (nonatomic)                 CGRect                       view_location_rect;
@property (nonatomic)                 CGPoint                      view_center_point;
@property (nonatomic)                 CGFloat                      zoom_in_scale;
@property (nonatomic)                 CGFloat                      zoom_out_scale;





@end
