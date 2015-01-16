#import <UIKit/UIKit.h>

@class XYDoughnutChart;

@protocol XYDoughnutChartDataSource <NSObject>
@required
- (NSUInteger)numberOfSlicesInDoughnutChart:(XYDoughnutChart *)doughnutChart;
- (CGFloat)doughnutChart:(XYDoughnutChart *)doughnutChart valueForSliceAtIndex:(NSUInteger)index;
@optional
- (NSString *)doughnutChart:(XYDoughnutChart *)doughnutChart textForSliceAtIndex:(NSUInteger)index;
@end

@protocol XYDoughnutChartDelegate <NSObject>
@optional
- (void)doughnutChart:(XYDoughnutChart *)doughnutChart willSelectSliceAtIndex:(NSUInteger)index;
- (void)doughnutChart:(XYDoughnutChart *)doughnutChart didSelectSliceAtIndex:(NSUInteger)index;
- (void)doughnutChart:(XYDoughnutChart *)doughnutChart willDeselectSliceAtIndex:(NSUInteger)index;
- (void)doughnutChart:(XYDoughnutChart *)doughnutChart didDeselectSliceAtIndex:(NSUInteger)index;
- (UIColor *)doughnutChart:(XYDoughnutChart *)doughnutChart colorForSliceAtIndex:(NSUInteger)index;
- (UIColor *)doughnutChart:(XYDoughnutChart *)doughnutChart selectedStrokeColorForSliceAtIndex:(NSUInteger)index;
- (CGFloat)doughnutChart:(XYDoughnutChart *)doughnutChart selectedStrokeWidthForSliceAtIndex:(NSUInteger)index;
@end

@interface XYDoughnutChart : UIView
@property(nonatomic, weak) id<XYDoughnutChartDataSource> dataSource;
@property(nonatomic, weak) id<XYDoughnutChartDelegate> delegate;
@property(nonatomic, assign) CGFloat startPieAngle;
@property(nonatomic, assign) CGFloat animationDuration;
@property(nonatomic, assign) BOOL    showLabel;
@property(nonatomic, strong) UIFont  *labelFont;
@property(nonatomic, strong) UIColor *labelColor;
@property(nonatomic, strong) UIColor *labelShadowColor;
@property(nonatomic, assign) CGFloat labelRadius;
@property(nonatomic, assign) BOOL    showPercentage;

- (void)reloadData;
- (void)reloadData:(BOOL)animated;
- (void)setPieBackgroundColor:(UIColor *)color;
- (void)setSliceSelectedAtIndex:(NSInteger)index;
- (void)setSliceDeselectedAtIndex:(NSInteger)index;
@end;
