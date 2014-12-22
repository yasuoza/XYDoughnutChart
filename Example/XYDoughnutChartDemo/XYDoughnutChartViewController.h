#import <UIKit/UIKit.h>

#import "DoughnutChartContainerView.h"

@interface XYDoughnutChartViewController : UIViewController<
XYDoughnutChartDelegate,
XYDoughnutChartDataSource>

@property (weak) IBOutlet DoughnutChartContainerView *chartContainer;

@end
