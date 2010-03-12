# Utility methods for Ruby Environment validation
class ThreeSegmentNumericVersion
  include Comparable
  
  def initialize(tsnv)
    unless tsnv.respond_to?(:match) then
      raise ArgumentError, "initialized with unusable value"
    end
    
    unless tsnv.match(/^(\d+)\.(\d+)\.(\d+)$/) then
      raise ArgumentError, "initialized with an improperly formatted " \
      "three-segment numeric version string (#{tsnv})"
    end
    
    @major   = $1.to_i
    @minor   = $2.to_i
    @release = $3.to_i
  end
  attr_reader :major, :minor, :release
  
  def <=>(other)
    unless other.kind_of?(ThreeSegmentNumericVersion) then
      raise ArgumentError, "Cannot compare to non ThreeSegmentNumericVersion"
    end
    return @major <=> other.major unless @major == other.major
    return @minor <=> other.minor unless @minor == other.minor
    return @release <=> other.release
  end
  
  def to_s
    return "#{@major}.#{@minor}.#{@release}"
  end
  
  def inspect
    return self.to_s
  end
end
