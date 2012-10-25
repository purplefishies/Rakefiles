#!/usr/bin/ruby
# Rakefile for creating schedules
#
require 'rake/loaders/makefile'
require 'yaml'

#namespace :tasks do#
desc "does something"
task :foo do
  puts "Another task"
end

desc "Displays tasks required for completion"
task :listTasks do |t| 
  directories = Dir.entries(".").find_all { |i| File.directory?(i) && i !~ /^\.{1,2}/ }
  end

desc "Displays tasks required for completion"
task :listProjects do |t| 
  c = YAML.load_file( File.expand_path("~/" + "Projects/" +  "Projects.yml"))
  counter = 1
  c["ideas"].sort {|x,y| 
    if y.has_value?("priority") and x.has_value?("priority")
      y["priority"] <=> x["priority"]  
    elsif y.has_value?("priority") 
      1 
    else
      -1 
    end
  }.each { |i|
    puts "#{counter}.\t#{i["idea"]}"
    counter += 1
  }
end

desc "Display long term goals"
task :listLongtermProjects do |t| 
  c = YAML.load_file( File.expand_path("~/" + "OngoingProjects/" +  "Projects.yml"))
  counter = 1
  c["ideas"].sort {|x,y| 
    if y.has_value?("priority") and x.has_value?("priority")
      y["priority"] <=> x["priority"]  
    elsif y.has_value?("priority") 
      1 
    else
      -1 
    end
  }.each { |i|
    puts "#{counter}.\t#{i["idea"]}"
    counter += 1
  }
end

def getProjects(file, key)
  c = YAML.load_file(file)
  return c[key]
end

def sortProjects(projects)
  counter = 1
  return  projects.sort {|x,y| 
    if y.has_value?("priority") and x.has_value?("priority")
      y["priority"] <=> x["priority"]  
    elsif y.has_value?("priority") 
      1 
    else
      -1 
    end
  }.each { |i|
    puts "#{counter}.\t#{i["idea"]}"
    counter += 1
  }  
end

namespace :pictures do 

desc "Automatically rename pictures"
task :autoRename do |t|
    files = `ls *.png`.split("\n")
    if !File.directory?("Hold")
      sh %{mkdir Hold}
    end
    sh %{rm -f Hold/*}
    if !File.directory?("Old")
      sh %{mkdir Old}
    end
    files.sort!
    files.each_index {|i|
#      puts i
      sh %{cp #{files[i]} #{"Hold/" + "page_" + sprintf("%2.2d",i+1) + ".png"} }
    }
    files.each { |i|
      sh %{mv #{i} #{"Old/" + i}}
    }
    Dir.entries("Hold/").find_all { |i| i =~ /\.png/ }.each { |i|
      sh %{cp #{"Hold/" + i} . }
    }
  end

desc "Convert Odd number pages"
task :convertOdd do |t|

end

desc "Convert Even number pages"
task :convertEven do |t|

end


desc "Converts PNG to JPG"
task :convertAllPics do |t|
    depth = ENV["DEPTH"] || 2
    quality = ENV["QUALITY"] || 4
    Dir.entries(".").find_all { |i| i =~ /\.png/ }.each { |i|
      sh %{convert -depth 2  -quality 4   #{i}  #{i.pathmap("%X") + ".jpg"}}
    }
  end
desc "Makes a PDF of jpgs"
task :makePDF, [:outfile] do |t,args |
    args.with_defaults(:outfile => "outfile.pdf" )
    outfile = ENV["OUTFILE"]  || args.outfile
    jpegs = Dir.entries(".").find_all { |i| i =~ /\.jpg/ }.sort!
    puts "Outfile : #{outfile}"
    sh %{pdfjam #{jpegs.join(" ")} -o #{outfile}}

end

desc "Makes a final PDF"
task :makeFinalPDF, [:outfile] do |t,args |
    args.with_defaults(:outfile => "Final.pdf" )
    outfile = ENV["OUTFILE"]  || args.outfile
    dirs = Dir.entries(".").find_all { |i| File.directory?(i)  &&
      i !~ /^.{1,2}$/ 
    }.sort!
    puts "Dirs are #{dirs}"
    files = []
#    dirs.each { |dir|
#      files << `find #{dir} . -name "*.pdf" -maxdepth 2 2>/dev/null`.split("\n").sort!
#    }
    dirs.each { |dir|
      files << Dir.entries("#{dir}/").find_all { 
        |i| i =~ /\.pdf/ 
        }.map { |i|         "#{dir}/#{i}"
      }
    }
    puts "Files are #{files.join("\n")}"
    coverfile = File.exist?("cover.jpg")  ? "cover.jpg" : "" 
    endfile   = File.exist?("end.jpg")  ? "end.jpg" : "" 
    sh %{pdfjam #{coverfile} #{files.join(" ")} #{endfile}  -o #{outfile}}
end




end

