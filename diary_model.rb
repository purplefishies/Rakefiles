

require 'rubygems'
gem 'rails', '3.0.9'
gem 'activerecord', '3.0.9'
require 'active_record'
#gem 'activerecord' , '2.3.11'
#gem 'activerecord','2.3.9'
#gem 'activerecord','2.3.11'
#ActiveSupport::Deprecation.silenced = true
#gem 'rails' , '2.3.9'
#gem 'rails', '3.0.9'



class Task  < ActiveRecord::Base
  has_many :tags_tasks
  has_many :tags, :through => :tags_tasks
  belongs_to :category , :foreign_key => :category_id
  has_one :task, :foreign_key => :id

  # New for the hierarchical nature
  has_many :parent_child_relationships, :class_name => "ParentRelationship", :foreign_key => :parent_id, :dependent => :destroy
  has_many :parents, :through => :parent_child_relationships, :source => :child

  has_many :child_parent_relationships, :class_name => "ParentRelationship", :foreign_key => :child_id, :dependent => :destroy
  has_many :children, :through => :child_parent_relationships, :source => :parent

  #
  # My customized indentation
  #
  def new_to_yaml(indent)
    retstring = ""
    starter   = "  "

    retstring = "#{indent}#{starter}- item: #{self.entry}\n"
    retstring += "#{indent}#{starter}  due:  #{self.due}\n"
    retstring += "#{indent}#{starter}  exp:  #{self.expcomplete}\n"
    if !self.completed.nil?
      retstring += "#{indent}#{starter}  completed: #{self.completed}\n"
    end
    if self.children
      retstring +=  "#{indent}#{starter * 2}tasks:\n"
      self.children.each { |child|
        tmpindent = indent + "    "
        retstring += child.new_to_yaml( tmpindent )
      }
    end
    return retstring
  end

end



class ParentRelationship < ActiveRecord::Base
  belongs_to :parent, :class_name => "Task"
  belongs_to :child, :class_name => "Task"
end

#  has_many :children, :through => :parent_children
#  has_one :category, :foreign_key
#class Type < ActiveRecord::Base
#  has_and_belongs_to_many :tasks
#  belongs_to :tasks
#end
class Category < ActiveRecord::Base
#  belongs_to :categorical, :foreign_key => :id
#  has_many :tasks, :foreign_key => :id
end

#
#
# Note that the 
class Tag < ActiveRecord::Base
  has_many :tags_tasks
  has_many :tasks, :through => :tags_tasks
end

##
# The table has to have a plural version
# of this naming convention
##
class TagsTask < ActiveRecord::Base
  belongs_to :tag
  belongs_to :task
end

class ParentChild < ActiveRecord::Base
  belongs_to :task
  belongs_to :task
end
