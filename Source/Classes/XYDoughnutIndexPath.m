#import <objc/runtime.h>
#import "XYDoughnutIndexPath.h"

@implementation XYDoughnutIndexPath

+ (XYDoughnutIndexPath *)indexPathForSlice:(NSInteger)slice
{
    XYDoughnutIndexPath *index = [[XYDoughnutIndexPath alloc] init];
    index.slice = slice;
    return index;
}

@end
