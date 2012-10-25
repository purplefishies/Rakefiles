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
namespace :latex do 

desc "Clean directory"
task :clean do |t|
    CLEAN.include("*~")
    CLEAN.include("_region*")
    CLEAN.include("sample.prv")
    files = Dir.glob("*.tex")
    CLEAN.include(files.collect {|i| i.pathmap("%X") + ".out" })
    CLEAN.include(files.collect {|i| i.pathmap("%X") + ".dvi" })
    CLEAN.include(files.collect {|i| i.pathmap("%X") + ".rel" })
    CLEAN.include(files.collect {|i| i.pathmap("%X") + ".fmt" })
    CLEAN.include(files.collect {|i| i.pathmap("%X") + ".aux" })
    CLEAN.include(files.collect {|i| i.pathmap("%X") + ".log" })
    CLEAN.include(files.collect {|i| i.pathmap("%X") + ".prv" })
    CLEAN.include(files.collect {|i| i.pathmap("%X") + ".prv" })
    CLEAN.include(files.collect {|i| i.pathmap("%X") + ".synctex.gz"})
    badfiles = IO.popen("find . -name \"_region_.*\" " ).readlines().collect { |i| i.chomp!}
    #CLEAN.include(badfiles)
    #puts "Bad files\n#{badfiles}"
    CLEAN.include( badfiles.split("\n"))


    files = Dir.glob("prv_*")
    CLEAN.include(files)
    #puts "Files are " + CLEAN.include.to_s
    CLEAN.include.uniq.each { |i|
      if File.exists?(i)
        if File.directory?(i)
          rm_rf i
        else
          rm i
        end
      end
    }
end

desc "Make Pdf"
task :makepdf, [:file]  do |t,args|
    args.with_defaults( :file => Dir.glob("*.tex").sort { |a,b| File.mtime(b) <=> File.mtime(a) }.first )
    puts "Using file #{args.file}"
    if File.file?(args.file)
      sh %{pdflatex #{args.file}}
    end
end


end
