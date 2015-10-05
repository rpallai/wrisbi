# encoding: utf-8
class BasicShare < ActiveRecord::Base
  validates :share, :presence => true
  validate :validate_share, :if => :share

  self.abstract_class = true

  def to_s
    "%s[%s]" % [person.name, share]
  end

  def is_ratio?
    share.starts_with? ':'
  end
  def ratio
    if is_ratio?
      share[1..-1].to_i
    end
  end

  def is_expression?
    is_ratio?
  end

  private
  def validate_share
		#
		# Q: miert tamogatunk kizarolag aranyszamot?
		# A1: %-nal, tortnel kezelni kene, ha az osszeg nem adja ki az 1-et, aranyszamnal pedig ilyen gond nincs.
		# A2: %-nak esetleg annyi haszna lenne, hogy a hibas inputot ki lehet szurni vele, de a kezi share bevitel
    #     amugy sem nem jellemzo.
		#
    if not is_ratio?
      errors.add(:share, "Csak arányszám lehet")
    elsif ratio <= 0
      errors.add(:share, "Csak pozitív szám lehet")
    end
  end
end
