# creds to Dave Thomas/Chad Fowler/Andy Hunt PickAxe1.9 book pp.242 
module Kernel
  def require_relative(relative_feature)
    c = caller.first
    fail "Can't parse #{c}" unless c.rindex(/:\d+(:in `.*')?$/)
    file = $`
    if /\A\((.*)\)/ =~ file
      raise LoadError, "require_relative is called in #{$1}"
    end
    absolute = File.expand_path(relative_feature, File.dirname(file))
    require absolute
  end 
end if RUBY_VERSION =~ /1\.8\.\d+/