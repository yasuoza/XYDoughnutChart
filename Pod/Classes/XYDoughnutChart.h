#import <UIKit/UIKit.h>

@class XYDoughnutChart;

@protocol XYDoughnutChartDataSource <NSObject>
@required
- (NSUInteger)numberOfSlicesInPieChart:(XYDoughnutChart *)pieChart;
- (CGFloat)pieChart:(XYDoughnutChart *)pieChart valueForSliceAtIndex:(NSUInteger)index;
@optional
- (UIColor *)pieChart:(XYDoughnutChart *)pieChart colorForSliceAtIndex:(NSUInteger)index;
- (NSString *)pieChart:(XYDoughnutChart *)pieChart textForSliceAtIndex:(NSUInteger)index;
@end

@protocol XYDoughnutChartDelegate <NSObject>
@optional
- (void)pieChart:(XYDoughnutChart *)pieChart willSelectSliceAtIndex:(NSUInteger)index;
- (void)pieChart:(XYDoughnutChart *)pieChart didSelectSliceAtIndex:(NSUInteger)index;
- (void)pieChart:(XYDoughnutChart *)pieChart willDeselectSliceAtIndex:(NSUInteger)index;
- (void)pieChart:(XYDoughnutChart *)pieChart didDeselectSliceAtIndex:(NSUInteger)index;
@end

@interface XYDoughnutChart : UIView
@property(nonatomic, weak) id<XYDoughnutChartDataSource> dataSource;
@property(nonatomic, weak) id<XYDoughnutChartDelegate> delegate;
@property(nonatomic, assign) CGFloat startPieAngle;
@property(nonatomic, assign) CGFloat animationSpeed;
@property(nonatomic, assign) BOOL    showLabel;
@property(nonatomic, strong) UIFont  *labelFont;
@property(nonatomic, strong) UIColor *labelColor;
@property(nonatomic, strong) UIColor *labelShadowColor;
@property(nonatomic, assign) CGFloat labelRadius;
@property(nonatomic, assign) CGFloat selectedSliceStroke;
@property(nonatomic, assign) BOOL    showPercentage;

- (void)reloadData;
- (void)reloadData:(BOOL)animated;
- (void)setPieBackgroundColor:(UIColor *)color;
- (void)setSliceSelectedAtIndex:(NSInteger)index;
- (void)setSliceDeselectedAtIndex:(NSInteger)index;
@end;
