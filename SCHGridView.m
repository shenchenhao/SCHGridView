//
//  SCHGridView.m
//  数米基金宝HD
//
//  Created by 晨豪 沈 on 12-9-14.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SCHGridView.h"
#import <QuartzCore/QuartzCore.h>
#import "DeleteButton.h"
#import "SCHAnimationGroup.h"

static int remove_count     = 0; //正在移除的个数

static int all_remove_count = 0; //全部移除的个数


@interface SCHGridView ()

/*清除*/
- (void)clean;

/*加载*/
- (void)load;

/*显示存在的tabel view */

- (void)showGridView;

- (void)showGridViewDefault;     //默认显示
- (void)showGridViewDivergence; //发散显示

/*设置 尺寸*/
- (void)setScrollViewSize;


/*拖动的 重新排列位置*/

- (void)changGridPointAtIndex:(NSInteger)index moveGridPointAtIndext:(NSInteger)move_index;

- (void)moveLineGridPointStartAtIndex:(NSInteger)start_index endAtIndex:(NSInteger)end_index;  //默认的线性的移动
- (void)moveWaveGridPointStartAtIndex:(NSInteger)start_index endAtIndex:(NSInteger)end_index isInsertAfter:(BOOL)is_after;  //波浪的移动
- (void)moveJumpUpGridPointStartAtIndex:(NSInteger)start_index endAtIndex:(NSInteger)end_index isInsertAfter:(BOOL)is_after; //上跳跃
- (void)moveJumpDownGridPointStartAtIndex:(NSInteger)start_index endAtIndex:(NSInteger)end_index isInsertAfter:(BOOL)is_after; //下跳跃

/*插入的 重新排列位置*/
- (void)insertLineGridPointStartAtIndex:(NSInteger)start_index endAtIndex:(NSInteger)end_index insertIndexArray:(NSArray *) index_array;  //默认的线性的移动
- (void)insertWaveGridPointStartAtIndex:(NSInteger)start_index endAtIndex:(NSInteger)end_index insertIndexArray:(NSArray *) index_array;  //波浪的移动
- (void)insertJumpUpGridPointStartAtIndex:(NSInteger)start_index endAtIndex:(NSInteger)end_index insertIndexArray:(NSArray *) index_array; //上跳跃
- (void)insertJumpDownGridPointStartAtIndex:(NSInteger)start_index endAtIndex:(NSInteger)end_index insertIndexArray:(NSArray *)index_array; //下跳跃

/*显示 插入的 位置*/

- (void)showInsertGridView:(NSArray *)index_array;
- (void)showInsertGridViewDefault:(NSArray *)index_array;
- (void)showInsertGridViewLight:(NSArray *)index_array;
- (void)showInsertGridViewDrop:(NSArray *)index_array;



/*删除 对应的图标*/
- (void)removeGridAtIndex:(NSInteger)index;

- (void)removeGridDefaultAtIndex:(NSInteger)index;
- (void)removeGridLightAtIndex:(NSInteger)index;

/*删除全部图片的方式*/
- (void)removeAllGridDefault;
- (void)removeAllGridPaths;

/*进入编辑状态*/ 
- (void)editMode:(NSInteger)index;

/*进入正常模式*/
- (void)normalMode;
@end

@implementation SCHGridView
@synthesize grid_data_source      = _grid_data_source;
@synthesize grid_delegate         = _grid_delegate;

@synthesize grid_layout_style     = _grid_layout_style;
@synthesize grid_show_style       = _grid_show_style;
@synthesize grid_move_style       = _grid_move_style;
@synthesize grid_insert_style     = _grid_insert_style;
@synthesize grid_delete_style     = _grid_delete_style;
@synthesize grid_delete_all_style = _grid_delete_all_style;

@synthesize is_edit               = _is_edit;


#pragma mark - 
#pragma makr - 删除所有的格子

- (void)deleteAllGridCell
{
    if([_grid_delegate respondsToSelector:@selector(gridViewBeginDelete:)])
        [_grid_delegate gridViewBeginDelete:self];
    
    switch (_grid_delete_all_style)
    {
        case SCHGridDeleteAllDefault:
            [self removeAllGridDefault];
            break;
            
        case SCHGridDeleteAllPaths:
            [self removeAllGridPaths];
            break;
            
        default:
            [self removeAllGridDefault];
            break;
    }
}
- (void)removeAllGridDefault
{
    [UIView animateWithDuration:0.3f
                     animations:^{
                         for (SCHGridViewCell *cell in _data_array)
                         {
                             cell.alpha = 0.0f;
                         }
                     } completion:^(BOOL finished) {
                         for (SCHGridViewCell *cell in _data_array)
                         {
                             [cell removeFromSuperview];
                         }
                         
                         [_data_array removeAllObjects];
                         
                         if([_grid_delegate respondsToSelector:@selector(gridViewEndDelete:)])
                             [_grid_delegate gridViewEndDelete:self];
                     }];
}
- (void)removeAllGridPaths
{
    all_remove_count = _data_array.count;
    int i = 0;
    for (SCHGridViewCell *cell in _data_array)
    {
        CGPoint from_point = cell.center;
        
        //路径曲线
        UIBezierPath *move_path = [UIBezierPath bezierPath];
        [move_path moveToPoint:from_point];
        
        
        CGPoint to_point;
        if([_grid_data_source respondsToSelector:@selector(gridView:toPointAtIndex:)])
        {
            
            to_point = [_grid_data_source gridView:self toPointAtIndex:i];
        }
        else
        {
            to_point = CGPointMake(0.0f, 0.0f);
        }
        
        CGPoint control_point;
        
        if([_grid_data_source respondsToSelector:@selector(gridView:controlPointAtIndex:)])
        {
            control_point = [_grid_data_source gridView:self controlPointAtIndex:i];
        }
        else
        {
            control_point = CGPointMake(to_point.x,from_point.y);
        }
        
        [move_path addQuadCurveToPoint:to_point
                         controlPoint:control_point];
        
        //关键帧
        CAKeyframeAnimation *move_anim = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        move_anim.path                 = move_path.CGPath;
        move_anim.fillMode             = kCAFillModeForwards;
        move_anim.removedOnCompletion  = NO;
        
        
        //缩放
        CABasicAnimation *scale_anim   = [CABasicAnimation animationWithKeyPath:@"transform"];
        scale_anim.fromValue           = [NSValue valueWithCATransform3D:CATransform3DIdentity];  //1.0,1.0,1.0
        //x，y轴缩小到0.,Z 轴不变
        scale_anim.toValue             = [NSValue valueWithCATransform3D:CATransform3DMakeScale(.01, .01, 1.0)];
        scale_anim.fillMode            = kCAFillModeForwards;
        scale_anim.removedOnCompletion = NO;
        
        
        //组合
        SCHAnimationGroup *anim_group  = [SCHAnimationGroup animation];
        anim_group.animations          = [NSArray arrayWithObjects:move_anim, scale_anim, nil];
        anim_group.duration            = 0.5f + 0.026 * i;
        anim_group.delegate            = self;
        anim_group.fillMode            = kCAFillModeForwards;
        anim_group.removedOnCompletion = NO;
       
        anim_group.tag                 = i;
    
        [cell.layer addAnimation:anim_group forKey:[NSString stringWithFormat:@"anim_group_%d",i]];
        ++i;
    }
}

