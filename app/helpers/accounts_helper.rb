# encoding: utf-8
module AccountsHelper
  def accounts_to_options(accounts)
    accounts.map{|account| [account.name, account.id]}
  end
  
  def print_account(account)
    account.person.name+'/'+account.name
  end
end
