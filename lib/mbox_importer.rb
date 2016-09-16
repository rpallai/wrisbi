require 'optparse'
require 'ostruct'
require 'net/imap'

def parse_options
  $options = OpenStruct.new
  $options.dry_run = false
  $options.one_shot = false
  $options.verbose = false
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"
    opts.separator ""
    opts.separator "Specific options:"

    opts.on("-n", "--dry-run", "") do
      $options.dry_run = true
    end
    opts.on("-o", "--one-shot", "") do
      $options.one_shot = true
    end
    opts.on("-v", "--verbose", "") do
      $options.verbose = true
    end
  end.parse!
end

def each_message(cfg, search)
  imap = Net::IMAP.new(cfg[:host], :port => 993, :ssl => true)
  imap.login(cfg[:login], cfg[:password])
  begin
    imap.examine(cfg[:folder])
    imap.select(cfg[:folder])
    n = 0
    imap.search(search).each do |message_id|
      msg = imap.fetch(message_id, "RFC822")
      if $options.dry_run
        imap.store(message_id, "-FLAGS", [:Seen])
      end
      mail = Mail.read_from_string(msg.first.attr['RFC822'])
      if mail.multipart?
        # az uj relayme trukkje
        body = mail.parts[0].body.decoded.force_encoding('UTF-8')
      else
        body = mail.body.to_s.force_encoding('UTF-8')
      end

      if $options.verbose
        i = 1
        body.lines.each do |l|
          puts "< #{l}"
          break if i == 2
          i += 1
        end
      end

      handled = yield(body,mail)

      if not $options.dry_run and handled
        puts "deleting..." if $options.verbose
        imap.store(message_id, "+FLAGS", [:Deleted])
      end

      if $options.one_shot and (n += 1) >= 10
        puts "exiting..."
        exit 1
      end
    end
  ensure
    imap.logout
  end
end

class XlateBankMsgFailed < Exception
end

#
# normalizalja, kiboviti az egyes mezoket
#
def xlate_bank_msg(foreign_id, date, op, amount, comment = '', payee_name = '')
  Rails.logger.debug "xlate_bank_msg> account_id: %s date: %s op: %s amount: %s payee_name: %s comment: %s" % [
    foreign_id, date, op, amount, payee_name, comment
  ]

  date = Date.parse(date)
  account = $treasury.accounts.foreign_id(foreign_id).first
  raise XlateBankMsgFailed, "Account by foreign_id (#{foreign_id}) not found" unless account
  amount = amount.delete('.').to_i
  comment.squeeze!(" ")

  Rails.logger.debug "xlate_bank_msg> date: %s account: %s amount: %s comment: %s" % [
    date, account.name, amount.inspect, comment.inspect
  ]

  return account, date, op, amount, comment, payee_name
end

def save_deal(account, date, amount, comment, categories, importer_id = nil, foreign_id = nil)
  t = $treasury.transactions.build(date: date, comment: comment, importer_id: importer_id, foreign_id: foreign_id)
  p = t.parties.build
  p.account = account
  p.amount = amount
  m = Family::Title::Deal.new(new_category_ids: categories.map(&:id))
  p.titles << m

  if $options.verbose
    puts "> #{date} #{amount} Ft @ #{account.name}"
    puts " #{comment}"
    puts " %s" % [categories.map{|c| c.ancestors.push(c).map(&:name).join('/') }.join(', ')]
  end

  success = true
  success = t.save unless $options.dry_run
  unless success
    puts t.errors.inspect
    puts t.parties[0].errors.inspect
    puts t.parties[0].titles[0].errors.inspect
    raise "Fuck." unless $options.dry_run
  end
end

def save_transfer(account_from, account_to, date, amount, comment, importer_id = nil, foreign_id = nil)
  t = $treasury.transactions.build(date: date, comment: comment, importer_id: importer_id, foreign_id: foreign_id)
  #
  p = t.parties.build
  p.account = account_from
  p.amount = amount
  m = Title::TransferHead.new
  p.titles << m
  #
  p = t.parties.build
  p.account = account_to
  p.amount = -amount
  m = Title::TransferHead.new
  p.titles << m

  if $options.verbose
    puts "> #{date} #{amount} Ft @ #{print_account(account_from)} => #{print_account(account_to)}"
    puts " #{comment}"
  end

  success = true
  success = t.save unless $options.dry_run
  unless success
    puts t.errors.inspect
    puts t.parties[0].errors.inspect
    puts t.parties[0].titles[0].errors.inspect
    puts t.parties[1].errors.inspect
    puts t.parties[1].titles[0].errors.inspect
    raise "Fuck." unless $options.dry_run
  end
end

def update_foreign_balance(account, balance)
  account.update(:foreign_balance => balance.delete('.').to_i)
end

def find_category(path)
  category = nil
  categories = $treasury.categories.roots
  path.split('/').each do |name|
    unless name.blank?
      category = categories.find_by_name(name)
      categories = category.children
    end
  end
  return category
end

def print_account(account)
  account.person.name+'/'+account.name
end
