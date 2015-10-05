# encoding: utf-8
class CategoryLink < ActiveRecord::Base
  self.table_name = 'categories_titles'

  belongs_to :category
  belongs_to :title

  after_create  {|l| l.category.exporter.after_create_category_link(self) if l.category.exporter }
  after_destroy {|l| l.category.exporter.after_destroy_category_link(self) if l.category.exporter }
end
