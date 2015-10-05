#
# itt szurjuk ki azokat a szamlakat a tablazatbol amire nincs jogosultsaga
# a juzernek
#
module TitlesHelper
  def transfer_head_direction(transfer_head)
    transfer_head.amount > 0 ? '<' : '>'
  end

#  def each_account_of_persons_of_treasury(treasury)
#		# ebben taroljuk, hogy melyk oszlop melyk account;
#		# kell a tablazat soronkenti legyartasahoz, ld. lentebb
#		@index_account = []
#		@column_classes = []
#		i = 0
#		treasury.people.includes(:accounts).each do |person|
#			accounts = []
#			person.accounts.each do |account|
#				next if account.hidden? and not treasury.supervisors.include? @current_user
#				@index_account[i] = account.id
#				@column_classes[i] = "tc_" << account.type_code.to_s
#				i += 1
#				accounts << account
#			end
#			yield person, accounts unless accounts.empty?
#		end
#  end
#
#  def each_account_column(title)
#    operations_by_account_id = title.operations.group_by(&:account_id)
#    @index_account.length.times do |i|
#      account_id = @index_account[i]
#      operations = operations_by_account_id[account_id] || []
#      yield operations, i
#    end
#  end
end
