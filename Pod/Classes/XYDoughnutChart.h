//
//  XYDoughnutChart.h
//  XYDoughnutChart
//
//  Created by Yasuharu Ozaki Feng on 13/12/14.
//  Copyright (c) 2014 Yasuharu Ozaki. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.

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
@property(nonatomic, assign) CGFloat selectedSliceOffsetRadius;
@property(nonatomic, assign) BOOL    showPercentage;
- (id)initWithFrame:(CGRect)frame Center:(CGPoint)center Radius:(CGFloat)radius;
- (void)reloadData;
- (void)setPieBackgroundColor:(UIColor *)color;

- (void)setSliceSelectedAtIndex:(NSInteger)index;
- (void)setSliceDeselectedAtIndex:(NSInteger)index;

@end;
