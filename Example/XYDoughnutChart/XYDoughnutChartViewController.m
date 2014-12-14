#import "XYDoughnutChartViewController.h"

@interface XYDoughnutChartViewController ()

@property NSArray *sliceColors;
@property NSMutableArray *slices;

@end

@implementation XYDoughnutChartViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

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
        for(int i = 0; i < 5; i ++) {
            NSNumber *one = [NSNumber numberWithInt:rand()%60+20];
            [_slices addObject:one];
        }
        [self.chartContainer.chartView reloadData:YES];
    });
}

#pragma mark - XYDoughnutChart Data Source

- (NSUInteger)numberOfSlicesInPieChart:(XYDoughnutChart *)pieChart
{
    return self.slices.count;
}

- (CGFloat)pieChart:(XYDoughnutChart *)pieChart valueForSliceAtIndex:(NSUInteger)index
{
    return [[self.slices objectAtIndex:(index % self.slices.count)] intValue];
}

- (UIColor *)pieChart:(XYDoughnutChart *)pieChart colorForSliceAtIndex:(NSUInteger)index
{
    return [self.sliceColors objectAtIndex:(index % self.sliceColors.count)];
}

#pragma mark - XYDoughnutChart Delegate

- (void)pieChart:(XYDoughnutChart *)pieChart willSelectSliceAtIndex:(NSUInteger)index
{
    NSLog(@"will select slice at index %lu", (unsigned long)index);
}

- (void)pieChart:(XYDoughnutChart *)pieChart willDeselectSliceAtIndex:(NSUInteger)index
{

    NSLog(@"will deselect slice at index %lu", (unsigned long)index);
}

- (void)pieChart:(XYDoughnutChart *)pieChart didDeselectSliceAtIndex:(NSUInteger)index
{
    NSLog(@"did deselect slice at index %lu", (unsigned long)index);
}

- (void)pieChart:(XYDoughnutChart *)pieChart didSelectSliceAtIndex:(NSUInteger)index
{
    NSLog(@"did select slice at index%lu", (unsigned long)index);
//    self.selectedSliceLabel.text = [NSString stringWithFormat:@"$%@",[self.slices objectAtIndex:index]];
}

@end
