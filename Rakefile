WORKSPACE = 'Example/XYDoughnutChartDemo.xcworkspace'
SCHEME    = 'XYDoughnutChartDemo'
ARCH_FLAG = 'ONLY_ACTIVE_ARCH=NO'

def run(command)
  success = system %(set -o pipefail && xcodebuild #{command.to_s}  \
                                         -workspace #{WORKSPACE}    \
                                         -scheme #{SCHEME}          \
                                         -sdk iphonesimulator       \
                                         #{ARCH_FLAG}               \
                                         | xcpretty -c)
  exit! unless success
end

desc 'clean'
task :clean do
  run 'clean'
end

desc 'run sweet test'
task :test do
  run 'build test'
end

namespace :framework do
  desc 'build release framework'
  task :build do
    system <<-CMD
      carthage build --no-skip-current
      cd Carthage && zip -r -FS XYDoughnutChart.framework.zip Build && cd -
    CMD
  end
end

task default: %w[clean test]
