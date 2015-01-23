#import <objc/runtime.h>
#import "NSIndexPath+XYDoughnutChart.h"

static void *NSIndexPathXYDouchnutChartSliceKey;

@implementation NSIndexPath (XYDoughnutChart)

+ (NSIndexPath *)indexPathForSlice:(NSInteger)slice
{
    NSIndexPath *index = [[NSIndexPath alloc] init];
    index.slice = slice;
    return index;
}

- (void)setSlice:(NSInteger)slice {
    objc_setAssociatedObject(self, &NSIndexPathXYDouchnutChartSliceKey, [NSNumber numberWithInteger:slice], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)slice {
    return [(NSNumber *)objc_getAssociatedObject(self, &NSIndexPathXYDouchnutChartSliceKey) integerValue];
}

@end
