task :default => :test

task :test do
  require 'rake/runtest'
  Rake.run_tests
end

desc "Generate TODO file"
task :TODO

file "TODO" do
  # remove old TODO file
  todo_file = Dir['TODO']
  rm(todo_file, verbose:true) unless todo_file.empty?
  
  main_file_heading = "TODO Generated on #{Time.now} by #{ENV["USER"]}"
  
  # Search all .rb files
  search_files = Dir['**/*.rb'] 
  File.open('TODO', 'w') do |todo_file|
    search_files.each do |search_file|
      File.open(search_file, 'r') do |fh|
        search_file_heading = "\nTODO in #{search_file}"
        fh.each_with_index do |line_txt, line_num|
          if (line_txt =~ /.*TODO:(.*)/i) then
            # Output main_file_heading only once, if there's a match
            if main_file_heading then
              todo_file.puts main_file_heading
              main_file_heading = nil
            end
            # Output search_file heading once, only if there's a match
            if search_file_heading then
              todo_file.puts search_file_heading
              search_file_heading = nil
            end
            # Output matching line:
            todo_file.puts "#{line_num.to_s.rjust(3, "0")}: #{$1.strip!}"
          end
        end
      end
    end
  end
end
