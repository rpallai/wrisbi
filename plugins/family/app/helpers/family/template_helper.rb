# encoding: utf-8
module Family::TemplateHelper
  def family_new_deal(account)
    link_to("⇩", new_family_treasury_transaction_path(@treasury, :p => {
      invert: 1,
      :parties_attributes => { '0' => {
          :account_id => account,
          :titles_attributes => { '0' => {
              type: Family::Title::Deal
          }}
      }}
    }), class: 'new_transaction')
  end

  def family_new_transfer(account)
    link_to("⇒", new_family_treasury_transaction_path(@treasury, :p => {
      :parties_attributes => {
        '0' => {
          :account_id => account,
          :titles_attributes => { '0' => {
              type: Title::TransferHead
          }}
        },
        '1' => {
          :titles_attributes => { '0' => {
              type: Title::TransferHead
          }}
        }
      }
    }), class: 'new_transaction')
  end
end
