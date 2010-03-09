require "lib/ruby_utilities.rb"

describe ThreeSegmentNumericVersion, "valid initialization" do
  before (:all) do
    a = (10 * rand).to_i
    b = (10 * rand).to_i
    c = (10 * rand).to_i
    d = (100 * rand).to_i
    e = (100 * rand).to_i
    f = (1000 * rand).to_i
    @segments = [a, b, c, d, e, f]
  end

  before (:each) do
    @valid_test_data_segments=[]
    3.times { @valid_test_data_segments << @segments.sample }
    @valid_test_data = @valid_test_data_segments.join(".")
  end
  
  it 'initializes with one argument that matches /^(\d+)\.(\d+)\.(\d+)$/' do
    ThreeSegmentNumericVersion.new(@valid_test_data)
  end
  
  it "raises when initialized with no arguments" do
    lambda { 
      ThreeSegmentNumericVersion.new()
    }.should raise_exception
  end
  
  it "raises when initialized with too many arguments" do
    lambda { 
      ThreeSegmentNumericVersion.new(@valid_test_data, @valid_test_data)
    }.should raise_exception
  end
  
  it "raises initialized with value that does not respond to #match" do
    lambda { 
      ThreeSegmentNumericVersion.new(nil)
    }.should raise_exception
  end
end

describe ThreeSegmentNumericVersion, "behavior" do
  
  before (:all) do
    a = (10 * rand).to_i
    b = (10 * rand).to_i
    c = (10 * rand).to_i
    d = (100 * rand).to_i
    e = (100 * rand).to_i
    f = (1000 * rand).to_i
    @segments = [a, b, c, d, e, f]
  end

  before (:each) do
    @valid_test_data_segments=[]
    3.times { @valid_test_data_segments << @segments.sample }
    @valid_test_data = @valid_test_data_segments.join(".")
    
    @tsnv = ThreeSegmentNumericVersion.new @valid_test_data
  end
  
  it "should return major version as an integer" do
    @tsnv.major.should == @valid_test_data_segments[0]
  end
    
  it "should return minor version as an integer" do
    @tsnv.minor.should == @valid_test_data_segments[1]
  end
  
  it "should return release version as an integer" do
    @tsnv.release.should == @valid_test_data_segments[2]
  end
  
  it "should raise if compared to non ThreeSegmentNumericVersion" do
    lambda { @tsnv < 3 }.should raise_exception
  end
  
  it "should properly compare version numbers" do
    @tsnv = ThreeSegmentNumericVersion.new "5.5.5" 
    same1 = ThreeSegmentNumericVersion.new "5.5.5" 
    
    low_1 = ThreeSegmentNumericVersion.new "4.4.4" 
    low_2 = ThreeSegmentNumericVersion.new "4.5.5" 
    low_3 = ThreeSegmentNumericVersion.new "4.5.6" 
    low_4 = ThreeSegmentNumericVersion.new "4.5.4"
    low_5 = ThreeSegmentNumericVersion.new "4.6.6"
    low_6 = ThreeSegmentNumericVersion.new "5.5.4"
    low_7 = ThreeSegmentNumericVersion.new "5.4.5"
    low_8 = ThreeSegmentNumericVersion.new "5.4.6"
    
    hgh_1 = ThreeSegmentNumericVersion.new "6.6.6" 
    hgh_2 = ThreeSegmentNumericVersion.new "6.5.5" 
    hgh_3 = ThreeSegmentNumericVersion.new "6.5.4" 
    hgh_4 = ThreeSegmentNumericVersion.new "6.5.6"
    hgh_5 = ThreeSegmentNumericVersion.new "6.4.4"
    hgh_6 = ThreeSegmentNumericVersion.new "5.5.6"
    hgh_7 = ThreeSegmentNumericVersion.new "5.6.5"
    hgh_8 = ThreeSegmentNumericVersion.new "5.6.4"
    
    @tsnv.should == same1
    @tsnv.should be > low_1
    @tsnv.should be > low_2
    @tsnv.should be > low_3
    @tsnv.should be > low_4
    @tsnv.should be > low_5
    @tsnv.should be > low_6
    @tsnv.should be > low_7
    @tsnv.should be > low_8
    
    @tsnv.should be < hgh_1
    @tsnv.should be < hgh_2
    @tsnv.should be < hgh_3
    @tsnv.should be < hgh_4
    @tsnv.should be < hgh_5
    @tsnv.should be < hgh_6
    @tsnv.should be < hgh_7
    @tsnv.should be < hgh_8
  end
  
  it "should represent itself as a string" do
    @tsnv.should respond_to :to_s
  end
  
  it "string representation should match initializer argument" do
    @tsnv = ThreeSegmentNumericVersion.new("123.45.6")
    @tsnv.to_s.should == "123.45.6"
  end
    
  it "should inspect as it represents itself" do
    @tsnv.to_s.should == @tsnv.inspect
  end
end