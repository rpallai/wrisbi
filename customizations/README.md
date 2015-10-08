# Testreszabás kincstáranként

A kincstárak HTML sablon és CSS stílus fájljai tartoznak ide.

# HTML sablonok

A sablonok tetszőleges HTML kódot tartalmazhatnak, különbség abban van, hogy hol jelennek meg:

- Headline: A felső csíkon állandóan látható tartalom. Praktikus a fontosabb egyenlegek megjelenítésére, de 1-2 tranzakció sablon is kerülhet ide.
- Transactions: A "Templates" gomb klikkelésére bukkan fel. Ide jó sok tranzakció sablon elfér.

A tranzakció űrlapon belül is jelenik meg HTML sablon, amivel a tételek felvitelét könnyítheted meg:

- Titles: az "új tétel hozzádása" alatt jelenik meg. A gyakran hozzáadandó tételek sablonja.

# Tranzakció sablon

A tranzakció sablon nagyon fontos elem a használhatóság és a beviteli hibaarány csökkentése érdekében. A tranzakció sablonban rögzítve van a új tranzakció szerkezete és a mezők értéke. Természetesen bármi átállítható, hiszen ez csak a kezdeti állapotot adja. Minden tranzakció szerkezetet és értéket le tud írni.

A következő sablon a "Tárca" nevű számlához csatol egy +- tételt. Az `invert: 1` hatására az űrlap az összeg mezőbe írt számot fordított előjellel rögzíti (kényelmi extra, hogy a kiadásoknál ne kelljen állandóan minuszt gépelni).

> ```
link_to("Eltapsolás tárcából", new_family_treasury_transaction_path(@treasury, :p => {
  invert: 1,
 :parties_attributes => { '0' => {
   :account_id => @treasury.person_of_user(@current_user).accounts.find_by_name('Tárca'),
   :titles_attributes => { '0' => {
     type: Family::Title::Deal
   }}
 }}
}), class: 'new_transaction')
```

# Tétel sablon

A következő sablon egy +- tételt csatol a tranzakció űrlaphoz `Vendéglátás/Szalmonella büfé` kategóriával. A `new_title_attributes` az a rész ahol szabadon lehet játszani, a többi kötött.

> ```
<%= link_to("Szalmonellázás",
  polymorphic_url([:build_new_title, current_namespace, @transaction],
     party_idx: party_idx
     new_title_attributes: {
       :type => 'Family::Title::Deal',
       category_ids: [@treasury.categories.find_by_name('Vendéglátás').children.find_by_name('Szalmonella büfé')]
     },
   ), class: 'build_new_title') %>
```

# Mappaszerkezet

* customizations/
  * {*kincstar_neve*}/
    * stylesheets/
      * {*xyz*}.scss
    * templates/
      * _{*current_user*}_headline.html.erb
      * _{*current_user*}_transactions.html.erb
      * _{*current_user*}_titles.html.erb
      * _everybody_transactions.html.erb

# Éles példa: Headline

- Kincstár: teszt
- Felhasználó: teszt@nincsilyen.hu

A felső csíkon állandóan látható lesz a "Tárca" nevű számla egyenlege és mellette lesz két tranzakció sablon link: egyik a kiadáshoz, másik az átvezetéshez. A `family_new_deal()` és `family_new_transfer()` helperek [itt vannak](../plugins/family/app/helpers/family/template_helper.rb).

`customizations/teszt/templates/_teszt@nincsilyen.hu_headline.html.erb`
> ```
<span class="account">
  <% account = @treasury.person_of_user(@current_user).accounts.find_by_name('Tárca') -%>
  Tárca <span class="balance">/<%= print_amount account.balance -%>/</span>
  <% if controller_name == "view" %>
    <%= family_new_deal account %>
    <%= family_new_transfer account %>
  <% end %>
</span>
```

Az `if controller_name == "view"` hatására a sablon linkek csak akkor jelennek meg, ha a könyvelési adatok láthatóak a képernyőn. Felvinni ugyanis olyan nézetben érdemes, ahol a tranzakció azonnal látszani is fog: így az esetleges hiba kiszúrható még melegében.

## Napi büdzsé

Ha hónapról hónapra élsz, akkor hasznos lehet egy olyan fejléc, ahol mindig látható, hogy:
- mennyi a napi költségkeretem
- ebből mennyit költöttem el
- mennyi pénzem van még a hónapra
- hány nap van még hónap végéig (következő fizetésig)

Természetesen az előző fejezetben bemutatott fájl bővítésével könnyedén megoldható:
> ```
<br/>
<%
  fizetesnap = Date.today.at_beginning_of_month.next_month + 4   # +4, azaz 5-en
  penznem = 'HUF'
  vizsgalt_szamlak = @treasury.accounts.where(
    currency: penznem,
    type_code: Account::T_wallet,
    # Csak a likvid számlák számítanak "költőpénznek", a megtakarítások, hitelkártya nem
    subtype_code: [Family::Account::St_bankszamla, Family::Account::St_koltopenz]
  ).map(&:id)
%>
<% rows = Account.where(id: vizsgalt_szamlak).joins(:operations => :transaction) %>
<% spending_rows = rows.where("titles.type = 'Family::Title::Deal'").where("operations.amount < 0") %>
<% koltopenzem = rows.sum('operations.amount') %>
költőpénzem: <%= koltopenzem %> <%= penznem %>,
<% napok_fizetesig = (fizetesnap - Date.today).to_i %>
napok fizetésig: <%= napok_fizetesig %>,
napi költségkeret: <%= koltopenzem / napok_fizetesig %> <%= penznem %>,
<% mai_koltes = -spending_rows.where('transactions.date = CURDATE()').sum('operations.amount') %>
mai költés: <%= mai_koltes %> <%= penznem %>,
<% tegnapi_koltes = -spending_rows.where('transactions.date = CURDATE()-1').sum('operations.amount') %>
tegnapi költés: <%= tegnapi_koltes %> <%= penznem %>.
<% if mai_koltes > koltopenzem / napok_fizetesig %>
  <%= link_to("Bevásárlólistám", 'https://www.google.hu/search?&q=vizes+zsemle') %>
<% end %>
```

A fentivel a napi költésbe az is beleszámít ha kölcsönadsz (már ha követed a [family plugin](../plugins/family/README.md) ajánlását az esetre). A bevétel nem tompítja a napi költést, csak a költőpénz mennyiségét növeli, ezáltal a napi keretet növeli.

Bizonyos kategóriákat ki tudsz venni a napi költésből. A következő kód beszúrása pl a `/Hitel/*` kategóriás tételeket kihagyja a napi költés számításából:
>```
<% spending_rows = spending_rows.includes(:operations => { :title => :categories }).
  where('categories.id NOT IN (?)', find_category(@treasury, '/Hitel').children.ids) %>
```

És mindezt még tovább lehet csűrni-csavarni, SQL-lel nincs akadály!
