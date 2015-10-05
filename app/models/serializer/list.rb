#
# Serializer, ami space-szel elvalasztott ertekeket kereshetove tesz SQL-ben.
#
# Hasznalat:
#
#  class Some < ActiveRecord::Base
#    serialize :foreign_ids, ::Serializer::List.new
#    scope :foreign_id, proc{|id|
#      where("foreign_ids LIKE '%%-%s-%%'" % ActiveRecord::Base.connection.quote_string(id))
#    }
#  end
#
class Serializer::List
	def initialize(opts = {})
		@separator = opts.delete(:separator) || ' '
		raise "Unknown options: " << opts.inspect unless opts.empty?
	end

	def load(text)
		text.split('-').map{|v| v.blank? ? nil : v }.compact.join(@separator) rescue ''
	end

	def dump(text)
		text.split(@separator).map{|id| "-#{id}-" }.join rescue ''
	end
end
