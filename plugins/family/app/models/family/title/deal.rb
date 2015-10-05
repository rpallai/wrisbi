# encoding: utf-8
class Family::Title::Deal < Title::Deal
  def self.display_name
    "+-"
  end

  private
  def find_account_for_share(share)
    share.person.first_cash_account_in(account.currency) if account
  end
end
