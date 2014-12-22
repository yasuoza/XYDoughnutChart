Pod::Spec.new do |s|
  s.name             = "XYDoughnutChart"
  s.version          = "0.1.0"
  s.summary          = "Simple DoughnutChart library for iOS"
  s.description      = <<-DESC
                       Easy to use doughunut chart library for iOS platform.

                       This library is inspired by [XYPieChart](https://github.com/xyfeng/XYPieChart).

                       If you want to try this pod, please run demo application placed at Example folder.
                       DESC
  s.homepage         = "https://github.com/yasuoza/XYDoughnutChart"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Yasuharu Ozaki" => "yasuharu.ozaki@gmail.com" }
  s.source           = { :git => "https://github.com/yasuoza/XYDoughnutChart.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Source/Classes'
  s.resource_bundles = {
    'XYDoughnutChart' => ['Source/Assets/*.png']
  }

  s.frameworks = 'UIKit', 'QuartzCore'
end
