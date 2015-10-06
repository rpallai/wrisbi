# Testreszabás kincstáranként

* customizations/
  * {*kincstar_neve*}/
    * stylesheets/
      * {*xyz*}.scss
    * templates/
      * _{*current_user*}_headline.html.erb
      * _{*current_user*}_transactions.html.erb
      * _{*current_user*}_titles.html.erb
      * _everybody_transactions.html.erb

**_{current_user}_headline.html.erb**<br/>
A felső csíkon megjelenő tartalom. Praktikus lehet a legfontosabb egyenlegek megjelenítésére.

**_{current_user}_transactions.html.erb, _everybody_transactions.html.erb**<br/>
A doboz tartalma ami a "Templates" gombra bukkan fel. Tipikusan a tranzakció template-ek kerülnek ide. Az utóbbi template minden felhasznalónal látható.

**_{current_user}_titles.html.erb**<br/>
Linkek, amik az "új tétel hozzádása" alatt jelennek meg.

A `stylesheets/.(s)css` fajlban testreszabhatod a teljes lap megjelenését, beleértve a fenti template-eket.