- (void)animationDidStart:(CAAnimation *)anim
{

}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{

    --all_remove_count;
    /*全部删除了*/
    if(0 == all_remove_count)
    {
        for (SCHGridViewCell *cell in _data_array)
        {
            [cell removeFromSuperview];
            [cell.layer removeAllAnimations];
        }
        
        [_data_array removeAllObjects];
        
        if([_grid_delegate respondsToSelector:@selector(gridViewEndDelete:)])
        {
            [_grid_delegate gridViewEndDelete:self];
        }
    }
}

#pragma mark -
#pragma mark - 设置尺寸

- (void)setScrollViewSize
{
    _grid_cell_count = [_grid_data_source numberOfGridInSCHGridView:self];
    CGFloat width  = self.frame.size.width;
    CGFloat height = self.frame.size.height;

    CGFloat length = (_grid_cell_count / _row_count + 1 ) * (_grid_cell_size.height + _top_and_bottom_space) - _top_and_bottom_space  + _top_space + _bottom_space;

    
    /*设置尺寸*/
    if(length > height)
    {
        [self setContentSize:CGSizeMake(width, length)];
    }
    else
    {
        [self setContentSize:CGSizeMake(width, height)];
        
    }
}

#pragma mark -
#pragma mark - 显示插入的位置

- (void)showInsertGridView:(NSArray *)index_array
{
    /*设置尺寸*/
    [self setScrollViewSize];
    
    switch (_grid_insert_style) 
    {
        case SCHGridInsertDefault:
        {
            [self showInsertGridViewDefault:index_array];
        }
            break;
        case SCHGridInsertLight:
        {
            [self showInsertGridViewLight:index_array];
        }
            break;
        case SCHGridInsertDrop:
        {
            [self showInsertGridViewDrop:index_array];
        }
            break;
            
        default:
        {
            [self showInsertGridViewDefault:index_array];
        }
            break;
    }
}


- (void)showInsertGridViewDefault:(NSArray *)index_array
{
    for (NSNumber *number in index_array) 
    {
        SCHGridViewCell *cell = [_data_array objectAtIndex:[number intValue]];
        cell.alpha            = 0.0f;
        [self addSubview:cell];
    }
    [UIView animateWithDuration:.3f
                     animations:^{
                         for (NSNumber *number in index_array)
                         {
                             SCHGridViewCell *cell = [_data_array objectAtIndex:[number intValue]];
                             cell.alpha            = 1.0f;
                             
                         }
                     } completion:^(BOOL finished) {
                         
                     }];
    
}
- (void)showInsertGridViewLight:(NSArray *)index_array
{
    for (NSNumber *number in index_array)
    {
        SCHGridViewCell *cell = [_data_array objectAtIndex:[number intValue]];
        cell.frame = CGRectMake(cell.frame.origin.x + cell.frame.size.width / 2.0f,
                                cell.frame.origin.y + cell.frame.size.height / 2.0f,
                                0.0f,
                                0.0f);
        [self addSubview:cell];
    }
    
    [self setScrollViewSize];
    

    
    [UIView animateWithDuration:0.12f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         for (NSNumber *number in index_array)
                         {
                             SCHGridViewCell *cell = [_data_array objectAtIndex:[number intValue]];
                             cell.frame            = CGRectMake(cell.view_location_rect.origin.x,
                                                                cell.view_location_rect.origin.y + cell.view_location_rect.size.height / 2.0f - 1.0f,
                                                                cell.view_location_rect.size.width,
                                                                2.0f);
                             
                         }

                         
                     } completion:^(BOOL finished) {
                         
                         [UIView animateWithDuration:0.12f
                                               delay:0.0f
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                            
                                              for (NSNumber *number in index_array)
                                              {
                                                  SCHGridViewCell *cell = [_data_array objectAtIndex:[number intValue]];
                                                  cell.frame            = cell.view_location_rect;
                                                  
                                              }
                                          } completion:^(BOOL finished) {
                                          }];
                         
                     }];

}
- (void)showInsertGridViewDrop:(NSArray *)index_array
{
    for (NSNumber *number in index_array)
    {
        SCHGridViewCell *cell = [_data_array objectAtIndex:[number intValue]];
        cell.alpha            = 0.0f;
        cell.center           = CGPointMake(cell.view_center_point.x, cell.view_center_point.y - 30.f);
        [self addSubview:cell];
    }
    
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationCurveLinear
                     animations:^{
                         
                         for (NSNumber *number in index_array)
                         {
                             SCHGridViewCell *cell = [_data_array objectAtIndex:[number intValue]];
                             cell.alpha            = 1.0f;
                         }
                     } completion:^(BOOL finished) {
                         
                         [UIView animateWithDuration:0.2f
                                               delay:0.0f
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              
                                          } completion:^(BOOL finished) {
                                              
                                              for (NSNumber *number in index_array)
                                              {
                                                  SCHGridViewCell *cell = [_data_array objectAtIndex:[number intValue]];
                                                  cell.frame            = cell.view_location_rect;
                                              }
                                          }];
                     }];

}


#pragma mark -
#pragma mark - 批量 插入

- (void)insertGridCellOfIndex:(NSArray *)index_array
{
    /*总数*/
    _grid_cell_count = [_grid_data_source numberOfGridInSCHGridView:self];
    
    /*x y*/
    CGFloat x;
    CGFloat y;
    int     i;
    
    /*插入 cell*/
    for (NSNumber *number in index_array)
    {
        i = [number intValue];
        /*读取图标*/
        SCHGridViewCell *cell = [[_grid_data_source gridView:self cellAtIndex:i] retain];
        cell.delegate         = self;
        
        /*默认布局 SCHGridLayoutDefault */
        if(SCHGridLayoutDefault == _grid_layout_style)
        {
            x = _left_space + (i % _row_count) * (_grid_cell_size.width + _left_and_right_space);
            y = _top_space + (i / _row_count) * (_grid_cell_size.height + _top_and_bottom_space);
            
            cell.view_location_rect = CGRectMake(x,
                                                 y, 
                                                 _grid_cell_size.width , 
                                                 _grid_cell_size.height);
            cell.frame              = cell.view_location_rect;
            cell.view_center_point  = cell.center;
            
            /*是否在编辑状态*/
            if(_is_edit)
            {
                cell.delete_button.hidden = NO;
                [cell.layer setBorderWidth:2.0f];
                [cell.layer setBorderColor:[UIColor colorWithRed:0.0f green:0.1f blue:1.0f alpha:1.0f].CGColor];
            }
            
        }
        /*自定义布局SCHGridLayoutOfArray*/
        else 
        {
            cell.view_location_rect = [_grid_data_source gridView:self rectAtIndex:i];
            cell.frame              = cell.view_location_rect;
            cell.view_center_point  = cell.center;
            
            /*是否在编辑状态*/
            if(_is_edit)
            {
                cell.delete_button.hidden = NO;
                [cell.layer setBorderWidth:2.0f];
                [cell.layer setBorderColor:[UIColor colorWithRed:0.0f green:0.1f blue:1.0f alpha:1.0f].CGColor];
            }
            
        }
        
        /*存入数组*/
        [_data_array insertObject:cell atIndex:i];
        [cell release], cell = nil;
    }
    
    
    
    int start_index = _data_array.count - 1;
    int end_index   = _data_array.count - 1;
    
    for (NSNumber *number in index_array) 
    {
        if(start_index > [number intValue])
            start_index = [number intValue];
    }
    
    /*如果是插入到最后 几个*/
    if(start_index >= _data_array.count - index_array.count)
    {
        [self showInsertGridView:index_array];
        
        return;
    }
    
    /*改变布局*/

    switch (_grid_move_style)
    {
        case SCHGridMoveLineDefault:
        {
            [self insertLineGridPointStartAtIndex:start_index endAtIndex:end_index insertIndexArray:index_array];   
        }
            break;
        case SCHGridMoveWave:
        {
            [self insertWaveGridPointStartAtIndex:start_index endAtIndex:end_index  insertIndexArray:index_array];
        }
            break;
            
        case SCHGridMoveJumpUp:
        {
            [self insertJumpUpGridPointStartAtIndex:start_index endAtIndex:end_index insertIndexArray:index_array];
        }
            break;
        case SCHGridMoveJumpDown:
        {
            [self insertJumpDownGridPointStartAtIndex:start_index endAtIndex:end_index insertIndexArray:index_array];
        }
            break;
        default:
        {
            [self insertLineGridPointStartAtIndex:start_index endAtIndex:end_index insertIndexArray:index_array]; 
        }
            break;
    }
}

