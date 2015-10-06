# new/edit
$( ->
  #
  # uj split;
  # ilyenkor submit-eljuk a form-ot, a link parameterei alapjan egy uj title-rel
  # gazdagabban ter vissza
  #
  $('a.new_title').click ()->
    href = $(@).attr('href')
    action_ref = $('form').attr("action")
    $('form').attr("action", action_ref+href)
    $('form').submit()
    return false
  build_new = ()->
    href = $(@).attr('href')
    $('form').attr("action", href)
    $('form').submit()
    return false
  $('a.build_new_party').click build_new
  $('a.build_new_title').click build_new
  $('a.copy_title').click build_new
  $('a.refresh').click build_new

  $('input.destroy').change ()->
    $('a.refresh').click()
  $("select.account").change ()->
    $('a.refresh').click()
  $("select.title_type").change (e)->
    href = $(e.target).attr('href').replace("TYPE_TEMPLATE", $(e.target).val())
    $('form').attr("action", href)
    $('form').submit()

  # ctrl+q: iframe bezarasa
  # siman esc-re nem jo bindelni, mert a desktop hotkey-eket is elkapja
  ctrlKey = 17
  theKey = 81
  $("body").keydown (e)->
    window.ctrlDown = true if e.keyCode == ctrlKey
  $("body").keyup (e)->
    window.ctrlDown = false if e.keyCode == ctrlKey
  $("body").keydown (e)->
    if window.ctrlDown && e.keyCode == theKey
      $("body").text('cancelled')

  #
  # a komment alapvetoen kerulendo;
  # szemmel kell grepelni, statisztikaba nem vonhato be, azzal is probaljuk oket megfekezni,
  # hogy alapesetben a komment mezot elrejtjuk
  #
  $('.title.comment').click ()->
    $(@).next().toggle()
  $('.transaction.comment').click ()->
    $(@).next().toggle()

#  $('select.payee_id').change ()->
#    if $('select.payee_id option:selected').val() == "-1"
#      $('input.payee_name').show()
#    else
#      $('input.payee_name').hide()

  # felo hogy tobb bajt okoz mint hasznot
#  $('#transaction_date_1i').change (e)->
#    $("select.title_date:nth(0)").val($(e.target).val())
#  $('#transaction_date_2i').change (e)->
#    $("select.title_date:nth(1)").val($(e.target).val())
#  $('#transaction_date_3i').change (e)->
#    $("select.title_date:nth(2)").val($(e.target).val())

  $(".leftValues").chosen(search_contains: true)

  #$("#transaction_date_3i").focus()
#  $('form:not(.from_template) .parties.account_id_changed input.amount').focus()
#  $(".party.empty_account .account").focus()
#  $($('.title.new_title select.leftValues')[0]).trigger('chosen:open')
)
