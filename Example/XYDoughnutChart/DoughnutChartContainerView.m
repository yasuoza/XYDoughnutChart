#import "DoughnutChartContainerView.h"

@implementation DoughnutChartContainerView

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self.chartView reloadData:YES];
}

@end
