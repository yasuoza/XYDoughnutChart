WORKSPACE = 'Example/XYDoughnutChart.xcworkspace'
SCHEME    = 'XYDoughnutChart-Example'
ARCH_FLAG = 'ONLY_ACTIVE_ARCH=NO'
DESTINATIONS = [
  'platform=iOS Simulator,name=iPad,OS=7.1',
  'platform=iOS Simulator,name=iPhone 6,OS=8.1',
  'platform=iOS Simulator,name=iPhone 6 Plus,OS=8.1',
]


def run(command)
  args = block_given?? yield : ''
  system %(xcodebuild #{command.to_s}  \
            -workspace #{WORKSPACE}    \
            -scheme #{SCHEME}          \
            #{args}                    \
            #{ARCH_FLAG}               \
            | xcpretty -c)
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

task default: %w[clean test]