#pragma mark -
#pragma mark -批量 删除(未实现)

- (void)deleteGridCellOfIndex:(NSArray *)index_array
{
    //未完成
}


#pragma mark -
#pragma mark - 编辑模式

- (void)BeginEdit
{
    if(!_is_can_edit)
        return;
   
    [self editMode:-1];
}
- (void)EndEdit
{
    if(!_is_can_edit)
        return;
     [self normalMode];

}



#pragma mark -
#pragma mark - 进入 正常模式
- (void)normalMode
{

    
    if(!_is_edit)
        return;
    _is_edit = NO;
    
    if([_grid_delegate respondsToSelector:@selector(gridviewEndEdit:)])
    {
        [_grid_delegate gridviewEndEdit:self];
    }
    
    for (int i = 0; i < _data_array.count; ++i)
    {
        SCHGridViewCell *cell = [_data_array objectAtIndex:i];
        
        cell.delete_button.hidden = YES;
        [cell.layer setBorderWidth:0.0f];
    }
    
 
}

#pragma mark - 
#pragma makr -进入编辑状态

- (void)editMode:(NSInteger)index
{
  
    if(_is_edit)
        return;
    
    _is_edit = YES;
    

    
    /*循环控制 进入编辑状态*/
 
    for (int i = 0; i < _data_array.count; ++i)
    {
       
        if(i == index)
        {
            continue;
        }
        
        SCHGridViewCell *cell = [_data_array objectAtIndex:i];
        
        cell.delete_button.hidden = NO;
        [cell.layer setBorderWidth:2.0f];
        [cell.layer setBorderColor:[UIColor colorWithRed:0.0f green:0.1f blue:1.0f alpha:1.0f].CGColor];
    
    }
    
    
    if([_grid_delegate respondsToSelector:@selector(gridViewBeginEdit:)])
    {
        [_grid_delegate gridViewBeginEdit:self];
    }
    
}

#pragma mark -
#pragma mark - 删除对应图标
- (void)removeGridAtIndex:(NSInteger)index
{
    switch (_grid_delete_style)
    {
        case SCHGridDeleteDefault:
        {
            [self removeGridDefaultAtIndex:index];
        }
            break;
        case SCHGridDeleteLight:
        {
            [self removeGridLightAtIndex:index];
        }
            break;
        default:
        {
            [self removeGridDefaultAtIndex:index];
        }
            break;
    }
}

- (void)removeGridDefaultAtIndex:(NSInteger)index
{
    SCHGridViewCell *cell = [_data_array objectAtIndex:index];
    [_data_array removeObjectAtIndex:index];

    [self setScrollViewSize];
    
    ++remove_count;
    
    [UIView animateWithDuration:0.25f 
                          delay:0.0f 
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         cell.alpha = 0.0f;
                         
                     } completion:^(BOOL finished) {
                         --remove_count;
                         
                         [cell removeFromSuperview];
                         /*没有正在移除的 图标*/
                         if(0 == remove_count)
                         {   
                             if(_data_array.count > 0)
                                 [self moveLineGridPointStartAtIndex:0 endAtIndex:_data_array.count - 1];
                         }
                     }];

}

- (void)removeGridLightAtIndex:(NSInteger)index
{
    SCHGridViewCell *cell = [_data_array objectAtIndex:index];
    
    [_data_array removeObjectAtIndex:index];
    
    [self setScrollViewSize];
    
    ++remove_count;
    
    [UIView animateWithDuration:0.12f 
                          delay:0.0f 
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         cell.frame = CGRectMake(cell.frame.origin.x,
                                                 cell.frame.origin.y + cell.frame.size.height / 2.0f - 1.0f, 
                                                 cell.frame.size.width, 
                                                 2.0f);
                         
                     } completion:^(BOOL finished) {
                         
                         [UIView animateWithDuration:0.12f 
                                               delay:0.0f 
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              
                                              cell.frame = CGRectMake(cell.frame.origin.x + cell.frame.size.width / 2.0f,
                                                                      cell.frame.origin.y + cell.frame.size.height / 2.0f, 
                                                                      0.0f, 
                                                                      0.0f);
                                              
                                          } completion:^(BOOL finished) {
                                              
                                              --remove_count;
                                              
                                              [cell removeFromSuperview];
                                              
                                              /*没有正在移除的 图标*/
                                              if(0 == remove_count)
                                              {   
                                                  if(_data_array.count > 0)
                                                      [self moveLineGridPointStartAtIndex:0 endAtIndex:_data_array.count - 1];
                                              }
                                          }];
                         
                     }];
}




