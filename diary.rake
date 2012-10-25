
require 'rubygems'
require 'rake'
require 'diary_model'
require 'chronic'

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
namespace :diary do 

DIR_ENVIRONMENT = ENV["DIARY_DIR"] || "work"
LOCATION = ENV["LOCATION"] || "work"

MAIN_DIRECTORY = ENV["HOME"] + "/Schedule/" + DIR_ENVIRONMENT + "/"
DBFILE = ENV["HOME"] + "/.notes.db"




def currentDay
  time = Time.new()
  MAIN_DIRECTORY + time.strftime("%Y/%b/%m_%d_%y.yml")
end

desc "First Task"
task :updateProject do |t|
  curfile = currentDay()
    ActiveSupport::Deprecation.silenced = true
    ActiveRecord::Base.establish_connection( :adapter => "sqlite3", :dbfile => DBFILE )
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
#  c = Category.find(:all, :conditions => ['name like ?','%iary%'] ).first
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
  # b.category = Category.find(:all, :conditions => ['name = ?',"task"] ).first
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
#  getTasks("diary").find_all { |i| i.entry =~ reg }.each { |i|
#  puts "Foo"
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
#  puts "Going to destroy this entry"
  connect()
#  d = getTasks("diary").last
#  puts d.entry
  d = getTasks( getDiary() ).last

  d.destroy
end

desc "List Tasks"
task :listTasks , [:numlist,:completed] do |t, args|
  args.default( :numlist => false )
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
  # begin
  #   args.completed = eval(args.completed)
  # rescue 
  #   args.completed = false
  # end
  #puts "HERE"
  args.completed = false
  args.numlist = false
  # if args.completed && args.numlist
  #   fn = Proc.new { |x|
  #     begin
  #       !x.completed? || ( x.completed? &&  x.completed >= Date.today )
  #     rescue
  #       false
  #     end
  #   }
  # else
  #   fn = Proc.new { |x|
  #     begin 
  #       !x.completed?
  #     rescue
  #       false
  #     end
  #   }
  # end
  connect()
  # puts "HERE !!!!"
  # c = Category.find(:all, :conditions => ['name = ?',"task"] ).first
  c = Category.find(:all, :conditions => ['name = ?', getTask() ] ).first

  entries = getTasks( getTask() ).find_all { |i|
    (!i.completed? ) || ( i.completed? && i.completed >= Date.today )
  }

  entry = entries.map {|i| "#{i.id}: #{i.entry}" }.join("\n")
  puts entry
end


def findTask(id)
  connect()
#  c = Category.find(:all, :conditions => ['name = ?',"task"] ).first
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
#  puts b.new_to_yaml("")
  b.destroy
end

desc "Mark a task as completed"
task :completeTask, [:taskID,:date] do |t,args|
  #args.with_defaults( :date => DateTime.now )
  completed_date = args.date
  if !completed_date.nil? 
    puts "Parsing"
    completed_date = Chronic.parse(args.date)
  else
    #puts "Assignined other"
    completed_date = DateTime.now()
  end
  #puts "This date is #{completed_date}"
  #puts "Date: #{DateTime.now()}"
  b = findTask( args.taskID )
  #puts "B is #{b.to_yaml}"
  b.completed = completed_date.to_datetime
  #b.completed = Time.now
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
#  c = Category.find(:all, :conditions => ['name = ?',"task"] ).first
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
                       :conditions => 
                       {:category_id => c.id }
            ).find_all { |j| 
               j.entry =~ regex and j.completed.nil?
            }
  return alltasks
end

def connect
  ActiveSupport::Deprecation.silenced = true
  ActiveRecord::Base.establish_connection( :adapter => "sqlite3", :dbfile => DBFILE )
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
  # c = Category.find(:all, :conditions => ['name = ?',"task"] ).first
  #puts "Anohter"
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
  #puts "HERE"
  retstring = getOnlyTasks
  # puts "HERE"
  c = Category.find(:all, :conditions => ['name = ?',"diary"] ).first
  retstring += "\n\njournal:\n"
  # getTasks("diary").find_all { |i|
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
#    retstring += tmp.to_yaml.sub(/^---/g,'')
    end
  }
  return retstring
end

end
