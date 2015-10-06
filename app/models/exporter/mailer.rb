# encoding: utf-8
#
# Az exportalas nem tartja meg a tranzakcio eredeti strukturajat;
# a transaction-title paros egy row-ba lesz kombinalva.
#
# A row exportalasanak okai lehetnek:
# - category (un)bound
# - account (un)bound (XXX)
#
class Exporter::Mailer < Exporter
  def to
    self.cfg[:to] if cfg
  end
  def to=(value)
    self.cfg ||= {}
    self.cfg[:to] = value
  end
  def from
    self.cfg[:from] if cfg
  end
  def from=(value)
    self.cfg ||= {}
    self.cfg[:from] = value
  end

  def name
    to
  end

  def after_create_category_link(category_link)
    Exporter::Mailsender.category_bound(from, to, category_link).deliver
  end
  def after_destroy_category_link(category_link)
    Exporter::Mailsender.category_unbound(from, to, category_link).deliver
  end

  #~ elsif record.is_a? Operation
  #~ Exporter::Mailsender.export_account(from, to, record).deliver

  def after_title_update(title)
    Exporter::Mailsender.title_updated(from, to, title).deliver
  end

  def after_transaction_update(transaction)
    Exporter::Mailsender.transaction_updated(from, to, transaction).deliver
  end
end
