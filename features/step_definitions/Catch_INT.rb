# A work in progress, but practical tests on this feature work.


# Given /^the program was run normally$/ do
#   @errout = IO.pipe
#   @pid = spawn("ruby RubOt.rb", [ STDERR, STDOUT ] => @errout)
#   end
# end
# 
# When /^the program is sent an INT Signal$/ do
#   Process.kill "INT", @pid
# end
# 
# Then /^tell the user to press \^C again$/ do
#   @errout.close
#   raise unless @errout.string =~ /Caught Interrupt.  [CTRL]-C again exits/
# end
# 
# Then /^do not quit$/ do
#   Process.egid(@pid)
# end
# 
# When /^the program is sent an INT Signal twice$/ do
#   Process.kill "INT", @pid
#   sleep 1
#   Process.kill "INT", @pid
# end
# 
# Then /^quit$/ do
#   Process.wait
# end
# 
# When /^"([^\"]*)" seconds elapse$/ do |arg1|
#   sleep 10
# end
