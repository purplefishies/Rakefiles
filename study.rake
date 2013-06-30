#!/usr/bin/ruby
# Rakefile for creating schedules
#
require 'rake/loaders/makefile'

require 'rake'
require 'rake/clean'
require 'yaml'
require 'test_questions'
namespace :study do 



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
  sh %{dvipdfm #{args.file.pathmap("%X")+".dvi"}}
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




desc "Make Quiz PDF"
task :makeQuizPDF , [:file] do |t,args|
  args.with_defaults( :file => "formulas.tex" )
  puts "HERE"
  puts "Using file #{args[:file]}"
  frontpage = "front_page.pdf"
  defined? debugger ? debugger() : nil
  c = LatexProblems.new( :file => args[:file] ,
                         :basetype => PngProblem
                         )

  puts "Problems are #{c.problems}"

  if !File.directory?("Tmp" )
    Dir.mkdir( "Tmp")
  end
  directory = "Tmp/#{args[:file].pathmap("%X")}"
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
    filelist << "#{directory}/question_#{counter}.tex"
    #checkFiles(directory, ["mystyle.sty","problems.sty"])
    makeLatexFile( filelist.last , problem.question )
    pnglist << makePNGFile( filelist.last )
    if ! pnglist.last
      skipvalue = true
      pnglist.pop
    end
    if ! skipvalue
      filelist << "#{directory}/answer_#{counter}.tex"
      makeLatexFile( filelist.last, problem.answer )
      pnglist << makePNGFile( filelist.last )
      if !pnglist.last
        pnglist.pop
      end
    end
    counter += 1
  }
  frontpage = makeFrontPDF( "#{directory}/front_page.tex" )
  defined? debugger ? debugger() : nil
  sh %{pdfjam  --fitpaper 'true' --suffix joined  --papersize '{8.5cm,7.4cm}' #{frontpage} #{pnglist.join(" ")} --outfile #{directory + "/quiz.pdf"} }
  sh %{pdfjam #{directory + "/quiz.pdf"}  '2-' --papersize '{8.5cm,7.4cm}' --outfile #{directory + "/quiz.pdf"}}
end

def checkFiles(dir,files)
  files.each { |file|
    if !File.exists?("#{dir}/#{file}" )
#      File.cp( file, "#{dir}/#{file}" )
      cp file  , "#{dir}/#{file}"
    end
  }
end

def makeFrontPDF(filename)
  header=<<FRONT
\\documentclass{article}
\\usepackage{amsmath}
\\usepackage{amssymb}
\\usepackage{problems}
\\usepackage{mystyle}
\\usepackage{geometry}
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

def makePNGFile(filename)
  curdir = Dir.pwd()
  outfile = filename.pathmap("%n") + ".pdf"
  Dir.chdir(filename.pathmap("%d"))
  tmp = "tmp001"
  begin
    sh %{latex -halt-on-error #{filename.pathmap("%n")} }
    # %{latex -halt-on-error #{filename.pathmap("%n")} }
    sh %{dvips -Pwww -i -E  -o tmp #{filename.pathmap("%n") + ".dvi"} }
    #sh %{gs -r300 -dEPSCrop -dTextAlphaBits=4 -sDEVICE=png16m -sOutputFile=#{outfile} -dBATCH -dNOPAUSE #{tmp} }
    sh %{gs -r300 -dEPSCrop -dTextAlphaBits=4 -sDEVICE=pdfwrite -sOutputFile=#{outfile} -dBATCH -dNOPAUSE #{tmp} }
    #sh %{dvipng -D 400 #{filename.pathmap("%n")} -o #{outfile} }
    #sh %{convert #{outfile} #{outfile.pathmap("%X") + ".jpg"}}
    #outfile = File.expand_path( outfile.pathmap("%X") + ".jpg" )
    outfile = File.expand_path( outfile.pathmap("%X") + ".pdf" )
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
def makeLatexFile(filename, string)
  header=<<HEADER
\\documentclass{article}
\\usepackage{amsmath}
\\usepackage{amssymb}
\\usepackage{problems}
\\usepackage{mystyle}
\\usepackage{geometry}
\\usepackage{xskak}
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
