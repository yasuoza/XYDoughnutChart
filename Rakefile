WORKSPACE = 'Example/XYDoughnutChartDemo.xcworkspace'
SCHEME    = 'XYDoughnutChartDemo'
ARCH_FLAG = 'ONLY_ACTIVE_ARCH=NO'
DESTINATIONS = [
  'platform=iOS Simulator,name=iPhone 6,OS=8.1',
  'platform=iOS Simulator,name=iPhone 6 Plus,OS=8.1',
]


def run(command)
  args = block_given?? yield : ''
  success = system %(set -o pipefail && xcodebuild #{command.to_s}  \
                                         -workspace #{WORKSPACE}    \
                                         -scheme #{SCHEME}          \
                                         #{args}                    \
                                         #{ARCH_FLAG}               \
                                         | xcpretty -c)
  exit! unless success
end

def test(destinations: [DESTINATIONS[1]])
  run 'clean test' do
    %(#{destinations.map {|d| "-destination '#{d}'" }.join(' ')})
  end
end

namespace :test do
  desc 'run all tests'
  task :all do
    test(destinations: DESTINATIONS)
  end
end

desc 'run sweet test'
task :test do
  test
end

desc 'clean build'
task :clean do
  run :clean do
    %(#{DESTINATIONS.map {|d| "-destination '#{d}'" }.join(' ')})
  end
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

task default: %w[clean test:all]
