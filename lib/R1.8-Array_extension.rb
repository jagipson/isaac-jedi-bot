class Array
  def sample
    self.sort_by { rand }[0]
  end
end if RUBY_VERSION =~ /1\.8\.\d+/
