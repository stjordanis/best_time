class BestTime
  attr_reader :buckets

  TIERS = {
    hour: {
      range: 0...24,
      bucket: lambda{|time| time.hour },
      # graph options
      label: lambda{|key| Time.new(2012, 1, 1, key).strftime("%l %P") },
      step: 2
    },
    minute_of_day: {
      range: 0...1440,
      bucket: lambda{|time| (time.hour * 60) + time.min },
      label: lambda{|key| Time.new(2012, 1, 1, key / 60, key % 60).strftime("%H:%M") },
      step: 60
    },
    wday: {
      range: 0...7,
      bucket: lambda{|time| time.wday },
      label: lambda{|key| Time.new(2012, 1, key + 1).strftime("%a") },
      step: 1
    },
    month: {
      range: 1..12,
      bucket: lambda{|time| time.month },
      label: lambda{|key| Time.new(2012, key, 1).strftime("%b") },
      step: 1
    },
    minute: {
      range: 0...60,
      bucket: lambda{|time| time.min },
      label: lambda{|key| Time.new(2012, 1, 1, 0, key).strftime("00:%M") },
      step: 10
    }
  }

  def initialize(conversions, tier = :hour)
    @tier = TIERS[tier.to_sym]

    @buckets = {}
    range = @tier[:range]
    range.each do |hour|
      @buckets[hour] = 0
    end

    conversions.each do |conversion|
      mean = @tier[:bucket].call(conversion)
      size = range.max - range.min + 1
      std = size / 12.0
      #std = 1e-10
      value = 1 # could be weighted
      range.each do |key|
        @buckets[key] += value * (normal_pdf(key, mean, std) + normal_pdf(key + size, mean, std) + normal_pdf(key - size, mean, std))
      end
    end

    # Normalize.
    max = @buckets.values.max
    @buckets.each{|k,v| @buckets[k] = v / max }
  end

  # Graph with Google Charts.
  # Need to customize for tiers.
  def graph
    labels = buckets.keys.map{|key| @tier[:label].call(key)  }
    labels = labels.each_with_index.map{|label, i| i % @tier[:step] == 0 ? label : "" }
    url = "http://chart.apis.google.com/chart?chxt=x,y&chxl=0:|#{labels.join("|")}&chma=40,40,40,40&chbh=a,10&chs=750x400&cht=bvs&chco=A2C180&chds=a&chd=t:#{buckets.values.join(",")}"
    system("open '#{url}'")
  end

  protected

  def normal_pdf(x, mean = 0, std = 1)
    Math.exp(-((x - mean)**2/(2.0*(std**2))))/(Math.sqrt(2*Math::PI)*std)
  end

end

now = Time.now
conversions = [
  now,
  now + 3600,
  now + 7200
]

bt = BestTime.new(conversions, :hour)
bt.graph
