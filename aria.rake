require 'rake'
require 'rake/clean'
require 'fileutils'
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Going to modify it so that I can record how
# I actually leave in tasks in the journal that
# are completed, but their completion date is less than
# tomorrow..............................................................DONE!
#
#
# 2. List only tasks in the short view that aren't completed............
#
# 3.
#
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
namespace :aria do 

desc "Upload accounts"
task :clean do |t|
end

desc "Take YAML file and upload account data to Aria"
task :writeYamlToAria, [:yamlfile ]  do |t,args|
    puts "Need to write this"
end


end
