# encoding: utf-8
require 'open-uri'

class ExchangeRateLog < ActiveRecord::Base
  validates_uniqueness_of :date, scope: :currency

  def self.pull(currency)
    doc = Nokogiri::HTML(open('http://www.mnb.hu/arfolyamok').read)
    eurhuf = doc.at(".mnbtable tbody td:contains('#{currency}') ~ td[3]").inner_text.tr(',','.').to_f
    create!(
      :date => Date.today,
      :currency => currency,
      :rate => eurhuf
    )
  end

  def self.pull_all()
    imported = 0
    ['EUR'].each do |currency|
      if where(:currency => currency, :date => Date.today).count.zero?
        pull currency
        imported += 1
      end
    end
    imported
  end
end
