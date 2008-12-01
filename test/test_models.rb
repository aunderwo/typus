class User < ActiveRecord::Base
  
end

class Person < ActiveRecord::Base

end

class Tag < ActiveRecord::Base
  
end

class Page < ActiveRecord::Base

  has_many :assets, :as => :assetable, :dependent => :destroy

  def self.admin_order_by
    [ 'status' ]
  end

  def self.admin_search
    [ 'title', 'body' ]
  end

  def self.admin_filters
    [ 'status', 'created_at' ]
  end

  def self.admin_actions_for_index
    [ 'rebuild_all' ]
  end

  def self.admin_actions_for_edit
    [ 'rebuild' ]
  end

  def self.admin_fields_for_list
    [ 'title' ]
  end

  def self.admin_fields_for_form
    [ 'title', 'body' ]
  end

end

class Asset < ActiveRecord::Base

  belongs_to :assetable, :polymorphic => true

end

class Post < ActiveRecord::Base

  validates_presence_of :title, :body
  has_and_belongs_to_many :categories
  has_many :comments
  belongs_to :user
  has_and_belongs_to_many :tags

  def self.typus
    "plugin"
  end

  def self.status
    %w( pending published unpublished )
  end

  def to_label
    "Labeled post"
  end

end

class Category < ActiveRecord::Base

  acts_as_list if defined? ActiveRecord::Acts::List

  validates_presence_of :name
  has_and_belongs_to_many :posts

  def self.typus
  end

end

class Comment < ActiveRecord::Base

  validates_presence_of :name, :email, :body
  belongs_to :post

end