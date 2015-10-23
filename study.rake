#!/usr/bin/ruby
# Rakefile for creating schedules
#
require 'rake/loaders/makefile'

require 'rake'
require 'rake/clean'
require 'yaml'
require 'test_questions'
require 'uri'

if ENV.has_key?("OUTPUT_FILE") 
  tmp = STDOUT.dup()
  $stderr.close
end


namespace :study do 
if ENV.has_key?("SILENT")
  Rake::FileUtilsExt::verbose(false)
end
if ENV.has_key?("NOWRITE") 
  Rake::FileUtilsExt::nowrite(true)
end


task :default => [:makeQuizPDF]

class PngProblem < Problem
  def normalize(str)
    return str
  end
end

desc "Displays random tasks"
task :makePDF , [:file] do |t,args| 
  args.with_defaults(:file => "formulas.tex")
  sh %{latex #{args.file}}
  sh %{dvipdfm #{args.file.pathmap("%f").pathmap("%X")+".dvi"}}
end

desc "Study Clean"
task :clean do |t|
  CLEAN.include("*.prv")
  CLEAN.include("*.log")
  CLEAN.include("*.aux")
  CLEAN.include("*.out")
  CLEAN.include("*.pdf")
  CLEAN.include("prv_*")
  CLEAN.include("_region*")
end


#
# Need to verify that the file was correctly rendered, otherwise
# don't add the answer for a question
#
desc "Make Lots Quiz PDFS, QUIZ_NAME=quiz.pdf NOTECARDS=file1,file2..."
task :makeQuizPDFS do |t,args|

  entries = ( ENV.has_key?("NOTECARDS") ? ENV["NOTECARDS"].split(",") : [args[:file]] ) .collect { |f|
    URI(f).path
  }
  outfile = ( ENV.has_key?("QUIZ_NAME") ? ENV["QUIZ_NAME"] : "quiz.pdf" )

  frontpage = "front_page.pdf"

  final_directory = ENV.has_key?("NOTECARD_DIRECTORY") ? ENV["NOTECARD_DIRECTORY"] : "Tmp"


  if !File.directory?("#{final_directory}" )
    Dir.mkdir( "#{final_directory}")
  end

  filelist = []
  pnglist = []
  counter= 0

  entries.each { |entry | 

    defined? debugger ? debugger() : nil
    
    packages = LatexProblems.findLatexPackages( entry );
    c = LatexProblems.new( :file => entry, :basetype => PngProblem )
    
    puts "PACKAGES: #{packages}"

    c.problems.each { |problem|
      skipvalue = false
      filelist << "#{final_directory}/question_#{counter}.tex"
      makeLatexFile( filelist.last , problem.question , packages )
      pnglist << makePNGFile( filelist.last )
      if ! pnglist.last
        skipvalue = true
        pnglist.pop
      end
      if ! skipvalue
        filelist << "#{final_directory}/answer_#{counter}.tex"
        makeLatexFile( filelist.last, problem.answer , packages )
        pnglist << makePNGFile( filelist.last )
        if !pnglist.last
          pnglist.pop
        end
      end
      counter += 1
    }
  }
  frontpage = makeFrontPDF( "#{final_directory}/front_page.tex" )
  defined? debugger ? debugger() : nil
  sh %{pdfjam  --fitpaper 'true' --suffix joined  --papersize '{8.5cm,7.4cm}' #{frontpage} #{pnglist.join(" ")} --outfile #{final_directory + "/quiz.pdf"} }
  sh %{pdfjam #{final_directory + "/quiz.pdf"}  '2-' --papersize '{8.5cm,7.4cm}' --outfile #{final_directory + "/quiz.pdf"}}
  cp File.expand_path(final_directory + "/quiz.pdf" ) , outfile 
  sh "find . -type f -name \"front_page*\" -print0 -maxdepth 1 | xargs -0 rm"

end


desc "Make Quiz PDF"
task :makeQuizPDF , [:file] do |t,args|
  args.with_defaults( :file => "formulas.tex" )

  output_file = args[:file].pathmap("%f").pathmap("%X") + ".pdf"

  entries = ENV.has_key?("NOTECARDS") ? ENV["NOTECARDS"].split(",") : [args[:file]]
  
  frontpage = "front_page.pdf"

  entries.each { |entry | 
    defined? debugger ? debugger() : nil

  
    c = LatexProblems.new( :file => entry, :basetype => PngProblem )
    packages = LatexProblems.findLatexPackages( entry );

    if !File.directory?("Tmp" )
      Dir.mkdir( "Tmp")
    end

    directory = "Tmp/#{entry.pathmap("%f")}"
    if File.directory?( directory )
      sh %{rm -rf #{directory} }
    end

    Dir.mkdir( directory )
    allfiles = Dir.glob("*.eps")
    allfiles.each { |i| 
      sh %{cp -f *.eps #{i}}
    }
    filelist = []
    pnglist = []
    counter= 0

    c.problems.each { |problem|
      skipvalue = false
      keepfile = "#{directory}/question_#{counter}.tex"
      filelist << keepfile

      makeLatexFile( filelist.last , problem.question , packages)

      tmpfile = makePNGFile( filelist.last )
      
      if ! tmpfile
        # skipvalue = true
        # pnglist.pop
        next
      else 
        pnglist << tmpfile
      end

      keepfile = "#{directory}/answer_#{counter}.tex"

      filelist << keepfile
      makeLatexFile( filelist.last, problem.answer )
      tmpfile = makePNGFile( filelist.last )

      if !tmpfile
        puts "#{pnglist.join("\n")}"
        pnglist.pop
        next
      else 
        pnglist << tmpfile
      end
      counter += 1
    }
    
    frontpage = makeFrontPDF( "#{directory}/front_page.tex" )
    defined? debugger ? debugger() : nil

    sh %{pdfjam  --fitpaper 'true' --suffix joined  --papersize '{8.5cm,7.4cm}' #{frontpage} #{pnglist.join(" ")} --outfile #{directory + "/#{output_file}"} }
    sh %{pdfjam #{directory + "/#{output_file}"}  '2-' --papersize '{8.5cm,7.4cm}' --outfile #{directory + "/#{output_file}"}}
    cp File.expand_path(directory + "/#{output_file}" ) , "." 
  }
  sh "find . -type f -name \"front_page*\" -print0 -maxdepth 1 | xargs -0 rm"
end

def checkFiles(dir,files)
  files.each { |file|
    if !File.exists?("#{dir}/#{file}" )
      cp file  , "#{dir}/#{file}"
    end
  }
end

def makeFrontPDF(filename)
  header=<<FRONT
\\documentclass{article}
\\usepackage{amsmath}
\\usepackage{amssymb}
\\usepackage{geometry}
\\input{header}
\\usepackage[utf8]{inputenc}
\\usepackage{xskak}
\\geometry{
paperwidth=7.4cm,
paperheight=5.2cm,
margin=0em,
bottom=0em,
nohead
}
\\begin{document}
{
\\newpage
\\clearpage
\\par
\\begin{center}
Questions
\\end{center}
\\end{document}
}
FRONT
  fp = File.open(filename,"w+")
  fp.write(header)
  fp.close()
  defined? debugger ? debugger() : nil
  sh "pdflatex #{filename}"
  newfile = filename.pathmap("%n") + ".pdf"
  return newfile
end

def makePNGFile(filename, packages=[] )
  curdir = Dir.pwd()
  outfile = filename.pathmap("%n") + ".pdf"
  Dir.chdir(filename.pathmap("%d"))
  tmp = "tmp001"
  #puts "ORIG: #{filename}"
  begin
    sh %{latex -halt-on-error #{filename.pathmap("%n")} }
    sh %{dvips -Pwww -i -E  -o tmp #{filename.pathmap("%n") + ".dvi"} }
    sh %{gs -r300 -dEPSCrop -dTextAlphaBits=4 -sDEVICE=pdfwrite -sOutputFile=#{outfile} -dBATCH -dNOPAUSE #{tmp} }
    #puts "BEFORE: #{outfile}"
    # outfile = File.expand_path( outfile.pathmap("%X") + ".pdf" )
    outfile = File.expand_path( outfile.pathmap("%f").pathmap("%X") + ".pdf" )
  rescue  RuntimeError
    Dir.chdir(curdir)
    outfile = false
  end
  Dir.chdir(curdir)
  return outfile
end

#
#
#
def makeLatexFile(filename, string, packages=[])
  default_headers="""
\\usepackage{amsmath}
\\usepackage{amssymb}
\\usepackage{amssymb}
\\usepackage{amssymb}
\\usepackage{geometry}
\\usepackage{xskak}
\\usepackage[utf8]{inputenc}
\\input{header}
""".split("\n")

  header=<<HEADER
\\documentclass{article}
#{(default_headers | packages).join("\n")}
\\geometry{
paperwidth=7.4cm,
paperheight=5.2cm,
margin=0em,
bottom=0em,
nohead
}

\\makeatletter
\\let\\if@boxedmulticols=\\iftrue

\\pagestyle{empty}\\thispagestyle{empty}
\\setcounter{page}{1}
\\onecolumn

\\begin{document}
HEADER
  footer=<<FOOTER
\\end{document}
FOOTER
  beginner=<<BEGINNER
{
\\newpage
\\clearpage
\\par
BEGINNER
  ender=<<ENDER
\\clearpage
}
ENDER
  fp = File.open(filename,"w+")
  fp.write( header )
  fp.write( beginner )
  fp.write( string )
  fp.write( ender )
  fp.write("\n")
  fp.write( footer )
  fp.close()
end

end
