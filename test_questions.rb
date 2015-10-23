#!/usr/bin/ruby
# -*- coding: utf-8 -*-


require 'rubygems'
require 'xml/mapping'
require 'rexml/document'
require 'open-uri'


class Problem
  attr_reader :question, :answer

  def initialize(problem)
    @question = _getQuestion( problem )
    @answer   = _getAnswer( problem )
  end

  def to_s
    "[@question=#{@question} , @answer=#{@answer}]"
  end

  def setQuestion(q)
    @question = q
  end
  def setAnswer(a)
    @answer = a
  end

  def normalize(str)
    REXML::Text::normalize(str)    
  end

  def _getQuestion(problem)
#    debugger()
    problem =~ /^.*(?:\\begin\{[kK]?Q\d?\}\s*(\S.*?)\s*\\end\{[kK]?Q\d?\}).*$/xmsu
    tmp = $1
    if !tmp.nil?
      tmp.gsub!(/\n/," ")
    else
      tmp = ""
    end
#    tmp.dup
#    REXML::Text::normalize(tmp)
    self.normalize( tmp )
  end

  def _getAnswer(problem)
    problem =~ /^.*(?:\\begin\{[kK]?A\d?\}\s*(\S.*?)\s*\\end\{[kK]?A\d?\}).*$/xmsu
    tmp =  $1
#    if !tmp.nil?
#      tmp.gsub!(/\n/," ")
#     tmp.gsub!(/&/,'&amp')
#    else 
#      tmp = ""
#    end
#    REXML::Text::normalize(tmp)
    self.normalize(tmp)
  end
end

class LatexProblems
  attr_reader :problems , :collections, :collection_range
  attr_reader :base_type
  def initialize(args)
    #puts "Fooey"
    if args[:basetype] 
      @base_type = args[:basetype] 
    else
      @base_type = Problem
    end
    if args[:file]  && File.file?(args[:file])
      loadFile( args[:file] )
    end
  end
  def to_s()
    retstring += @problems.collect { |i| 
      i.to_s
    }
    return retstring
  end

  def self.findLatexPackages(file) 
    # puts "BARRRRR!!!"
    packages = File.read(file).split("\n").find_all { |i| i =~ /^\s*((\\usepackage|\\input).*)/ } 
    # puts packages
    packages
  end

  def loadFile(file)
    defined? debugger ? debugger : nil 
    @problems = _findProblems(file )
    puts "Found problems #{problems.length}"
    # exit(1)
    @collections = [file.gsub(/\.tex/,'')]
    @collection_range = [[0,@problems.length-1]]
  end

  def addProblems(file2)
    newproblems = _findProblems( file2 )
    @collections.push( file2.gsub!(/\.tex/,''))
    @collection_range += [@problems.length, newproblems.length-1]
    @problems = @problems + newproblems
  end

  def _findProblems(file)
    if RUBY_VERSION == "1.8.7" 
      fp = IO.popen("between.pl -s 'begin\{[Kk]?QAP\d?\}' -e 'end\{[kK]?QAP\d?}' -m -i -f #{file}")
    else
      fp = IO.popen("between.pl -s 'begin\{[Kk]?QAP\d?\}' -e 'end\{[kK]?QAP\d?}' -m -i -f #{file}", :external_encoding=>"UTF-8")
    end


    lines = fp.readlines()

    defined? debugger ? debugger : nil 
    begin
      problems =  lines.join("").split(/\s+(?=\\begin\{[kK]?QAP\d?\})/).collect { |i|
        @base_type.new( i )
      }
    rescue Exception => e
      STDERR.puts("Had a problem : #{e}")
    end
    return problems;
  end

  def addProblems(file)

  end

  def writeParley(outfile)
    indent = "  "
    fp = File.open(outfile,"w+")
    fp.write( self.getHeader() )
    counter = 0
    fp.write("#{indent}<entries>\n")
    @problems.each { |problem|
#    problem = @problems.first
    fp.write("#{indent *2}<entry id=\"#{counter}\">\n")
    fp.write("#{indent *3}<translation id=\"0\">\n")
    fp.write("#{indent *3}<text>")
    fp.write("§§" + problem.question + "§§" )
    fp.write("#{indent *4}</text>\n")
    fp.write("#{indent *3}</translation>\n")
    fp.write("#{indent *2}<translation id=\"1\">\n")
    fp.write("#{indent *3}<text>")
    fp.write("§§" + problem.answer + "§§" )
    fp.write("</text>\n")
    fp.write("#{indent *2}</translation>\n")
    fp.write("#{indent *2}</entry>\n")
      counter += 1
    }
    fp.write("#{indent}</entries>\n")
    fp.write("#{indent}<lessons>\n")
    fp.write("#{indent*2}<container>\n")
    @collections.each_index { |i|
      fp.write("#{indent * 3}<name>#{@collections[i]}</name>\n")
      (@collection_range[i][0]..@collection_range[i][1]).each { |j|
        fp.write("#{indent *3}<entry id=\"#{j}\"\/>\n")
      }
    }
    fp.write("#{indent*2}</container>\n")
    fp.write("#{indent}</lessons>\n")
    fp.write("</kvtml>\n")
#    fp.write( self.getCollections() )
    fp.close()
  end

  def writeProblem( fp, counter )
    
  end
  def getCollections()
    
  end


  def getHeader()
header =<<HEADER
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE kvtml PUBLIC "kvtml2.dtd" "http://edu.kde.org/kvtml/kvtml2.dtd">
<kvtml version="2.0">
  <information>
    <generator>Parley 0.9.4</generator>
    <title>Untitled</title>
    <date>2010-10-30</date>
  </information>
  <identifiers>
    <identifier id="0">
      <name>Column 1</name>
      <locale>en</locale>
    </identifier>
    <identifier id="1">
      <name>Column 2</name>
      <locale>en</locale>
    </identifier>
  </identifiers>
HEADER
    header
  end
end

