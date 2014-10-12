//
//  SCHGridView.h
//  数米基金宝HD
//
//  Created by 晨豪 沈 on 12-9-14.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCHGridViewCell.h"

#define GRID_CELL_SIZE         CGSizeMake(210.0f, 180.0f)
#define TOP_SPACE              30.0f
#define BOTTOM_SPACE           30.0f
#define LEFT_SPACE             30.0f
#define RIGHT_SPACE            30.0f
#define TOP_AND_BOTTOM_SPACE   10.0f
#define ROW_COUNT              3

@class SCHGridViewCell;
@class SCHGridView;


/*布局*/
typedef enum
{
    /*默认的 布局*/
    SCHGridLayoutDefault = 1,   
    
    /*通过 一个 布局好的数组 进行 布局*/
    SCHGridLayoutOfArray = (1 << 1)    
}SCHGridLayoutStyle;



/*显示方式*/
typedef enum 
{
    /*默认显示*/
    SCHGridShowDefault    = 1,
    
    /*发散显示*/
    SCHGridShowDivergence = (1 << 1)
}SCHGridShowStyle;

/*图标移动方式*/
typedef enum 
{
    /*默认 线性移动*/
    SCHGridMoveLineDefault = 1,
    
    /*波浪移动*/
    SCHGridMoveWave        = (1 << 1),
    
    /*上 跳跃*/
    SCHGridMoveJumpUp      = (1 << 2),
    
    /*下 跳跃*/
    SCHGridMoveJumpDown    = (1 << 3)
    
}SCHGridMoveStyle;

/*图标删除的方式*/
typedef enum
{
    /*默认消失 方式*/
    SCHGridDeleteDefault = 1,
    
    /*闪烁 消失*/
    SCHGridDeleteLight   = (1 << 1)
    
}SCHGridDeleteStyle;

/*插入的方式*/
typedef enum
{
    /*默认的插入 方式*/
    SCHGridInsertDefault = 1,
    
    /*闪烁 插入*/
    SCHGridInsertLight   = (1 << 1),
    
    /*掉落 插入*/
    SCHGridInsertDrop    = (1 << 2)
}SCHGridInsertStyle;

/*全部删除的方式*/
typedef enum
{
    /*默认的删除全部的 方式*/
    SCHGridDeleteAllDefault = 1,
    
    /*删除 通过路径*/
    SCHGridDeleteAllPaths   = (1 << 1),

}SCHGridDeleteAllStyle;

/*资源*/
@protocol SCHGridViewDataSource <NSObject>
@optional
/*返回 多少格子*/
- (NSInteger)numberOfGridInSCHGridView:(SCHGridView *)grid_view;

/*返回 每一个格子*/
- (SCHGridViewCell *)gridView:(SCHGridView *)grid_view cellAtIndex:(NSInteger)index_grid;

/*返回 有多少 列数*/
- (NSInteger)rowOfGridInSCHGridView:(SCHGridView *)grid_view;

/*在  哪块区域 SCHGridLayoutOfArray */
- (CGRect)gridView:(SCHGridView *)grid_view rectAtIndex:(NSInteger)index_grid;

/*默认 布局 SCHGridLayoutDefault*/

/*格子属性*/
- (CGSize)gridView:(SCHGridView *)grid_view sizeAtIndex:(NSInteger)index_grid;

/*对于上顶的 空隙*/
- (CGFloat)gridView:(SCHGridView *)grid_view topSpaceAtIndex:(NSInteger)index_grid;

/*对于下底的 空隙*/
- (CGFloat)gridView:(SCHGridView *)grid_view bottomSpaceAtIndex:(NSInteger)index_grid;

/*对于左边的 空隙*/
- (CGFloat)gridView:(SCHGridView *)grid_view leftSpaceAtIndex:(NSInteger)index_grid;

/*对于右边的 空隙*/
- (CGFloat)gridView:(SCHGridView *)grid_view rightSpaceAtIndex:(NSInteger)index_grid;

/*gridView 上下之间的 cell 的 间距*/
- (CGFloat)gridView:(SCHGridView *)grid_view topAndBottomSpaceAtIndex:(NSInteger)index_grid;


/*全部删除 返回的点 和控制点*/
- (CGPoint)gridView:(SCHGridView *)grid_view toPointAtIndex:(NSInteger)index_grid;

- (CGPoint)gridView:(SCHGridView *)grid_view controlPointAtIndex:(NSInteger)index_grid;
 

/*是否可编辑的 默认不可编辑*/
- (BOOL)gridViewCanEdit:(SCHGridView *)grid_view;

@end


