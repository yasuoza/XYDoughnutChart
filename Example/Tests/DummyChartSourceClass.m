#import "DummyChartSourceClass.h"

@implementation DummyChartSourceClass

- (NSInteger)numberOfSlicesInDoughnutChart:(XYDoughnutChart *)doughnutChart
{
    return 4;
}

- (CGFloat)doughnutChart:(XYDoughnutChart *)doughnutChart valueForSliceAtIndexPath:(XYDoughnutIndexPath *)indexPath
{
    return (indexPath.slice + 1) * 10.0;
}

@end
