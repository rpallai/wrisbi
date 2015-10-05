module BusinessesHelper
  def businesses(treasury)
    Business.where(:treasury_id => treasury).map{|business| [ business.name, business.id ] }
  end
end
