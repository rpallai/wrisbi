module TransactionsHelper
  def active_parties_of(transaction)
    transaction.parties.find_all{|p| not p.marked_for_destruction? }
  end

  def title_input_attributes(title)
    title.marked_for_destruction?? {disabled: 'disabled'} : {}
  end
end
