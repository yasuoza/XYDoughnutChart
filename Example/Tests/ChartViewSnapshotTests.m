#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>

#import "XYDoughnutChartViewController.h"
#import "DoughnutChartContainerView.h"
#import <XYDoughnutChart/XYDoughnutChart.h>


@interface DummyChartSourceClass : NSObject<XYDoughnutChartDelegate, XYDoughnutChartDataSource>
@end

@implementation DummyChartSourceClass

- (NSInteger)numberOfSlicesInDoughnutChart:(XYDoughnutChart *)doughnutChart
{
    return 4;
}

- (CGFloat)doughnutChart:(XYDoughnutChart *)doughnutChart valueForSliceAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.slice + 1) * 10.0;
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

- (void)testChartViewReloadData
{
    XYDoughnutChart *chart = [[XYDoughnutChart alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    DummyChartSourceClass *source = [[DummyChartSourceClass alloc] init];
    chart.delegate = source;
    chart.dataSource = source;

    [chart reloadData];
    FBSnapshotVerifyView(chart, nil);
}

- (void)testChartViewWithZeroRadiusOffset
{
    XYDoughnutChart *chart = [[XYDoughnutChart alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    chart.radiusOffset = 0.0;
    DummyChartSourceClass *source = [[DummyChartSourceClass alloc] init];
    chart.delegate = source;
    chart.dataSource = source;

    [chart reloadData];
    FBSnapshotVerifyView(chart, nil);
}

- (void)testChartViewWithHighRadiusOffset
{
    XYDoughnutChart *chart = [[XYDoughnutChart alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    chart.radiusOffset = 8.0 / 10;
    DummyChartSourceClass *source = [[DummyChartSourceClass alloc] init];
    chart.delegate = source;
    chart.dataSource = source;

    [chart reloadData];
    FBSnapshotVerifyView(chart, nil);
}

@end