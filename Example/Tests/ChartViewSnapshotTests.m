#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>

#import "XYDoughnutChartViewController.h"
#import "DoughnutChartContainerView.h"
#import <XYDoughnutChart/XYDoughnutChart.h>


@interface DummyChartSourceClass : NSObject<XYDoughnutChartDelegate, XYDoughnutChartDataSource>
@end
@implementation DummyChartSourceClass
- (NSUInteger)numberOfSlicesInPieChart:(XYDoughnutChart *)pieChart {
    return 4;
}

- (CGFloat)pieChart:(XYDoughnutChart *)pieChart valueForSliceAtIndex:(NSUInteger)index {
    return (index + 1) * 10.0;
}
@end


@interface ChartViewSnapshotTests : FBSnapshotTestCase
@end

@implementation ChartViewSnapshotTests

- (void)setUp
{
    [super setUp];
    self.recordMode = NO;
}

- (void)testChartViewReloadData {
    XYDoughnutChart *chart = [[XYDoughnutChart alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    DummyChartSourceClass *source = [[DummyChartSourceClass alloc] init];
    chart.delegate = source;
    chart.dataSource = source;

    [chart reloadData];
    FBSnapshotVerifyView(chart, nil);
}

@end