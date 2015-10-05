# encoding: utf-8
class Title::Deal < Title
  Op = {
    :head => 0,
    :share => 1
  }
  OpHead = 0
  OpShare = 1

  self.abstract_class = true

  # A cache-nek jobb az utobbi megoldas
  #has_one :head, :conditions => { :type_code => Head }, :foreign_key => 'title_id', :class_name => 'Operation'
  #has_many :legs, :conditions => { :type_code => Leg }, :foreign_key => 'title_id', :class_name => 'Operation'
  def head; operations.detect{|o| o.type_code == OpHead }; end
  def legs; operations.find_all{|o| o.type_code != OpHead }; end

  private
  def build_shares
    categories.each do |category|
      if business = category.applied_business
        business.shares.each{|bshare|
          shares.build(:person => bshare.person, :share => bshare.share)
        }
      end
    end
  end

  def find_head_account
		account
  end

  def get_amount_for_share
    amount
  end

  # az OpHead a shares alapjan kerul a szamlakra
  def multihead
    false
  end

  def build_operations
		shares.each_amount(get_amount_for_share) {|share, share_amount|
			if account_for_share = find_account_for_share(share)
				operations.update_or_build(account_for_share, OpShare, -share_amount)
			end
		}
    if multihead
      shares.each_amount(amount) {|share, share_amount|
        if account_for_share = find_head_account_for_share(share)
          operations.update_or_build(account_for_share, OpHead, share_amount)
        end
      }
    else
      operations.update_or_build(find_head_account, OpHead, amount)
    end
  end

  def build_tax_operations(opts)
    base = opts.delete :based_on
    account_get_method = opts.delete :to
    raise "Unknown option: "<<opts.inspect unless opts.empty?

    # az adoalap a ceg beltagjai kozott kerul leosztasra
    Share.each_amount(shares.find_all{|s| s.person.member? }, base) {|share, share_amount|
			operations.update_or_build(share.person.send(account_get_method), OpShare, share_amount)
    }
  end
end
