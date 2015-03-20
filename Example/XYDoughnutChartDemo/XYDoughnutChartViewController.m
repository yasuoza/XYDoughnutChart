#import "XYDoughnutChartViewController.h"

@interface XYDoughnutChartViewController ()

@property NSArray *sliceColors;
@property NSMutableArray *slices;

@end

@implementation XYDoughnutChartViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor darkGrayColor];

    self.slices = [NSMutableArray arrayWithCapacity:10];

    for(int i = 0; i < 4; i ++) {
        NSNumber *one = [NSNumber numberWithInt:rand()%60+20];
        [_slices addObject:one];
    }

    [self.chartContainer.chartView setDelegate:self];
    [self.chartContainer.chartView setDataSource:self];

    [self.chartContainer.chartView setShowPercentage:NO];
    [self.chartContainer.chartView setLabelColor:[UIColor blackColor]];

    self.sliceColors = @[
                         [UIColor colorWithRed:246/255.0 green:155/255.0 blue:0/255.0 alpha:1],
                         [UIColor colorWithRed:129/255.0 green:195/255.0 blue:29/255.0 alpha:1],
                         [UIColor colorWithRed:62/255.0 green:173/255.0 blue:219/255.0 alpha:1],
                         [UIColor colorWithRed:229/255.0 green:66/255.0 blue:115/255.0 alpha:1],
                         [UIColor colorWithRed:148/255.0 green:141/255.0 blue:139/255.0 alpha:1]
                         ];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [_slices removeAllObjects];
        [self.chartContainer.chartView reloadData];
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 7 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        for(int i = 0; i < 7; i ++) {
            NSNumber *one = [NSNumber numberWithInt:rand()%60+20];
            [_slices addObject:one];
        }
        [self.chartContainer.chartView reloadData:YES];
    });
}

#pragma mark - XYDoughnutChart Data Source

- (NSInteger)numberOfSlicesInDoughnutChart:(XYDoughnutChart *)doughnutChart
{
    return self.slices.count;
}

- (CGFloat)doughnutChart:(XYDoughnutChart *)doughnutChart valueForSliceAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self.slices objectAtIndex:(indexPath.slice % self.slices.count)] intValue];
}

#pragma mark - XYDoughnutChart Delegate

- (NSIndexPath *)doughnutChart:(XYDoughnutChart *)doughnutChart willSelectSliceAtIndex:(NSIndexPath *)indexPath
{
    NSLog(@"will Select slice at index %lu", (long)indexPath.slice);
    return indexPath;
}

- (void)doughnutChart:(XYDoughnutChart *)doughnutChart didSelectSliceAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"did Select slice at index %ld", (long)indexPath.slice);
}


- (void)doughnutChart:(XYDoughnutChart *)doughnutChart didDeselectSliceAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"did Deselect slice at index %ld", (long)indexPath.slice);
}


- (UIColor *)doughnutChart:(XYDoughnutChart *)doughnutChart colorForSliceAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.sliceColors objectAtIndex:(indexPath.slice % self.sliceColors.count)];
}

- (UIColor *)doughnutChart:(XYDoughnutChart *)doughnutChart selectedStrokeColorForSliceAtIndexPath:(NSIndexPath *)indexPath
{
    return [UIColor whiteColor];
}

- (CGFloat)doughnutChart:(XYDoughnutChart *)doughnutChart selectedStrokeWidthForSliceAtIndexPath:(NSIndexPath *)indexPath
{
    return 2.0;
}

@end
