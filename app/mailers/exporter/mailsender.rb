class Exporter::Mailsender < ActionMailer::Base
  add_template_helper(ViewHelper)
  add_template_helper(AccountsHelper)

  def category_bound(from, to, category_link)
    @category_link = category_link
    title = category_link.title
    @title = title
    @categories = title.categories.map{|category| category.ancestors.push(category).map(&:name).join('/') }.join(',')
    mail(to: to, from: from,
      subject: "Category \"#{view_context.print_category(category_link.category, false)}\" bound to #{title.amount} @ "+
        "#{title.party.account.person.name+'/'+title.party.account.name} "+
        "(#{title.comment};#{title.transaction.comment})"
    )
  end
  def category_unbound(from, to, category_link)
    @category_link = category_link
    title = category_link.title
    @title = title
    mail(to: to, from: from,
      subject: "Category \"#{view_context.print_category(category_link.category, false)}\" unbound from #{title.amount} @ "+
        "#{title.party.account.person.name+'/'+title.party.account.name} "+
        "(#{title.comment};#{title.transaction.comment})"
    )
  end

  def title_updated(from, to, title)
    @title = title
    mail(to: to, from: from, subject: "Row updated")
  end
  def transaction_updated(from, to, transaction)
    @transaction = transaction
    mail(to: to, from: from, subject: "Row updated")
  end

  #~ def export_account(from, to, operation)
  #~ @operation = operation
  #~ @title = operation.title
  #~ mail(to: to, from: from)
  #~ end
end