#pragma mark -
#pragma mark - 加载
- (void)load
{
    if(![_grid_data_source respondsToSelector:@selector(numberOfGridInSCHGridView:)])
    {
        NSLog(@"提示: 必须实现 (numberOfGridInSCHGridView:) 的委托");
        return;
    }
    
    /*方格的个数*/
    _grid_cell_count = [_grid_data_source numberOfGridInSCHGridView:self];
    
    
    if([_grid_data_source respondsToSelector:@selector(gridViewCanEdit:)])
    {
        _is_can_edit = [_grid_data_source gridViewCanEdit:self];
    }
    
    
    /*使用哪种布局方式*/
    //默认的 SCHGridLayoutDefault
    if(SCHGridLayoutDefault == _grid_layout_style)
    {
        //格子的大小
        if([_grid_data_source respondsToSelector:@selector(gridView:sizeAtIndex:)])
        {
            _grid_cell_size = [_grid_data_source gridView:self sizeAtIndex:0];
        }
        else 
        {
            _grid_cell_size = GRID_CELL_SIZE;
        }
        
        //顶部的空隙
        if([_grid_data_source respondsToSelector:@selector(gridView:topSpaceAtIndex:)])
        {
            _top_space = [_grid_data_source gridView:self topSpaceAtIndex:0];
        }
        else 
        {
            _top_space = TOP_SPACE;
        }
        
        //底部的空隙
        if([_grid_data_source respondsToSelector:@selector(gridView:bottomSpaceAtIndex:)])
        {
            _bottom_space = [_grid_data_source gridView:self bottomSpaceAtIndex:0];
        }
        else 
        {
            _bottom_space = BOTTOM_SPACE;
        }
        
        //左边的空隙
        if([_grid_data_source respondsToSelector:@selector(gridView:leftSpaceAtIndex:)])
        {
            _left_space = [_grid_data_source gridView:self leftSpaceAtIndex:0];
        }
        else 
        {
            _left_space = LEFT_SPACE;
        }
        
        
        //右边的空隙
        if ([_grid_data_source respondsToSelector:@selector(gridView:rightSpaceAtIndex:)]) 
        {
            _right_space = [_grid_data_source gridView:self rightSpaceAtIndex:0];
        }
        else 
        {
            _right_space = RIGHT_SPACE;
        }
        
        
        //cell 之间上下间距
        if([_grid_data_source respondsToSelector:@selector(gridView:topAndBottomSpaceAtIndex:)])
        {
            _top_and_bottom_space = [_grid_data_source gridView:self topAndBottomSpaceAtIndex:0];
        }
        else 
        {
            _top_and_bottom_space = TOP_AND_BOTTOM_SPACE;
        }
        
        /*列数*/
        if([_grid_data_source respondsToSelector:@selector(rowOfGridInSCHGridView:)])
        {
            _row_count = [_grid_data_source rowOfGridInSCHGridView:self];
        }
        else 
        {
            _row_count = ROW_COUNT;
        }
        

        /* 尺寸*/
        [self setScrollViewSize];
        
        
        
        CGFloat width  = self.frame.size.width;
        /*cell 之间的 间隔*/
        _left_and_right_space = (width - _grid_cell_size.width * _row_count - _left_space - _right_space) / ((CGFloat)(_row_count - 1));
        
        /*半径的长度*/
        
        _r_distance    = (_grid_cell_size.width >= _grid_cell_size.height)?_grid_cell_size.height / 2.0f: _grid_cell_size.width / 2.0f;
        
        /*x y的偏移*/
        _drag_x_offset = 0.0f;
        _drag_y_offset = 0.0f;
    }
    //自己定义的 数组 SCHGridLayoutOfArray
    else
    {
        if(![_grid_data_source respondsToSelector:@selector(gridView:rectAtIndex:)])
        {
            NSLog(@"提示: 必须实现(gridView:rectAtIndex:) 的委托");
            return;
        }
    }
    
    
    if(![_grid_data_source respondsToSelector:@selector(gridView:cellAtIndex:)])
    {
        NSLog(@"提示: 必须实现 (gridView:cellAtIndex:)  的委托");
        return;
    }
    
    
    /*x y*/
    CGFloat x;
    CGFloat y;
    /*读取图标*/
    for (int i = 0; i < _grid_cell_count; ++i) 
    {
        SCHGridViewCell *cell = [[_grid_data_source gridView:self cellAtIndex:i] retain];
        cell.delegate         = self;
        
        /*默认布局 SCHGridLayoutDefault */
        if(SCHGridLayoutDefault == _grid_layout_style)
        {
            x = _left_space + (i % _row_count) * (_grid_cell_size.width + _left_and_right_space);
            y = _top_space + (i / _row_count) * (_grid_cell_size.height + _top_and_bottom_space);
            
            cell.view_location_rect = CGRectMake(x,
                                                 y, 
                                                 _grid_cell_size.width , 
                                                 _grid_cell_size.height);
            cell.frame              = cell.view_location_rect;
            cell.view_center_point  = cell.center;
            
        }
        /*自定义布局SCHGridLayoutOfArray*/
        else 
        {
            cell.view_location_rect = [_grid_data_source gridView:self rectAtIndex:i];
            cell.frame              = cell.view_location_rect;
            cell.view_center_point  = cell.center;
            
        }
        
        /*存入数组*/
        [_data_array addObject:cell];
        [cell release], cell = nil;
    }

}

#pragma mark - 
#pragma mark - 插入的 重新排列位置

