require_relative 'binomial_tester'
require 'gnuplot'
class Test
  attr_accessor :success, :fail, :total
  def initialize (success = 0, fail = 0, total = 0) 
    @success = success
    @fail = fail
    @total = total
  end
  def +(other)
    Test.new(
      success = self.success + other.success,
      fail = self.fail + other.fail,
      total = self.total + other.total
    )
  end
  def rate 
    if self.total == 0
      nil
    else
      self.success.to_f / self.total
    end
  end
end
class Array
  def increase?
    return false if self.include?(nil)
    flag = true
    self.each_index do |i|
      next if i == 0 
      if self[i] < self[i-1]
        flag = false
        break
      end
    end
    return flag
  end
end
def range_average_success_rates(trial_data, range)
  n = trial_data.size
  array = Array.new(n)
  array.each_with_index do |val, i|
    l = [i-range, 0].max
    r = [i+range, n-1].min
    s = (l..r).reduce(Test.new){|sum, j| sum = sum + trial_data[j]}
    array[i] = s.rate
  end
  array
end
def choose_n(range_avg, desire_rate, step)
  n = range_avg.size
  l = 0
  r = n
  until l + 1 == r
    m = (l+r)/2
    p "#{m}, #{range_avg[m].round(3)}"
    if (range_avg[m] >= desire_rate)
      r = m
    else
      l = m
    end
  end
  return rand([l-step,0].max .. [l+step,n-1].min)
end
LAMBDA = 80 # Correct population for 93% successful rate is 92
binomial_tester = BinomialTester.new(LAMBDA) 
N = 200
TIMES = 1000
trial_data = Array.new(N){Test.new}
desire_rate = 0.93

Gnuplot.open do |gp|
  Gnuplot::Plot.new( gp ) do |plot|
  
    plot.terminal 'png size 1600,1200'
    plot.output File.expand_path("../img/rate_#{LAMBDA}_#{N}_#{TIMES}.png", __FILE__)

    plot.xrange "[0:200]"
    plot.title  "Trial n=#{N} lambda=#{LAMBDA} times=#{TIMES}"
    plot.ylabel "Success Rate"
    plot.xlabel "n"
    x = (0...N).collect { |v| v }
    trial_data[0].fail = trial_data[0].total = 1
    trial_data[N-1].success = trial_data[N-1].total = 1
    range_avg = range_average_success_rates(trial_data, N/2)
    step = N/2
    TIMES.times do |i|
      # k = rand(0...n) 
      p range_avg.map{|i| i.round(2)}
      k = choose_n(range_avg, desire_rate, step)
      p "#{i}->#{k}"
      binomial_tester.trial(k) ? trial_data[k].success += 1 : trial_data[k].fail += 1
      trial_data[k].total += 1
      (0..100).each do |j| 
        range_avg = range_average_success_rates(trial_data, j)
        if range_avg.increase?
          step = j
          plot.data << Gnuplot::DataSet.new( [x, range_avg] ) do |ds|
            ds.with = "lines"
            # ds.title = "#{i}"ls
            ds.notitle
          end
          break    
        end
      end
    end
  end
end

Gnuplot.open do |gp|
  Gnuplot::Plot.new( gp ) do |plot|

    plot.terminal 'png size 1600,1200'
    plot.output File.expand_path("../img/trial_#{LAMBDA}_#{N}_#{TIMES}.png", __FILE__)
    plot.xrange "[0:#{N}]"
    plot.y2range "[0.0:1.0]"
    plot.title  "Trial n=#{N} lambda=#{LAMBDA} times=#{TIMES}"
    plot.ylabel "Trial Time"
    plot.xlabel "n"
    x = (0...N).collect {|v| v}
    y_total = x.map{|v| trial_data[v].total}
    y_success = x.map{|v| trial_data[v].success.to_f/trial_data[v].total}
    y_fail = x.map{|v| trial_data[v].fail.to_f/trial_data[v].total}

    plot.data << Gnuplot::DataSet.new( [x, y_total] ) do |ds|
      ds.with = "boxes"
      ds.title = 'trial times'
      ds.axes = "x1y1"
    end  
    plot.data << Gnuplot::DataSet.new( [x, y_success] ) do |ds|
      ds.with = "linespoints"
      ds.title = 'succ'
      ds.axes = "x1y2"
    end          
    plot.data << Gnuplot::DataSet.new( [x, y_fail] ) do |ds|
      ds.with = "linespoints"
      ds.title = 'fail'
      ds.axes = "x1y2"
    end    
  end
end