Kincstarankenti testreszabas

customizations/
 <kincstar_neve>/
  stylesheets/
   <xyz>.scss
  templates/
   _<current_user>_headline.html.erb
   _<current_user>_transactions.html.erb
   _<current_user>_titles.html.erb
   _everybody_transactions.html.erb

_<current_user>_headline.html.erb
 A felso csikon megjeleno tartalom. Praktikus lehet a legfontosabb egyenlegek megjelenitesere.

_<current_user>_transactions.html.erb
_everybody_transactions.html.erb
 A doboz tartalma ami a "Templates" gombra bukkan fel. Tipikusan a tranzakcio template-ek kerulnek ide.
 Az utobbi template minden felhasznalonal lathato.

_<current_user>_titles.html.erb
 Linkek, amik az "uj tetel hozzadasa" alatt jelennek meg.

A stylesheets/.(s)css fajlban testre szabhatod a teljes lap megjeleneset, beleertve a fenti
template-eket.
