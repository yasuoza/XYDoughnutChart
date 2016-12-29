import UIKit
import XYDoughnutChart

/*:

Mimimum data sourcing

*/

class DataSource: NSObject, XYDoughnutChartDataSource {

    func numberOfSlicesInDoughnutChart(doughnutChart: XYDoughnutChart) -> Int {
        return 4
    }

    func doughnutChart(doughnutChart: XYDoughnutChart, valueForSliceAtIndexPath indexPath: XYDoughnutIndexPath) -> CGFloat {
        return CGFloat(indexPath.slice + 1) * 10
    }

}

/*:

Draw a chart!

*/

let frame = CGRectMake(0, 0, 150, 150)
let chartView = XYDoughnutChart(frame: frame)
let dataSource = DataSource()
chartView.dataSource = dataSource
chartView.reloadData()

