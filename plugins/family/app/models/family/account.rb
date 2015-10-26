# encoding: utf-8
class Family::Account < Account
  # Ez egyben a sorrendet is meghatarozza a treasury#show -nal
  Ut_koltopenz = 0
  Ut_bankszamla = 1
  Ut_hitelkartya = 2
  Ut_keszpenztartalek = 3
  Ut_befektetes = 4
  Ut_elsz_keszpenz = 5
  Ut_segedszamla = 6

  # T_wallet
  St_bankszamla = 0
  St_hitelkartya = 1
  St_keszpenztartalek = 2
  St_befektetes = 3
  St_koltopenz = 4

  before_validation :xlate_type_user

  def self.possible_type_user
    {
      "Bankszámla" => Ut_bankszamla,
      "Készpénztartalék" => Ut_keszpenztartalek,
      "Költőpénz" => Ut_koltopenz,
      "Befektetés" => Ut_befektetes,
      "Hitelkártya" => Ut_hitelkartya,
      "Elszámolás készpénzben" => Ut_elsz_keszpenz,
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
        self.subtype_code = St_bankszamla
      when Ut_keszpenztartalek
        self.type_code = T_wallet
        self.subtype_code = St_keszpenztartalek
      when Ut_koltopenz
        self.type_code = T_wallet
        self.subtype_code = St_koltopenz
      when Ut_befektetes
        self.type_code = T_wallet
        self.subtype_code = St_befektetes
      when Ut_hitelkartya
        self.type_code = T_wallet
        self.subtype_code = St_hitelkartya
      when Ut_elsz_keszpenz
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
      return Ut_bankszamla if subtype_code == St_bankszamla
      return Ut_hitelkartya if subtype_code == St_hitelkartya
      return Ut_keszpenztartalek if subtype_code == St_keszpenztartalek
      return Ut_befektetes if subtype_code == St_befektetes
      return Ut_koltopenz if subtype_code == St_koltopenz
    end
    if liability?
      return Ut_elsz_keszpenz
    end
    if auxiliary?
      return Ut_segedszamla
    end
    nil
  end

  def type_user_s
    case type_user
    when Ut_bankszamla then "Bankszámla"
    when Ut_hitelkartya then "Hitelkártya"
    when Ut_keszpenztartalek then "Készpénztartalék"
    when Ut_befektetes then "Befektetés"
    when Ut_koltopenz then "Költőpénz"
    when Ut_elsz_keszpenz then "Elszámolás készpénzben"
    when Ut_segedszamla then "Segédszámla"
    end
  end


  def min_zero?
    asset? and not subtype_code == St_hitelkartya
  end

  def order_column
    'transactions.date'
  end
end
