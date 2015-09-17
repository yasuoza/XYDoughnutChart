#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import "DummyChartSourceClass.h"

@interface ChartViewWithHighRadiusOffsetSnapshotTests : FBSnapshotTestCase
@end

@implementation ChartViewWithHighRadiusOffsetSnapshotTests

- (void)setUp
{
    [super setUp];
    self.recordMode = NO;
}

- (void)testChartViewWithHighRadiusOffset
{
    XYDoughnutChart *chart = [[XYDoughnutChart alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    chart.radiusOffset = 8.0 / 10.0;
    DummyChartSourceClass *source = [[DummyChartSourceClass alloc] init];
    chart.delegate = source;
    chart.dataSource = source;

    [chart reloadData];

    FBSnapshotVerifyView(chart, nil);
}

@end