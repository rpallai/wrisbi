#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../config/environment'
require 'mbox_importer'

parse_options

cfg = {
  host: "imap.gmail.com",
  login: "dopeman@gmail.com",
  password: "bitchez",
  folder: "hc/sms",
}

puts "--- #{$0} import!" if $options.verbose

$treasury = Treasury.find(1)

each_message(cfg, ["SUBJECT", "36209400700", "UNSEEN"]) do |body,mail|
  handled = false

  begin
    if /(......) ..:.. (ATM készpénz felvét\/z.rol.s): ([\-\.\d]+) HUF; (.*); K.rtyasz.m: ...(\d+); Egyenleg: ([\-\.\d]+) HUF/.match(body)
      date = $1; op = $2; amount = $3; place = $4; card_id = $5
      balance = $6
      account, date, op, amount, place = xlate_bank_msg(card_id, date, op, amount, place)
      save_transfer(account, $treasury.people.find_by_name("Dopeman").accounts.find_by_name("Wallet"),
        mail.date, amount, "#{place} #{card_id}")
      handled = true

    elsif /OTPdirekt .* Jòvàhagyàs/.match(body)
      puts "* Jòvàhagyàs" if $options.verbose
      handled = true

    elsif /NEM TELJESÜLT/.match(body)
      puts "* NEM TELJESÜLT" if $options.verbose
      handled = true

    else
      puts "! Failed to parse the message of the bank" if $options.verbose

    end
    puts if $options.verbose
  rescue XlateBankMsgFailed => e
    puts e.inspect
  end

  handled
end
