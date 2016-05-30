# encoding: utf-8
#
# Key-value store, amibe az importerek letehetik az allapotukat.
#
# Hasznos peldaul az import offset tarolasahoz, hogy tudjuk meddig importaltunk:
#
#  import_scope = ...
#  istate_szamlazo_offset = ImporterState.find_or_initialize_by(key: 'szamlazo_offset')
#  import_scope = scope.where("szamfej_id > ?", istate_szamlazo_offset.value.to_i) unless istate_szamlazo_offset.new_record?
#  import_scope.each do |szamla|
#    istate_szamlazo_offset.update!(value: szamla.szamfej_id)
#  end
#
class ImporterState < ActiveRecord::Base
  validates :key, presence: true, uniqueness: true
  validates :value, presence: true
end
