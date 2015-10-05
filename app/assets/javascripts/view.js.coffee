#= require op_popup

window.transaction_link_click = (obj,href=null)->
  href ||= obj.attr('href')
  if href.indexOf("?") == -1
    chr = '?'
  else
    chr = '&'
  $("iframe#form").attr('src', "#{href}#{chr}iframe=1")
  $("iframe#form").show()
  $("#iframe-form-close").show()
  $("body").addClass("noscroll")
  $("iframe#form").load ()->
    window.iframe_contents = $("iframe#form").contents()

# Bizonyos feltetelek eseten bezarja az iframe-et es ujratolti az oldalt.
# Ez utobbihoz nincs jogosultsaga egy iframe-nek, emiatt kell a foablak kontextusabol intezni.
window.iframe_form_watchdog = ()->
  if window.iframe_contents
    iframe_text = window.iframe_contents.find("body").text()
    if iframe_text == "created" or iframe_text == "updated" or iframe_text == "destroyed" or iframe_text == "cancelled"
      $("iframe#form").attr('src', '')
      $("iframe#form").hide()
      $("#iframe-form-close").hide()
      $("body").removeClass("noscroll")
      window.iframe_contents = null
      #clearInterval(iframe_form_watchdog)
      unless iframe_text == "cancelled"
        location.reload()

$( ->
  if not is_mobile()
    $("#template_by_category_id").change ()->
      if $(@).val()
        transaction_link_click($(@), $(@).attr('href').replace("-1", $(@).val()))
        $(@).find("option:selected").attr('selected', false)
        $(@).trigger('chosen:updated')

  #new OpPopup("tr", $(".op_popup"))
  $("a.edit").click (e)->
    transaction_link_click($(@))
    return false

  $(".new_transaction_templates a").click ()->
    transaction_link_click($(@))
    $(".templates_switch").click()
    return false

  $("a.new_transaction").click ()->
    transaction_link_click($(@))
    return false

  $('#iframe-form-close').click ()->
    $("iframe#form").attr('src', null).hide()
    $("#iframe-form-close").hide()
    $("body").removeClass("noscroll")
    return false

  setInterval(iframe_form_watchdog, 1000)

  $("button.ack").click (e)->
    href = $(@).attr('href')
    id = $(@).attr('data-id')
    success = (jqXHR, textStatus)->
      #console.log("ack successful #{id}: #{textStatus}")
      $("tr[data-id=#{id}]").removeClass("unacked")
      #$("table tr.latest_updated").removeClass('latest_updated')
      #$("tr[data-id=#{id}]").addClass("latest_updated")
    $.post(href, '', success, 'json')

  set_anchor = ()->
    # kell valami, maskepp ujratolti az oldalt
    anchor = "#"
#    if $(".new_transaction_templates").hasClass('float')
#      anchor += "#float"
#      if $(".new_transaction_templates").hasClass('top')
#        anchor += "#top"
#      if $(".new_transaction_templates").hasClass('hidden')
#        anchor += "#slideup"
    if not $(".fixed_header").hasClass('float')
      anchor += "#fixed"
    else
      if not $(".fixed_header").hasClass('top')
        anchor += "#bottom"
#      if not $(".new_transaction_templates").hasClass('hidden')
#        anchor += "#slidedown"
    if $("table").hasClass('debug')
      anchor += "#debug"
    window.location = window.location.toString().replace(/#.*/, '') + anchor

#  $(".float_switch").click ()->
#    $(".fixed_header").toggleClass('float')
#    set_anchor()
#  $(".float_top_switch").click ()->
#    $(".fixed_header").toggleClass('top')
#    set_anchor()
  $(".templates_switch").click ()->
    $(".new_transaction_templates").toggleClass('hidden')
    #set_anchor()
  $(".debug_switch").click ()->
    $("table").toggleClass('debug')
    set_anchor()

#  if window.location.href.indexOf("#float") > 0
#    $(".fixed_header").addClass('float')
#  if window.location.href.indexOf("#fixed") > 0
#    $(".fixed_header").removeClass('float')
#  if window.location.href.indexOf("#top") > 0
#    $(".fixed_header").addClass('top')
#  if window.location.href.indexOf("#bottom") > 0
#    $(".fixed_header").removeClass('top')
#  if window.location.href.indexOf("#slideup") > 0
#    $(".new_transaction_templates").addClass('hidden')
#  if window.location.href.indexOf("#slidedown") > 0
#    $(".new_transaction_templates").removeClass('hidden')
  if window.location.href.indexOf("#debug") > 0
    $("table").toggleClass('debug')

  $(".leftValues").chosen(search_contains: true)
)
