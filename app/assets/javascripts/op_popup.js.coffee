#
# megjeleniti a popup-ot es az aktualis sor id-jevel
#
class window.OpPopup
  constructor: (data,popup)->
    unselect_all = ()->
      $("#{data}.selected").removeClass('selected')

    $("#{data}[data-id]").click (e)->
      #window.x_e = e
      #return if e.target.tagName == "A"
      #record = $(@).parentsUntil("tbody").last()
      record = $(@)

      id = record.attr('data-id')
      #console.log("id: #{id} this.height(): #{$(@).height()}")
      unselect_all()
      $(record).addClass('selected')
      popup.show().css(
        top: e.pageY + 20
        left: e.pageX - 20
      )
      # fix links
      popup.attr('data-id', id)
      if $(record).hasClass('unacked')
        popup.addClass('unacked')
      else
        popup.removeClass('unacked')
      for a in popup.find("a")
        a.href = $(a).attr('href_template').replace("-1", id)

    popup.find("a").click (e)->
      unselect_all()
      popup.hide()
    popup.find("button").click (e)->
      unselect_all()
      popup.hide()
