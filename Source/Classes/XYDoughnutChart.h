#import <UIKit/UIKit.h>

@class XYDoughnutChart;

/**
 *  The `XYDoughnutChartDataSource` is a protocol that mediates the application's 
 *  data model for a [`XYDoughnutChart`](XYDoughnutChart) object.
 */
@protocol XYDoughnutChartDataSource <NSObject>

@required

/** @name Required methods */

/**
 *  Asks the data source to return the number of slices in the chart view.
 *
 *  @param doughnutChart An object representing the chart view requesting this information.
 *
 *  @return The number of slices in chart view.
 */
- (NSUInteger)numberOfSlicesInDoughnutChart:(XYDoughnutChart *)doughnutChart;

/**
 *  Asks the data source to return the value of the specified slice in the chart view.
 *
 *  @param doughnutChart The doughnut chart object asking the value.
 *  @param index         An index number identifying a slice of chart view.
 *
 *  @return A value of specified slice in the chart view.
 */
- (CGFloat)doughnutChart:(XYDoughnutChart *)doughnutChart valueForSliceAtIndex:(NSUInteger)index;

@optional

/** @name Optional methods */

/**
 *  Asks the data source to return the text of the specified slice in the chart view.
 *
 *  @param doughnutChart The doughnut chart object asking the text.
 *  @param index         An index number identifying a slice of chart view.
 *
 *  @return A text of specified slice in the chart view.
 */
- (NSString *)doughnutChart:(XYDoughnutChart *)doughnutChart textForSliceAtIndex:(NSUInteger)index;

@end

/**
 *  The `XYDoughnutChartDelegate` protocol defines a set of optional methods you can use to receive chart events for [XYDoughnutChart](XYDoughnutChart) objects.
 *  All of the methods in this protocol are optional.
 *  You can use them in situations where you might want to adjust the chart being selected or de-selected at intended slice.
 */
@protocol XYDoughnutChartDelegate <NSObject>

@optional

/** @name Optional methods */

/**
 *  Fires just after a slice state is changed to selected.
 *
 *  @param doughnutChart The doughnut chart object has been selected.
 *  @param index         The slice index has been selected.
 */
- (void)doughnutChart:(XYDoughnutChart *)doughnutChart didSelectSliceAtIndex:(NSUInteger)index;

/**
 *  Fires just after a slice state is changed to not selected.
 *
 *  @param doughnutChart The doughnut chart object has not be selected.
 *  @param index         The slice index has not beeen selected.
 */
- (void)doughnutChart:(XYDoughnutChart *)doughnutChart didDeselectSliceAtIndex:(NSUInteger)index;

/**
 *  Asks the delegate to return the color of the slice in the chart view.
 *
 *  @discussion If delegate does not implement this method, random colors will be assigned by `XYDoughnutChart` object.
 *
 *  @param doughnutChart An object representing the chart view requesting this information.
 *  @param index         Slice index in the doughnut chart object.
 *
 *  @return UIColor object.
 */
- (UIColor *)doughnutChart:(XYDoughnutChart *)doughnutChart colorForSliceAtIndex:(NSUInteger)index;

/**
 *  Asks the delegate to return the color of the stroke color of the slice in the chart view.
 *
 *  @discussion If delegate does not implement this method, white color will be assigned by `XYDoughnutChart` object. See also doughnutChart:selectedStrokeWidthForSliceAtIndex:
 *
 *  @param doughnutChart An object representing the chart view requesting this information.
 *  @param index         Slice index in the doughnut chart object.
 *
 *  @return UIColor object.
 */
- (UIColor *)doughnutChart:(XYDoughnutChart *)doughnutChart selectedStrokeColorForSliceAtIndex:(NSUInteger)index;

/**
 *  Asks the delegate to return the width of the stroke color of the slice in the chart view. Default width is `1.0`.
 *
 *
 *  @param doughnutChart An object representing the chart view requesting this information.
 *  @param index         Slice index in the doughnut chart object.
 *
 *  @return A value for the stroke width.
 */
- (CGFloat)doughnutChart:(XYDoughnutChart *)doughnutChart selectedStrokeWidthForSliceAtIndex:(NSUInteger)index;

@end

/**
 *  A chart view object provides a view-based container for displaying doughnut chart.
 */
@interface XYDoughnutChart : UIView

/** @name Managing the Delegate and the Data Source */

/**
 *  The object that acts as the data source of the receiving doughnut chart view.
 */
@property(nonatomic, weak) id<XYDoughnutChartDataSource> dataSource;

/**
 *  The object that acts as the delegate of the receiving doughnut chart view.
 */
@property(nonatomic, weak) id<XYDoughnutChartDelegate> delegate;


/** @name Animating slices */

/**
 *  The amount of time it takes to go through one cycle of the slices. The default value is `0.5`.
 */
@property(nonatomic, assign) NSTimeInterval animationDuration;

/**
 *  The start angle where animation starts. The default value is `M_PI_2 * 3`.
 */
@property(nonatomic, assign) CGFloat startDoughnutAngle;

/**
 *  The doughnut center radius ratio. `0.0` draws chart as pie chart and `0.9` draws thin doughnut chart.
 *  The default value is `1.0 / 3.0`.
 */
@property(nonatomic, assign) CGFloat radiusOffset;

/** @name Setting and Getting Label Attributes */

/**
 *  Font for the slice label. The default font is System bold.
 */
@property(nonatomic, strong) UIFont  *labelFont;

/**
 * Color for the slice label. The default color is white color.
 */
@property(nonatomic, strong) UIColor *labelColor;

/**
 *  Color for the shadow of slice label. The default color is clear color.
 */
@property(nonatomic, strong) UIColor *labelShadowColor;

/**
 *  `YES` shows the labels in each slices. `NO` does not shows. The default is `YES`.
 */
@property(nonatomic, assign) BOOL    showLabel;

/**
 *  `YES` displays chart label as a percentage of the slices. `NO` displays the value of the slice.
 *   The default value is `YES`.
 */
@property(nonatomic, assign) BOOL    showPercentage;

/**
 *  Reloads chart view **without** animation. See also reloadData:.
 */
- (void)reloadData;

/**
 *  Draws chart view with `animated` flag.
 *
 *  @param animated `YES` draws chart view with animation. `NO` draws chart view without animation.
 */
- (void)reloadData:(BOOL)animated;

/**
 *  Set chart's background color.
 *
 *  @param color A color object to be set as chart's background color. Default color is clear color.
 */
- (void)setBackgroundColor:(UIColor *)color;

@end;