/*发出事件的委托*/
@protocol SCHGridViewDelegate<NSObject>
@optional
/*将要选择 的方块*/
- (void)gridView:(SCHGridView *)grid_view willSelectGrigAtIndex:(NSInteger)index_grid;

/*已经选择 的方块*/
- (void)gridView:(SCHGridView *)grid_view didSelectGrigAtIndex:(NSInteger)index_grid;

/*开始 拖动的*/
- (void)gridView:(SCHGridView *)grid_view beginDragGrigAtIndex:(NSInteger)index_grid;

/*移动的 点的位置 和 被变的点的位置*/
- (void)gridView:(SCHGridView *)grid_view dragGrigAtIndex:(NSInteger)index_drag_grid  changeGrigAtIndex:(NSInteger)index_change_grid;

/*结束拖拽*/
- (void)gridView:(SCHGridView *)grid_view endDragGrigAtIndex:(NSInteger)index_drag_grid;

/*删除*/
- (void)gridView:(SCHGridView *)grid_view deleteGrigAtIndex:(NSInteger)index_grid;


/*开始编辑*/
- (void)gridViewBeginEdit:(SCHGridView *)grid_view;

/*结束编辑*/
- (void)gridviewEndEdit:(SCHGridView *)grid_view;


/*删除全部*/
- (void)gridViewBeginDelete:(SCHGridView *)grid_view;
- (void)gridViewEndDelete:(SCHGridView *)grid_view;

@end

@interface SCHGridView : UIScrollView<SCHGridViewCellDelegate,UIGestureRecognizerDelegate>
{
   
    /*是否 可以 编辑*/
    BOOL                       _is_can_edit;
    
    /*是否 在 编辑*/
    BOOL                       _is_edit;
    
    /*是否 在拖动 中*/
    BOOL                       _is_draging;
    
    /*是否 在删除中*/
    BOOL                       _is_deleting;
    
    /*布局 方式*/
    SCHGridLayoutStyle         _grid_layout_style;
    
    /*显示 方式*/
    SCHGridShowStyle           _grid_show_style;
    
    /*移动 方式*/
    SCHGridMoveStyle           _grid_move_style;
    
    /*删除 消失 方式*/
    SCHGridDeleteStyle         _grid_delete_style;
    
    /*插入显示的方式*/
    SCHGridInsertStyle         _grid_insert_style;
    
    /*全部删除的方式*/
    SCHGridDeleteAllStyle      _grid_delete_all_style;
    /*总共的 格子数*/ 
    NSInteger                  _grid_cell_count;
    
    /*数据view的array*/
    NSMutableArray            *_data_array;
    
    
    id<SCHGridViewDataSource>  _grid_data_source;
    id<SCHGridViewDelegate>    _grid_delegate;
    
    
    /*格子属性*/
    /*数据的 属性*/
    CGSize                     _grid_cell_size;       //格子的大小
    CGFloat                    _top_space;            //顶部的空隙
    CGFloat                    _bottom_space;         //底部的空隙
    CGFloat                    _left_space;           //左边的空隙
    CGFloat                    _right_space;          //右边的空隙
    CGFloat                    _top_and_bottom_space; //上下间距
    CGFloat                    _left_and_right_space; //左右距离
    NSInteger                  _row_count;            //多少列
    CGSize                     _scroll_view_size;     //scroll view 的尺寸
    CGFloat                    _r_distance;           //位置改变 出发的半径
    
    CGFloat                    _drag_x_offset;        //拖动 x 的偏移量
    CGFloat                    _drag_y_offset;        //拖动 y 的偏移量
    
    
}

@property (nonatomic,assign)   id<SCHGridViewDataSource> grid_data_source;
@property (nonatomic,assign)   id<SCHGridViewDelegate>   grid_delegate;

@property (nonatomic,assign)   SCHGridLayoutStyle        grid_layout_style;
@property (nonatomic,assign)   SCHGridShowStyle          grid_show_style;
@property (nonatomic,assign)   SCHGridMoveStyle          grid_move_style;
@property (nonatomic,assign)   SCHGridDeleteStyle        grid_delete_style;
@property (nonatomic,assign)   SCHGridInsertStyle        grid_insert_style;
@property (nonatomic,assign)   SCHGridDeleteAllStyle     grid_delete_all_style;

@property (nonatomic,readonly) BOOL                      is_edit;

/*重新加载信息*/
- (void)reload;

/*编辑模式*/
- (void)BeginEdit;
- (void)EndEdit;

/*插入 数据*/
- (void)insertGridCellOfIndex:(NSArray *)index_array;

/*删除 数据*/
- (void)deleteGridCellOfIndex:(NSArray *)index_array;

/*删除 所有格子*/
- (void)deleteAllGridCell;

@end