/*插入的 重新排列位置*/
- (void)insertLineGridPointStartAtIndex:(NSInteger)start_index endAtIndex:(NSInteger)end_index insertIndexArray:(NSArray *) index_array//默认的线性的移动
{
    
    
    
    /*生成字典*/
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    
    for (NSNumber *number in index_array)
    {
        [dic setObject:@"1" forKey:number];
    }
    
    
    CGFloat x;
    CGFloat y;
    
    for (int i = start_index; i <= end_index; ++i) 
    {
        
        if([dic objectForKey:[NSNumber numberWithInt:i]])
            continue;
        
        SCHGridViewCell *cell = [_data_array objectAtIndex:i];
        
        /*默认布局 SCHGridLayoutDefault */
        if(SCHGridLayoutDefault == _grid_layout_style)
        {
            x = _left_space + (i % _row_count) * (_grid_cell_size.width + _left_and_right_space);
            y = _top_space + (i / _row_count) * (_grid_cell_size.height + _top_and_bottom_space);
            
            cell.view_location_rect = CGRectMake(x,
                                                 y, 
                                                 _grid_cell_size.width , 
                                                 _grid_cell_size.height);
        }
        /*自定义布局SCHGridLayoutOfArray*/
        else 
        {
            cell.view_location_rect = [_grid_data_source gridView:self rectAtIndex:i];
        }
    }
    
    
    /*动画*/
    [UIView animateWithDuration:0.2f 
                          delay:0.0f  
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         for (int i = start_index; i <= end_index; ++i) 
                         {
                             if([dic objectForKey:[NSNumber numberWithInt:i]])
                                 continue;
                             
                             SCHGridViewCell *cell  = [_data_array objectAtIndex:i];
                             cell.frame             = cell.view_location_rect;
                             cell.view_center_point = cell.center;
                         }
                     } 
                     completion:^(BOOL finished) {
                         
                         /*显示插入的格子*/
                         [self showInsertGridView:index_array];
                     }];
    
    [dic release], dic = nil;

}
- (void)insertWaveGridPointStartAtIndex:(NSInteger)start_index endAtIndex:(NSInteger)end_index insertIndexArray:(NSArray *) index_array  //波浪的移动
{
    /*生成字典*/
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    
    for (NSNumber *number in index_array)
    {
        [dic setObject:@"1" forKey:number];
    }
    
    
    CGFloat x;
    CGFloat y;
    
    for (int i = start_index; i <= end_index; ++i) 
    {
        if([dic objectForKey:[NSNumber numberWithInt:i]])
            continue;
        
        SCHGridViewCell *cell = [_data_array objectAtIndex:i];
        
        /*默认布局 SCHGridLayoutDefault */
        if(SCHGridLayoutDefault == _grid_layout_style)
        {
            x = _left_space + (i % _row_count) * (_grid_cell_size.width + _left_and_right_space);
            y = _top_space + (i / _row_count) * (_grid_cell_size.height + _top_and_bottom_space);
            
            cell.view_location_rect = CGRectMake(x,
                                                 y, 
                                                 _grid_cell_size.width , 
                                                 _grid_cell_size.height);
            cell.view_center_point  = CGPointMake(x + _grid_cell_size.width / 2.0f , y + _grid_cell_size.height / 2.0f);
            
        }
        /*自定义布局SCHGridLayoutOfArray*/
        else 
        {
            cell.view_location_rect = [_grid_data_source gridView:self rectAtIndex:i];
            cell.view_center_point  = CGPointMake(cell.view_location_rect.origin.x + cell.view_location_rect.size.width / 2.0f , cell.view_location_rect.origin.y + cell.view_location_rect.size.height / 2.0f);
        }
    }
    
    
    /*动画*/
    int j = 0;
    for (int i = start_index; i <= end_index; ++i) 
    {
        if([dic objectForKey:[NSNumber numberWithInt:i]])
            continue;
        
        [UIView animateWithDuration:0.15f 
                              delay:0.05f * j  
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             
                             SCHGridViewCell *cell = [_data_array objectAtIndex:i];
                             cell.frame            = CGRectMake((cell.frame.origin.x + cell.view_location_rect.origin.x) / 2.0f, 
                                                                (cell.frame.origin.y + cell.view_location_rect.origin.y) / 2.0f, 
                                                                cell.view_location_rect.size.width * cell.zoom_out_scale,
                                                                cell.view_location_rect.size.height * cell.zoom_out_scale);
                             
                             
                         } 
                         completion:^(BOOL finished) {
                             
                             [UIView animateWithDuration:0.15f 
                                              animations:^{
                                                  
                                                  
                                                  SCHGridViewCell *cell  = [_data_array objectAtIndex:i];
                                                  cell.frame             = cell.view_location_rect;
                                                  cell.view_center_point = cell.center;
                                                  
                                              } 
                                              completion:^(BOOL finished) {
                                                  
                                                  if(j == _data_array.count - index_array.count - start_index - 1)
                                                  {
                                                      /*显示插入的格子*/
                                                      [self showInsertGridView:index_array];
                                                  }
                                                  
                                              }];
                         }];
        
        ++j;
    }

    [dic release], dic = nil;
}
- (void)insertJumpUpGridPointStartAtIndex:(NSInteger)start_index endAtIndex:(NSInteger)end_index insertIndexArray:(NSArray *) index_array //上跳跃
{
    /*生成字典*/
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    
    for (NSNumber *number in index_array)
    {
        [dic setObject:@"1" forKey:number];
    }
    
    CGFloat x;
    CGFloat y;
 
    
    for (int i = start_index; i <= end_index; ++i) 
    {
        if([dic objectForKey:[NSNumber numberWithInt:i]])
            continue;
        
        SCHGridViewCell *cell = [_data_array objectAtIndex:i];


        /*默认布局 SCHGridLayoutDefault */
        if(SCHGridLayoutDefault == _grid_layout_style)
        {
            x = _left_space + (i % _row_count) * (_grid_cell_size.width + _left_and_right_space);
            y = _top_space + (i / _row_count) * (_grid_cell_size.height + _top_and_bottom_space);
            
            cell.view_location_rect = CGRectMake(x,
                                                 y, 
                                                 _grid_cell_size.width , 
                                                 _grid_cell_size.height);
            cell.view_center_point  = CGPointMake(x + _grid_cell_size.width / 2.0f , y + _grid_cell_size.height / 2.0f);
            
        }
        /*自定义布局SCHGridLayoutOfArray*/
        else 
        {
            cell.view_location_rect = [_grid_data_source gridView:self rectAtIndex:i];
            cell.view_center_point  = CGPointMake(cell.view_location_rect.origin.x + cell.view_location_rect.size.width / 2.0f , cell.view_location_rect.origin.y + cell.view_location_rect.size.height / 2.0f);
        }
    }
    
    
    /*动画*/
    int j = 0;
    for (int i = start_index; i <= end_index; ++i) 
    {
        if([dic objectForKey:[NSNumber numberWithInt:i]])
            continue;
        
        [UIView animateWithDuration:0.15f 
                              delay:0.05f * j  
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             
                             SCHGridViewCell *cell = [_data_array objectAtIndex:i];
                             cell.frame            = CGRectMake((cell.frame.origin.x + cell.view_location_rect.origin.x) / 2.0f, 
                                                                (cell.frame.origin.y + cell.view_location_rect.origin.y - cell.view_location_rect.size.height) / 2.0f,  
                                                                cell.view_location_rect.size.width * cell.zoom_out_scale,
                                                                cell.view_location_rect.size.height * cell.zoom_out_scale);
                             
                             
                         } 
                         completion:^(BOOL finished) {
                             
                             [UIView animateWithDuration:0.15f 
                                              animations:^{
                                                  
                                                  
                                                  SCHGridViewCell *cell  = [_data_array objectAtIndex:i];
                                                  cell.frame             = cell.view_location_rect;
                                                  cell.view_center_point = cell.center;
                                                  
                                              } 
                                              completion:^(BOOL finished) {
                                    
                                                  if(j == _data_array.count - index_array.count - start_index - 1)
                                                  {
                                                      /*显示插入的格子*/
                                                      [self showInsertGridView:index_array];
                                                  }
                                              }];
                         }];
        
        ++j;
    }
    
    [dic release], dic = nil;
}
- (void)insertJumpDownGridPointStartAtIndex:(NSInteger)start_index endAtIndex:(NSInteger)end_index insertIndexArray:(NSArray *)index_array //下跳跃
{
    
    /*生成字典*/
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    
    for (NSNumber *number in index_array)
    {
        [dic setObject:@"1" forKey:number];
    }
    
    
    CGFloat x;
    CGFloat y;
    
    for (int i = start_index; i <= end_index; ++i) 
    {
        if([dic objectForKey:[NSNumber numberWithInt:i]])
            continue;
        
        SCHGridViewCell *cell = [_data_array objectAtIndex:i];
        
        /*默认布局 SCHGridLayoutDefault */
        if(SCHGridLayoutDefault == _grid_layout_style)
        {
            x = _left_space + (i % _row_count) * (_grid_cell_size.width + _left_and_right_space);
            y = _top_space + (i / _row_count) * (_grid_cell_size.height + _top_and_bottom_space);
            
            cell.view_location_rect = CGRectMake(x,
                                                 y, 
                                                 _grid_cell_size.width , 
                                                 _grid_cell_size.height);
            cell.view_center_point  = CGPointMake(x + _grid_cell_size.width / 2.0f , y + _grid_cell_size.height / 2.0f);
            
        }
        /*自定义布局SCHGridLayoutOfArray*/
        else 
        {
            cell.view_location_rect = [_grid_data_source gridView:self rectAtIndex:i];
            cell.view_center_point  = CGPointMake(cell.view_location_rect.origin.x + cell.view_location_rect.size.width / 2.0f , cell.view_location_rect.origin.y + cell.view_location_rect.size.height / 2.0f);
        }
    }
    
    
    /*动画*/
    int j = 0;
    for (int i = start_index; i <= end_index; ++i) 
    {
        if([dic objectForKey:[NSNumber numberWithInt:i]])
            continue;
        
        [UIView animateWithDuration:0.15f 
                              delay:0.05f * j  
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             
                             SCHGridViewCell *cell = [_data_array objectAtIndex:i];
                             cell.frame            = CGRectMake((cell.frame.origin.x + cell.view_location_rect.origin.x) / 2.0f, 
                                                                (cell.frame.origin.y + cell.view_location_rect.origin.y + cell.view_location_rect.size.height) / 2.0f, 
                                                                cell.view_location_rect.size.width * cell.zoom_out_scale,
                                                                cell.view_location_rect.size.height * cell.zoom_out_scale);
                             
                             
                         } 
                         completion:^(BOOL finished) {
                             
                             [UIView animateWithDuration:0.15f 
                                              animations:^{
                                                  
                                                  
                                                  SCHGridViewCell *cell  = [_data_array objectAtIndex:i];
                                                  cell.frame             = cell.view_location_rect;
                                                  cell.view_center_point = cell.center;
                                                  
                                              } 
                                              completion:^(BOOL finished) {
                                                  
                                                  if(j == _data_array.count - index_array.count - start_index - 1)
                                                  {
                                                      /*显示插入的格子*/
                                                      [self showInsertGridView:index_array];
                                                  }
                                              }];
                         }];
        
        ++j;
    }
    [dic release], dic = nil;
}


