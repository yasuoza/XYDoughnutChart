#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import "DummyChartSourceClass.h"

@interface ChartViewWithZeroRadiusOffsetSnapshotTests : FBSnapshotTestCase
@end

@implementation ChartViewWithZeroRadiusOffsetSnapshotTests

- (void)setUp
{
    [super setUp];
    self.recordMode = NO;
}

- (void)testChartViewWithZeroRadiusOffset
{
    XYDoughnutChart *chart = [[XYDoughnutChart alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    chart.radiusOffset = 0.0;
    DummyChartSourceClass *source = [[DummyChartSourceClass alloc] init];
    chart.delegate = source;
    chart.dataSource = source;

    [chart reloadData];
    [chart setNeedsDisplay];
    FBSnapshotVerifyView(chart, nil);
}

@end