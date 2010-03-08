# Hooks for Cucumber

After("@clean_temp_file") do |scenario|
  if scenario.passed? then
    File.delete($temp_file)
  else
    puts "*** During cleanup, skipped deleting temp file named #{$temp_file}"
    end
end