#pragma mark -
#pragma mark - 拖动的 重新排列位置 
/*                             被替换的方块 的位置                        移动的方块点的位置*/
- (void)changGridPointAtIndex:(NSInteger)index moveGridPointAtIndext:(NSInteger)move_index;
{
    int  start_index;
    int  end_index;
    BOOL is_insert_after; //是否往后插
    /*如果是 往前插的*/
    if(move_index > index)
    {
        start_index     = index + 1;
        end_index       = move_index;
        is_insert_after = NO;
    }
    /*如果是 往后插的*/
    else 
    {
        start_index     = move_index;
        end_index       = index - 1;
        is_insert_after = YES;
    }
    
    /*改变数组位置*/
    SCHGridViewCell *move_cell = [[_data_array objectAtIndex:move_index] retain];
    [_data_array removeObject:move_cell];
    [_data_array insertObject:move_cell atIndex:index];
    [move_cell release],move_cell = nil;
    
    /*进入委托*/
    if([_grid_delegate respondsToSelector:@selector(gridView:beginDragGrigAtIndex:changeGrigAtIndex:)])
    {
        [_grid_delegate gridView:self dragGrigAtIndex:move_index changeGrigAtIndex:index];
    }
    
    
    
    switch (_grid_move_style)
    {
        case SCHGridMoveLineDefault:
            {
                [self moveLineGridPointStartAtIndex:start_index endAtIndex:end_index];   
            }
            break;
        case SCHGridMoveWave:
            {
                [self moveWaveGridPointStartAtIndex:start_index endAtIndex:end_index isInsertAfter:is_insert_after];
            }
            break;
            
        case SCHGridMoveJumpUp:
            {
                [self moveJumpUpGridPointStartAtIndex:start_index endAtIndex:end_index isInsertAfter:is_insert_after];
            }
            break;
        case SCHGridMoveJumpDown:
            {
                [self moveJumpDownGridPointStartAtIndex:start_index endAtIndex:end_index isInsertAfter:is_insert_after];
            }
            break;
        default:
            {
                [self moveLineGridPointStartAtIndex:start_index endAtIndex:end_index];
            }
            break;
    }
    
}

//线性移动
- (void)moveLineGridPointStartAtIndex:(NSInteger)start_index endAtIndex:(NSInteger)end_index
{
    CGFloat x;
    CGFloat y;
    
    for (int i = start_index; i <= end_index; ++i) 
    {
        SCHGridViewCell *cell = [_data_array objectAtIndex:i];
        
        /*默认布局 SCHGridLayoutDefault */
        if(SCHGridLayoutDefault == _grid_layout_style)
        {
            x = _left_space + (i % _row_count) * (_grid_cell_size.width + _left_and_right_space);
            y = _top_space + (i / _row_count) * (_grid_cell_size.height + _top_and_bottom_space);
            
            cell.view_location_rect = CGRectMake(x,
                                                 y, 
                                                 _grid_cell_size.width , 
                                                 _grid_cell_size.height);

            
        }
        /*自定义布局SCHGridLayoutOfArray*/
        else 
        {
            cell.view_location_rect = [_grid_data_source gridView:self rectAtIndex:i];

            
        }
    }
    
    
    /*动画*/
    
    [UIView animateWithDuration:0.2f 
                          delay:0.0f  
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                             for (int i = start_index; i <= end_index; ++i) 
                             {
                                 SCHGridViewCell *cell = [_data_array objectAtIndex:i];
                                 cell.frame           = cell.view_location_rect;
                                 cell.view_center_point = cell.center;
                             }
                     } 
                     completion:^(BOOL finished) {
                         
                     }];
    
    
}

//波浪移动
- (void)moveWaveGridPointStartAtIndex:(NSInteger)start_index endAtIndex:(NSInteger)end_index isInsertAfter:(BOOL)is_after
{
    CGFloat x;
    CGFloat y;
    
    for (int i = start_index; i <= end_index; ++i) 
    {
        SCHGridViewCell *cell = [_data_array objectAtIndex:i];
        
        /*默认布局 SCHGridLayoutDefault */
        if(SCHGridLayoutDefault == _grid_layout_style)
        {
            x = _left_space + (i % _row_count) * (_grid_cell_size.width + _left_and_right_space);
            y = _top_space + (i / _row_count) * (_grid_cell_size.height + _top_and_bottom_space);
            
            cell.view_location_rect = CGRectMake(x,
                                                 y, 
                                                 _grid_cell_size.width , 
                                                 _grid_cell_size.height);
            cell.view_center_point  = CGPointMake(x + _grid_cell_size.width / 2.0f , y + _grid_cell_size.height / 2.0f);
            
        }
        /*自定义布局SCHGridLayoutOfArray*/
        else 
        {
            cell.view_location_rect = [_grid_data_source gridView:self rectAtIndex:i];
            cell.view_center_point  = CGPointMake(cell.view_location_rect.origin.x + cell.view_location_rect.size.width / 2.0f , cell.view_location_rect.origin.y + cell.view_location_rect.size.height / 2.0f);
        }
    }
    
    
    /*动画*/
    int j = 0;
    for (int i = start_index; i <= end_index; ++i) 
    {
        
        [UIView animateWithDuration:0.15f 
                              delay:0.05f * j  
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             
                             SCHGridViewCell *cell = [_data_array objectAtIndex:i];
                             cell.frame            = CGRectMake((cell.frame.origin.x + cell.view_location_rect.origin.x) / 2.0f, 
                                                                (cell.frame.origin.y + cell.view_location_rect.origin.y) / 2.0f, 
                                                                cell.view_location_rect.size.width * cell.zoom_out_scale,
                                                                cell.view_location_rect.size.height * cell.zoom_out_scale);
                             
                         
                         } 
                         completion:^(BOOL finished) {
                             
                             [UIView animateWithDuration:0.15f 
                                              animations:^{
                                                  
                                                  
                                                  SCHGridViewCell *cell  = [_data_array objectAtIndex:i];
                                                  cell.frame             = cell.view_location_rect;
                                                  cell.view_center_point = cell.center;
                                                  
                                              } 
                                              completion:^(BOOL finished) {
                                                  
                                              }];
                         }];
        
        ++j;
    }
    

}

