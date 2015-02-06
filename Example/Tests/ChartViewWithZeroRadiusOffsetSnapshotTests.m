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

    XCTestExpectation *reloadChartExpectation = [self expectationWithDescription:@"reload chart"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        FBSnapshotVerifyView(chart, nil);
        [reloadChartExpectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1.5 handler:nil];
}

@end