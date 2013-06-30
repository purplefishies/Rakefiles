# The program takes an initial word or phrase from
# the command line (or in the absence of a
# parameter from the first line of standard
# input).  In then reads successive words or
# phrases from standard input and reports whether
# they are angrams of the first word.
#
# Author::    James Damon  (mailto:jdamon@gmail.com)
# Copyright:: Copyright (c) 2012 
# License::   Distributes under the same terms as Ruby

require 'rubygems'
gem 'activerecord','3.0.9'
gem 'rake'
gem 'chronic'
require 'diary_model'
require 'chronic'


#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Going to modify it so that I can record how
# I actually leave in tasks in the journal that
# are completed, but their completion date is less than
# tomorrow..............................................................DONE!
#
#
# 2. List only tasks in the short view that aren't completed............DONE!
#
# 3.
#
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
namespace :diary do 

DIARY_TYPE       = ENV["DIARY_TYPE"]      || "work"
DIR_ENVIRONMENT  = ENV["DIARY_DIR"]       || DIARY_TYPE
LOCATION         = ENV["DIARY_LOCATION"]  || DIR_ENVIRONMENT
DIARY_DB         = ENV["DIARY_DB"]        || "." + DIARY_TYPE + ".db"
DIARY_ROOT       = ENV["DIARY_ROOT"]      || ENV["HOME"] + "/Schedule/" + DIR_ENVIRONMENT + "/"
MAIN_DIRECTORY   = DIARY_ROOT

DBFILE           = ENV["DIARY_DBFILE"]    || ENV["HOME"] + "/" + DIARY_DB

# for i in [MAIN_DIRECTORY,DIARY_ROOT,DIARY_DB,LOCATION,DIR_ENVIRONMENT]
#   puts i
# end
# exit(0)
# Extract the age and calculate the
# date-of-birth.
#--
# FIXME: fails if the birthday falls on
# February 29th
#++
# The DOB is returned as a Time object.
def currentDay
  time = Time.new()
  MAIN_DIRECTORY + time.strftime("%Y/%b/%m_%d_%y.yml")
end

desc "First Task"
task :updateProject do |t|
  curfile = currentDay()
    ActiveSupport::Deprecation.silenced = true
    ActiveRecord::Base.establish_connection( :adapter => "sqlite3", :database => DBFILE )
  if File.file?(curfile )

  else

  end

end


desc "A test"
task :test do |t|
  puts ENV["DIARY"]
end


desc "Add Diary Entry"
task :addDiary do |t|
  connect()
  if ENV["DIARY"].empty?
    throw Exception.new("Need to have specified DIARY=\"??\"" )
  end
  c = Category.find(:all, :conditions => ['name like ?',getDiary()] ).first

  if !c.nil? && ENV["DIARY"]
    t = Task.new(:entry => ENV["DIARY"] )
    t.start = Time.now
    t.category = c
    t.save
  end

end

desc "Add Task"
task :addTask, [:task,:dueDate,:expected,:parent] do |t,args|
  connect()
  b = Task.new(:entry   => args.task,
               :due     => ( args.dueDate.nil? ? nil : DateTime.parse( args.dueDate) ),
               :expcomplete => ( args.expected.nil? ? nil : args.expected ),
               :parents => ( Task.find(:all, :conditions => { :id => args.parent })
                            ),
               :start   => Time.now
               )

  b.category = Category.find(:all, :conditions => ['name = ?',getTask() ] ).first
  b.save
end