- (void)moveJumpUpGridPointStartAtIndex:(NSInteger)start_index endAtIndex:(NSInteger)end_index isInsertAfter:(BOOL)is_after
{
    CGFloat x;
    CGFloat y;
    
    for (int i = start_index; i <= end_index; ++i) 
    {
        SCHGridViewCell *cell = [_data_array objectAtIndex:i];
        
        /*默认布局 SCHGridLayoutDefault */
        if(SCHGridLayoutDefault == _grid_layout_style)
        {
            x = _left_space + (i % _row_count) * (_grid_cell_size.width + _left_and_right_space);
            y = _top_space + (i / _row_count) * (_grid_cell_size.height + _top_and_bottom_space);
            
            cell.view_location_rect = CGRectMake(x,
                                                 y, 
                                                 _grid_cell_size.width , 
                                                 _grid_cell_size.height);
            cell.view_center_point  = CGPointMake(x + _grid_cell_size.width / 2.0f , y + _grid_cell_size.height / 2.0f);
            
        }
        /*自定义布局SCHGridLayoutOfArray*/
        else 
        {
            cell.view_location_rect = [_grid_data_source gridView:self rectAtIndex:i];
            cell.view_center_point  = CGPointMake(cell.view_location_rect.origin.x + cell.view_location_rect.size.width / 2.0f , cell.view_location_rect.origin.y + cell.view_location_rect.size.height / 2.0f);
        }
    }
    
    
    /*动画*/
    int j = 0;
    for (int i = start_index; i <= end_index; ++i) 
    {
        
        [UIView animateWithDuration:0.15f 
                              delay:0.05f * j  
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             
                             SCHGridViewCell *cell = [_data_array objectAtIndex:i];
                             cell.frame            = CGRectMake((cell.frame.origin.x + cell.view_location_rect.origin.x) / 2.0f, 
                                                                (cell.frame.origin.y + cell.view_location_rect.origin.y - cell.view_location_rect.size.height) / 2.0f,  
                                                                cell.view_location_rect.size.width * cell.zoom_out_scale,
                                                                cell.view_location_rect.size.height * cell.zoom_out_scale);
                             
                             
                         } 
                         completion:^(BOOL finished) {
                             
                             [UIView animateWithDuration:0.15f 
                                              animations:^{
                                                  
                                                  
                                                  SCHGridViewCell *cell  = [_data_array objectAtIndex:i];
                                                  cell.frame             = cell.view_location_rect;
                                                  cell.view_center_point = cell.center;
                                                  
                                              } 
                                              completion:^(BOOL finished) {
                                                  
                                              }];
                         }];
        
        ++j;
    }
    
}
- (void)moveJumpDownGridPointStartAtIndex:(NSInteger)start_index endAtIndex:(NSInteger)end_index isInsertAfter:(BOOL)is_after
{
    CGFloat x;
    CGFloat y;
    
    for (int i = start_index; i <= end_index; ++i) 
    {
        SCHGridViewCell *cell = [_data_array objectAtIndex:i];
        
        /*默认布局 SCHGridLayoutDefault */
        if(SCHGridLayoutDefault == _grid_layout_style)
        {
            x = _left_space + (i % _row_count) * (_grid_cell_size.width + _left_and_right_space);
            y = _top_space + (i / _row_count) * (_grid_cell_size.height + _top_and_bottom_space);
            
            cell.view_location_rect = CGRectMake(x,
                                                 y, 
                                                 _grid_cell_size.width , 
                                                 _grid_cell_size.height);
            cell.view_center_point  = CGPointMake(x + _grid_cell_size.width / 2.0f , y + _grid_cell_size.height / 2.0f);
            
        }
        /*自定义布局SCHGridLayoutOfArray*/
        else 
        {
            cell.view_location_rect = [_grid_data_source gridView:self rectAtIndex:i];
            cell.view_center_point  = CGPointMake(cell.view_location_rect.origin.x + cell.view_location_rect.size.width / 2.0f , cell.view_location_rect.origin.y + cell.view_location_rect.size.height / 2.0f);
        }
    }
    
    
    /*动画*/
    int j = 0;
    for (int i = start_index; i <= end_index; ++i) 
    {
        
        [UIView animateWithDuration:0.15f 
                              delay:0.05f * j  
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             
                             SCHGridViewCell *cell = [_data_array objectAtIndex:i];
                             cell.frame            = CGRectMake((cell.frame.origin.x + cell.view_location_rect.origin.x) / 2.0f, 
                                                                (cell.frame.origin.y + cell.view_location_rect.origin.y + cell.view_location_rect.size.height) / 2.0f, 
                                                                cell.view_location_rect.size.width * cell.zoom_out_scale,
                                                                cell.view_location_rect.size.height * cell.zoom_out_scale);
                             
                             
                         } 
                         completion:^(BOOL finished) {
                             
                             [UIView animateWithDuration:0.15f 
                                              animations:^{
                                                  
                                                  
                                                  SCHGridViewCell *cell  = [_data_array objectAtIndex:i];
                                                  cell.frame             = cell.view_location_rect;
                                                  cell.view_center_point = cell.center;
                                                  
                                              } 
                                              completion:^(BOOL finished) {
                                                  
                                              }];
                         }];
        
        ++j;
    }
    
}


#pragma mark -
#pragma mark - 清除图标

- (void)clean
{
    if(_data_array.count <= 0)
        return;
    
    for (SCHGridViewCell *grid_view in _data_array)
    {
        [grid_view removeFromSuperview];
    }
    
    if(_data_array.count > 0)
        [_data_array removeAllObjects];
    
    
}

#pragma mark - 
#pragma mark - reload 重新加载信息

- (void)reload
{
    /*清空*/
    [self clean];
    
    /*加载*/
    [self load];
    
    /*显示*/
    [self showGridView];
}

#pragma mark - 
#pragma mark - 显示
- (void)showGridView
{
    if(_data_array.count <= 0)
    {
        NSLog(@"没有可以显示的view");
        return;
    }
        
    
    /*显示的方式的选择*/
    switch (_grid_show_style)
    {
        case SCHGridShowDefault:
            {
                [self showGridViewDefault];
            }
            break;
        case SCHGridShowDivergence:
            {
                [self showGridViewDivergence];
            }
            break;
            
        default:
            {
                [self showGridViewDefault];
            }
            break;
    }
}

