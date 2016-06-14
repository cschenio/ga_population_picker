require 'distribution'

class BinomialTester
  attr_reader :lambda
  def initialize(lambda = rand(1.0..300.0))
    @lambda = lambda
    @success_rates = Array.new
    i = 0
    loop do
      i = i + 1
      success_rate = Distribution::Poisson.cdf(i, lambda)
      @success_rates << success_rate
      break if success_rate == 1.0
    end
    p @success_rates.map{|val|val.round(2)}
  end

  def trial(x)
    return false if x <= 0
    return true if x >= @success_rates.size
    return rand <= @success_rates[x]
  end
end
b = BinomialTester.new(30)