@import Foundation;

/**
 *  Adds programming framework to XYDoughnutIndexPath for XYDoughnutChart.
 */
@interface XYDoughnutIndexPath : NSIndexPath

/** @name Creating an Index Path Object */

/**
 *  Returns an index-path object initialized with the indexes of a specific section in chart view.
 *
 *  @param slice An index number identifying a slice in a `XYDoughnutChartView` object.
 *
 *  @return An `XYDoughnutIndexPath` object or nil if the object could not be created.
 */
+ (XYDoughnutIndexPath *)indexPathForSlice:(NSInteger)slice;

/** @name Getting the Index of a Row or Item */

/**
*  An index number identifying a slice in a section of a doughnut chart view. (read-only)
*/
@property (assign, nonatomic) NSInteger slice;

@end
