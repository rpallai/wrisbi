class Family::ViewController < ViewController
  add_template_helper(Family::TemplateHelper)

  def titles
    @order = 'transactions.date DESC'
    super
  end
end