- (void)showGridViewDefault
{
  
    /*隐藏 */
    for (SCHGridViewCell *cell in _data_array)
    {
        cell.alpha = 0.0f;
        [self addSubview:cell];
    }
    
    [UIView animateWithDuration:0.3f
                     animations:^{
                         for (SCHGridViewCell *cell in _data_array)
                         {
                             cell.alpha = 1.0f;
                         }
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}

- (void)showGridViewDivergence
{
    /*第一个位置*/
    SCHGridViewCell *first_cell = [_data_array objectAtIndex:0];
    
    /*隐藏 和改变位置*/
    for (SCHGridViewCell *cell in _data_array)
    {
        cell.alpha = 0.0f;
        cell.frame = first_cell.view_location_rect;
        [self addSubview:cell];
    }
    
    
    /*动画*/
    [UIView animateWithDuration:0.2f
                     animations:^{
                         for (SCHGridViewCell *cell in _data_array)
                         {
                             cell.alpha = 1.0f;
                         }
                     } 
                     completion:^(BOOL finished) {
                         
                         [UIView animateWithDuration:.4f
                                          animations:^{
                                              for (SCHGridViewCell *cell in _data_array)
                                              {
                                                  cell.frame = cell.view_location_rect;
                                              }
                                          }
                                          completion:^(BOOL finished) {
                                              
                                          }];
                         
                     }];
    
}

#pragma mark -
#pragma mark - 初始化
- (id)init
{
    self = [super init];
    
    if(self)
    {
        /*初始化 存储数组*/
        _data_array = [[NSMutableArray alloc] init];
        
        /*默认 布局*/
        _grid_layout_style     = SCHGridLayoutDefault;
        
        /*默认 显示*/
        _grid_show_style       = SCHGridShowDefault;
        
        /*移动 方式*/
        _grid_move_style       = SCHGridMoveLineDefault;
        
        /*删除 消失 方式*/
        _grid_delete_style     = SCHGridDeleteDefault;
        
        /*批量插入 方式*/
        _grid_insert_style     = SCHGridInsertDefault;
        
        /*全部删除 的方式*/
        _grid_delete_all_style = SCHGridDeleteAllDefault;
        
        _is_can_edit       = NO;
    }
    
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if(nil == _data_array)
    { 
        _data_array = [[NSMutableArray alloc] init];
    }
    
    _is_can_edit       = NO;
    
    
    /*默认 布局*/
    _grid_layout_style = SCHGridLayoutDefault;
    
    
    /*默认 显示*/
    _grid_show_style   = SCHGridShowDefault;
    
    /*移动 方式*/
    _grid_move_style   = SCHGridMoveLineDefault;
    
    /*删除 消失 方式*/
    _grid_delete_style = SCHGridDeleteDefault;
    
    /*批量插入 方式*/
    _grid_insert_style = SCHGridInsertDefault;
    
    /*全部删除 的方式*/
    _grid_delete_all_style = SCHGridDeleteAllDefault;
    
    /*增加单手指 双击事件*/
    UITapGestureRecognizer *single_tap = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(normalMode)] ;
    single_tap.numberOfTapsRequired    = 2;
    single_tap.cancelsTouchesInView    = NO;
    single_tap.numberOfTouchesRequired = 1;
    single_tap.delegate                = self;
    [self addGestureRecognizer:single_tap];
    
    [single_tap release],single_tap = nil;
    
    /*增加双手指 单击事件*/
    UITapGestureRecognizer *double_tap = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(normalMode)] ;
    double_tap.numberOfTapsRequired    = 1;
    double_tap.cancelsTouchesInView    = NO;
    double_tap.numberOfTouchesRequired = 2;
    double_tap.delegate                = self;
    [self addGestureRecognizer: double_tap];
    [double_tap release], double_tap = nil;
}


#pragma mark -
#pragma mark - 格子的委托 的委托

/*删除 一个方格*/
- (void)deleteGridCell:(DeleteButton *)delete_button_sender
{
    SCHGridViewCell *cell  = delete_button_sender.grid_view_cell;
    NSInteger        index = [_data_array indexOfObject:cell];
    
    /*委托移除对象*/
    if(![_grid_delegate respondsToSelector:@selector(gridView:deleteGrigAtIndex:)])
    {
        NSLog(@"提示: 必须实现(gridView:deleteGrigAtIndex:)的委托");
    } 
    else
    {
        [_grid_delegate gridView:self deleteGrigAtIndex:index];
    }
    [self removeGridAtIndex:index];
    
}

/*进入移动状态*/
- (void)gridDidEnterMoveMode:(id)sender withLocation:(CGPoint) point moveGestureRecognizer:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if(!_is_can_edit)
        return;
    
    
    /*开始拖动*/
    _is_draging = YES;
    

    
    
    /*拖拽的 cell*/
    SCHGridViewCell *move_cell = (SCHGridViewCell *)sender;
    
    move_cell.delete_button.hidden = YES;
//    move_cell.frame                = CGRectMake(0.0f,
//                                                0.0f,
//                                                move_cell.frame.size.width * move_cell.zoom_out_scale,
//                                                move_cell.frame.size.height * move_cell.zoom_out_scale);
   // move_cell.center               = move_cell.view_center_point;
    [move_cell.layer setBorderWidth:2.0f];
    [move_cell.layer setBorderColor:[UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:1.0f].CGColor];
    
    /*如果不是 编辑状态 进入编辑状态*/
    [self editMode:[_data_array indexOfObject:move_cell]];
    
    
    CGPoint          my_point  = [gestureRecognizer locationInView:self];
    /*偏移 量*/
    _drag_x_offset             = move_cell.center.x - my_point.x;
    _drag_y_offset             = move_cell.center.y - my_point.y;
    
}
- (void)gridDidMoved:(id)sender withLocation:(CGPoint)point moveGestureRecognizer:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if(!_is_can_edit)
        return;
    
    /*中心的点*/
    SCHGridViewCell *move_cell    = (SCHGridViewCell *)sender;
    CGPoint          my_point     = [gestureRecognizer locationInView:self];
    CGPoint          center_point = CGPointMake(my_point.x + _drag_x_offset,
                                                my_point.y + _drag_y_offset);
    move_cell.center              = center_point;

    
    /*找到被替代的位置*/

    for (int i = 0; i < _data_array.count; ++i)
    {
        SCHGridViewCell *cell = [_data_array objectAtIndex:i];
        
        if(cell == move_cell)
            continue;
         

        CGFloat distance = sqrtf((cell.center.x - center_point.x) * (cell.center.x - center_point.x) + (cell.center.y - center_point.y) * (cell.center.y - center_point.y));
        
        if(distance <= _r_distance)
        {
            move_cell.view_center_point  = cell.view_center_point;
            move_cell.view_location_rect = cell.view_location_rect;

   
            [self changGridPointAtIndex:[_data_array indexOfObject:cell] moveGridPointAtIndext:[_data_array indexOfObject:move_cell]];
            break;
        }
    
    }
}

- (void)gridDidEndMoved:(id)sender withLocation:(CGPoint)point moveGestureRecognizer:(UILongPressGestureRecognizer *)gestureRecognizer
{
    
    if(!_is_can_edit)
        return;

    /*中心的点*/
    SCHGridViewCell *move_cell     = (SCHGridViewCell *)sender;
    move_cell.delete_button.hidden = NO; 
    [UIView animateWithDuration:.3f 
                     animations:^{
                         move_cell.center = move_cell.view_center_point;
                         [move_cell.layer setBorderWidth:2.0f];
                         [move_cell.layer setBorderColor:[UIColor colorWithRed:0.0f green:0.1f blue:1.0f alpha:1.0f].CGColor];
                     }];
    /*结束拖动*/
    _is_draging = NO;
}


/*出发点击*/
- (void)gridTouch:(id)sender
{
    if(_is_edit)
        return;
    
    SCHGridViewCell *touch_cell = (SCHGridViewCell *)sender;
    NSInteger        index     = [_data_array indexOfObject:touch_cell];
 
    if(![_grid_delegate respondsToSelector:@selector(gridView:didSelectGrigAtIndex:)])
    {
        NSLog(@"提示: 必须实现(gridView:didDeselectGrigAtIndex:) 委托");
    }
    else
    {
        [_grid_delegate gridView:self didSelectGrigAtIndex:index];
    }
}


#pragma mark -
#pragma mark - UIGestureRecognizerDelegate 

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    // 过滤掉SCHGridViewCell，也可以是其他类型
    if ( [touch.view isKindOfClass:[SCHGridViewCell class]])
    {
        return NO;
    }
    
    return YES;
}



#pragma mark -
#pragma mark - dealloc 
- (void)dealloc
{
    [_data_array release], _data_array = nil;
    
    [super dealloc];
}

@end