desc "Search Diary"
task :searchDiary, [:query, :flag] do |t,args|
  args.default( :query => "",
                :flag  => ""
                )
  connect()
  reg  = Regexp.new( /#{args.query}/ )
  c = Category.find( :all ) 
  getTasks( getDiary() ).find_all { |i| i.entry =~ reg }.each { |i|
    puts "##" * 3;
    puts i.entry
    puts "##" * 3 + "\n\n"
  }
end

def getDiary
  if LOCATION == "work" 
    return "workdiary"
  else
    return "diary"
  end
end

def getTask
  if LOCATION == "work"
    return "worktask"
  else
    return "task"
  end
end


desc "Delete Last diary entry"
task :deleteLastDiary do |t|

  connect()

  d = getTasks( getDiary() ).last

  d.destroy
end

desc "List Tasks"
task :listTasks , [:numlist,:completed] do |t, args|
  args.default( :numlist => false )
  defined?  debugger ? debugger() : nil
  if args.completed
    fn = Proc.new { |x| true }
  else
    fn = Proc.new { |x|
      begin
        x.completed?
      rescue
        false
      end
    }
  end
  connect()
  if args.numlist
    connect()
    # c = Category.find(:all, :conditions => ['name = ?',"task"] ).first
    c = Category.find(:all, :conditions => ['name = ?', getTask() ] ).first

    entries = getTasks( getTask() ).find_all { |i|
      #i.completed.nil?
      fn.call( i )
    }
    entry = entries.map {|i| "#{i.id}: #{i.entry}" }.join("\n")
  else
    entries = getTasks( getTask() ).find_all { |i|
      fn.call( i )
    }
    puts "Entries was of length #{entries.length}"
    entry = formatTasks( entries )
  end
  puts entry
end

#
#
#
desc "List Tasks"
task :newlistTasks , [:completed, :numlist] do |t, args|
  args.default( :completed => "false" )
  args.default( :numlist => true )

  args.completed = false
  args.numlist = false

  connect()

  c = Category.find(:all, :conditions => ['name = ?', getTask() ] ).first

  entries = getTasks( getTask() ).find_all { |i|
    (!i.completed? ) || ( i.completed? && i.completed >= Date.today )
  }

  entry = entries.map {|i| "#{i.id}: #{i.entry}" }.join("\n")
  puts entry
end


def findTask(id)
  connect()

  c = Category.find(:all, :conditions => ['name = ?', getTask()] ).first
  return Task.find(:all, 
                   :conditions => {
                     :category_id => c.id,
                     :id => id
                   }
                   ).first
end

desc "Deletes a task based on number"
task :deleteTask, [:taskID] do |t,args|
  b = findTask( args.taskID )

  b.destroy
end

desc "Mark a task as completed"
task :completeTask, [:taskID,:date] do |t,args|

  completed_date = args.date
  if !completed_date.nil? 
    puts "Parsing"
    completed_date = Chronic.parse(args.date)
  else
    completed_date = DateTime.now()
  end
  b = findTask( args.taskID )

  b.completed = completed_date.to_datetime

  b.save!
end

desc "List all tasks"
task :listsAllTasks do |t|
  connect()
  c = Category.find(:all, :conditions => ['name = ?', getTask()] ).first
  b = Task.find(:all, 
                :conditions => {
                  :category_id => c.id,
                  :id => id
                }
                )
  puts b.to_yaml
end

desc "getTask matching"
task :getTask , [:regex] do |t,args|
  args.with_defaults( :regex => ".*" )

  regex = Regexp.new( args.regex )

  if ENV["REGEX"] 
    regex = Regexp.new( ENV["REGEX"] )
  end
  connect()
  c = Category.find(:all, :conditions => ['name = ?', getTask() ] ).first
  puts selectTasksMatching( regex ).map { |i| 
    i.new_to_yaml("")
  }

end

desc "Modify task"
task :modifyTask, [:action, :tagnum] do |t|
  if args.action.nil?
    throw Exception.new("Action must be either 'delete' or 'modify'")
  end
end

#
#
#
def getTasks(*args)
  if args.empty?
    cat = "task"
  else
    cat = args[0]
  end
  c = Category.find(:all, :conditions => ['name = ?', cat ] ).first
  alltasks=  Task.find(:all, 
                       :conditions => 
                       {:category_id => c.id }
                       )
  return alltasks
end

def selectTasksMatching(regex)
  c = Category.find(:all, :conditions => ['name = ?',"task"] ).first
  alltasks=  Task.find(:all,
                       :conditions => {:category_id => c.id }
            ).find_all { |j|
               j.entry =~ regex and j.completed.nil?
            }
  return alltasks
end

def connect
  ActiveSupport::Deprecation.silenced = true
  ActiveRecord::Base.establish_connection( :adapter => "sqlite3", :database => DBFILE )
end

desc "Test task"
task :doTest do |t|
  connect()
  entry = getYamlFile
end

desc "Second Task"
task :writeTasks do |t|
  connect()
  entry = getYamlFile
  curFile = currentDay()
  puts "CurFile is #{curFile}"
  setupCorrectDirectoryForFile( curFile )
  fp = File.open(curFile,"w+")
  fp.write( entry )
  fp.close
  puts `cat #{curFile}`
end

def setupCorrectDirectoryForFile(file)
#  puts file.pathmap("%d")
  if !File.directory?( file.pathmap("%d") )
    mkdir_p( file.pathmap("%d") )
  end
end


def formatTasks(tasks)
  retstring = "#\n# Tasks\n#\n"
  retstring += "date: #{Date.today.strftime("%m/%d/%Y")}\n"
  retstring += "\n"
  retstring += "tasks: \n"
  tasks.each {|i|
    retstring += i.new_to_yaml("")
  }
  retstring += "\n\n"
  return retstring
end

def getOnlyTasks
  retstring = "#\n# Tasks\n#\n"
  retstring += "date: #{Date.today.strftime("%m/%d/%Y")}\n"
  retstring += "\n"
  retstring += "tasks: \n"

  c = Category.find(:all, :conditions => ['name = ?', getTask() ] ).first
  Task.find(:all, 
            :conditions => ["category_id == :id",
                             { :id    => c.id }
                           ]
           ).find_all { |j| j.parents.empty?   and
                            ( j.completed.nil? ||
                              j.completed >= Date.today.to_time )
                       }.each { |i|
    retstring += i.new_to_yaml("")
  }
  retstring += "\n\n"
  return retstring
end

#
#
#
def getYamlFile

  retstring = getOnlyTasks

  c = Category.find(:all, :conditions => ['name = ?',"diary"] ).first
  retstring += "\n\njournal:\n"

  getTasks( getDiary() ).find_all { |i|
    i.start >= Date.today.to_time and
    ( i.completed.nil? || i.completed > Date.today.to_time )
  }.each { |j|
    retstring += "  - time: #{j.start}\n"
    tmp = {}
    tmp["desc"] = j.entry
    retstring += "    desc:"

    if j.entry =~ /\n/
      tmpstring = "      #{j.entry}"
      tmpstring.gsub!(/\n/,"\n      ")
      retstring += " |\n#{tmpstring}\n"
    else
      retstring += " #{j.entry}\n"

    end
  }
  return retstring
end

end
