class Track < ActiveRecord::Base

  validates_presence_of :title, :description
  
  has_many :sessions
end