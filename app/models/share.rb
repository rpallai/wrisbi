# encoding: utf-8
class Share < BasicShare
  Scale = 0

  self.table_name = 'shares'

  belongs_to :title
  belongs_to :person

  validates :person_id, :uniqueness => { :scope => :title_id }

  #
  # Szamszerusiti a kifejezessel megadott reszesedest a base alapjan.
  # Lehet, hogy minden reszesedes eleve konkret szam, ilyenkor lehet a base nil.
  #
  # Kerekitunk; inkabb itt, mint kontrollalatlan korulmenyek kozott.
  # Ennek mar csak olyan pontossagot szabad kiengednie, amit minden lekezel.
  #
  # Az esetleges maradeknal nil share-rel yield-del.
  #
  def self.each_amount(shares, base, opts = {})
    remainder_to = opts.delete(:remainder_to)
    #reserve = opts.delete(:reserve) || 0
    raise "Unknown option: "<<opts.inspect unless opts.empty?
    #
    # Csak akkor avatkozik be, ha a fenntartott reszt is elhappolnak
    #
    #for_share = base - reserve
    # XXX for_share = base - sum(Fixnumz)
    for_share = base

    if shares.any?(&:is_ratio?)
      # TODO mit kezd a nil-el ha Number..?
      total_ratio = shares.to_a.sum(&:ratio)
    end
    left = base
    shares_left = shares.length
    # mindig az utolso emberen korrigalunk, az emberek sorrendje ezert random
    shares.shuffle.each {|share|
      if share.is_a? Numeric
        amount = share
      elsif share.is_ratio?
        amount = for_share * share.ratio / total_ratio
      else
        amount = share.share.to_f
      end

      if Scale > 0
        amount = sprintf("%.#{Scale}f" % amount).to_f
      else
        amount = amount.round
      end

      left -= amount
      shares_left -= 1
      if shares_left.zero? and left.nonzero?
        # ha ennel nagyobb a difi, akkor biztos az inputtal van baj
        if left.abs <= shares.length
          logger.debug "Share rounding: left=#{left}; giving it to #{share.person.name}"
          amount += left
          left = 0
        end
      end
      # a kerekites miatt elofordulhat
      next if amount.zero?

      yield(share, amount)
    }
    if left.nonzero? and remainder_to
      yield(Share.new(:person => remainder_to, :share => left), left)
    end
  end
end
