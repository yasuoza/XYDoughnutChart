import UIKit
import XYDoughnutChart

class DataSource: NSObject, XYDoughnutChartDataSource {

    func numberOfSlicesInDoughnutChart(doughnutChart: XYDoughnutChart!) -> Int {
        return 4
    }

    func doughnutChart(doughnutChart: XYDoughnutChart!, valueForSliceAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return CGFloat(indexPath.slice + 1) * 10
    }

}

let frame = CGRectMake(0, 0, 250, 250)
let chartView = XYDoughnutChart(frame: frame)
let dataSource = DataSource()
chartView.dataSource = dataSource
chartView.reloadData()