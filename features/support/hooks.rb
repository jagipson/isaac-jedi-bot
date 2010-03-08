# Hooks for Cucumber

Before("@no_warn") do
  $VERBOSE_ASIDE = $VERBOSE
  $VERBOSE = nil
end

After("@no_warn") do 
  $VERBOSE = $VERBOSE_ASIDE
end

After("@clean_temp_file") do |scenario|
  if scenario.passed? then
    File.delete($temp_file)
  else
    puts "*** During cleanup, skipped deleting temp file named #{$temp_file}"
    end
end
