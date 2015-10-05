# encoding: utf-8
class Family::Account < Account
  Ut_bankszamla = 0
  Ut_megtak_kp = 1
  Ut_koltopenz = 2
  Ut_hitelkartya = 4
  Ut_keszpenz = 5
  Ut_segedszamla = 6

  # T_wallet
  St_bank = 0
  St_bank_creditable = 1
  St_cash = 2

  before_validation :xlate_type_user

  def self.possible_type_user
    {
      "Bankszámla" => Ut_bankszamla,
      "Megtakarítás készpénzben" => Ut_megtak_kp,
      "Költőpénz" => Ut_koltopenz,
      "Hitelkártya" => Ut_hitelkartya,
      "Készpénz követelés" => Ut_keszpenz,
      "Segédszámla" => Ut_segedszamla,
    }
  end
  def self.possible_type_user_disabled
    []
  end

  def xlate_type_user
    if @type_user
      case @type_user.to_i
      when Ut_bankszamla
        self.type_code = T_wallet
        self.subtype_code = St_bank
      when Ut_megtak_kp, Ut_koltopenz
        self.type_code = T_wallet
        self.subtype_code = St_cash
      when Ut_hitelkartya
        self.type_code = T_wallet
        self.subtype_code = St_bank_creditable
      when Ut_keszpenz
        self.type_code = T_cash
        self.subtype_code = 0
      when Ut_segedszamla
        self.type_code = T_auxiliary
        self.subtype_code = 0
      end
    end
  end

  def type_user
    if asset?
      return Ut_bankszamla if subtype_code == St_bank
      return Ut_megtak_kp if subtype_code == St_cash
      return Ut_hitelkartya if subtype_code == St_bank_creditable
    end
    if liability?
      return Ut_keszpenz
    end
    if auxiliary?
      return Ut_segedszamla
    end
    nil
  end


  def min_zero?
    asset? and not subtype_code == St_bank_creditable
  end

  def order_column
    'transactions.date'
  end
end
