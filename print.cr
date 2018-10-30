require "json"

##
# Example ioreg output:
#
#   >    | |           "AppleRawCurrentCapacity" = 3265
#   >    | |           "AppleRawMaxCapacity" = 4420
#   >    | |           "MaxCapacity" = 4420
#   >    | |           "CurrentCapacity" = 3265
#   >    | |           "LegacyBatteryInfo" = {"Amperage"=18446744073709551065,"Flags"=4,"Capacity"=4420,"Current"=3265,"Voltage"=7783,"Cycle Count"=158}
#   >    | |           "DesignCapacity" = 5297
#   >    | |           "BatteryData" = {"StateOfCharge"=18944,"Voltage"=7783,"QmaxCell1"=52498,"ResScale"=0,"QmaxCell2"=0,"QmaxCell0"=54034,"CycleCount"=158,"DesignCapacity"=5297}
#

def parse(ioreg)
  keys = {
    MaxCapacity: :max,
    CurrentCapacity: :cur,
    DesignCapacity: :design,
  }
  re = /"(#{keys.map { |k,| Regex.escape k.to_s }.join "|"})" = (\d+)$/
  values = {} of Symbol => Float64
  ioreg.each_line do |line|
    re =~ line || next
    label, val = $~.captures.map &.to_s
    values[keys[label]] = val.to_f
  end
  (keys.values.to_a - values.keys).tap do |missing|
    if !missing.empty?
      raise "missing from ioreg output: %s" % missing.inspect
    end
  end
  values[:pct] = values[:max]/values[:design]
  puts values.to_json
end

case ARGV
when [] of String
  parse(IO::Memory.new(`ioreg -l -w0 | grep Capacity`).tap {
    $?.success? || raise "ioreg failed"
  })
when ["-"]
  parse STDIN
else
  raise ArgumentError.new("usage: #{PROGRAM_NAME} [-]")
end
