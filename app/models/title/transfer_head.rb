# encoding: utf-8
class Title::TransferHead < Title
  Op = {
    :head => 0
  }
  OpHead = 0

  def self.display_name
    "Átvezetés"
  end

  private
  def build_operations
    operations.update_or_build(account, OpHead, amount)
  end
end
