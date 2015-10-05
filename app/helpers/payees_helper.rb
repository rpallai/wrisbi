module PayeesHelper
  def treasury_payees(treasury)
    treasury.payees.all.map{|p| [ p.name, p.id ]}.push(['egyeb', -1]).unshift(['nincs', nil])
  end
  
  def print_payee(payee)
		return unless payee
		payee.name
  end
  
  def payees(treasury)
		Payee.where(:treasury_id => treasury).map{|payee| [ payee.name, payee.id ] }
  end
end
