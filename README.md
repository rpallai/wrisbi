# Wrisbi
Simple and expandable multi-user accounting software for the web backed by SQL.

Features:

- Ruby on Rails
- Multi-treasury
- Multi-user with access control
- Plugin support to map your own complex business
- Accounts are grouped by people
- Categories with shares (eg to handle cash payments in a common business)
- Categories with exporters (email)
- Customization of treasuries (CSS, HTML templates)
- Easy to write new importers
- Responsive design, mobile support

It can act like a simple and dumb personal accounting software but you can do much more if getting familiar with plugins, shares, exporters and importers.

# Install
Basic requirements:
- Ruby 1.9.3 or newer
- SQL server (only tested with MySQL)

1. `$ git clone https://github.com/rpallai/wrisbi.git`
2. `$ cd ./wrisbi`
3. Create `config/database.yml` config file based on `config/database.yml.example`
4. Create the database, grant access
5. Set your RAILS_ENV environment variable to development or production. Choose the first if you want to develop.<br/>
`$ export RAILS_ENV={development|production}`
6. `$ bundle`                  # install gem dependencies
7. ``$ echo "Wrisbi::Application.config.secret_key_base = '`rake secret`'" >config/initializers/secret_token.rb``
8. `$ rake db:schema:load`
9. `$ rake plugins:migrate`
10. `$ rake user:create_root`
11. `$ test $RAILS_ENV == production && bundle exec rake assets:precompile`
12. `$ rails s -p 3003` #( 3003 is the http port number, you can choose another one)
13. Open in your browser: http://server:3003/

Uninstall a plugin:

1. `$ export RAILS_ENV={development|production}`
2. `$ NAME=<plugin_name> VERSION=0 rake plugins:migrate`

# Alapok, adatmodell (HU)

## Kincstár
A kincstár (treasury) egy könyvelési entitás. Minden elem (kivéve a felhasználókat) kincstár alá van rendelve. Minden kincstárnak van egy típusa (pl család), ami meghatározza az elérhető műveleteket, a személyek lehetséges szerepét, számláik lehetséges típusát. A kincstárak típusait a pluginek adják. A fent említett család is egy plugin, ami benne az alapcsomagban.

A kincstár alá tartoznak:
- tranzakciók
- kategóriák
- egyezségek
- személyek
  - számlák
- exporterek

### Tranzakció
Egy könyvelési esemény. Bővebben lásd lentebb.

### Kategória
A kategóriák célja:
- statiszikai, követni az adott kategória alá tartozó egyenleg időbeli alakulását
- a kapcsolódó egyezségen át a személyekre vetített részesedések meghatározása a tétel alapján

A kategóriák fa-struktúrába szervezhetőek.

A kategóriához kapcsolható (email) exporter, ami minden a kategória alatt történt változásról emailt küld a kijelölt címre.

### Személy/számla
Egy természetes, jogi vagy egyéb szereplő, akihez legalább egy számla kapcsolódik.

A számlák típusát és szerepét a kincstár határozza meg, lásd a vonatkozó plugin dokumentációját.

### Felhasználó
Be tud lépni a rendszerbe. Ha root, treasury supervisor vagy össze van kapcsolva egy személlyel, akkor az érdekeltségébe tartozó kincstárba is beléphet. Ha korlátozott, akkor ott csak a saját egyenlegét követheti.

## Tranzakció
Egy tranzakció némileg leegyszerűsítve így néz ki:

* idő
* megjegyzés
* fél (1..*)
  * összeg
  * számla
  * tétel (1..*)
    * összeg
    * megjegyzés
    * kategória (0..*)
      * egyezség
      * exporter
    * művelet (1..*)
      * összeg
      * számla

### Fél
A fél egy kincstári személy valamelyk számlája. A számla egyenlegét nem befolyásolja, arra csak a tétel képes, lásd lentebb.

### Tétel
Legfontosabb feladatai:

* Műveletek létrehozása, amivel a számlák egyenlege változtatható
* Kapcsolódó kategóriák tárolása, az azokon szereplő egyezségek és exporterek alkalmazása

Egy tétel az egyszerű átvezetéstől több személy több számláját érintő műveletig terjedhet. Ez utóbbira egy családban nemigen van példa, de ha mondjuk egy vállakozásban akarod monitorozni az egyes osztályok pénzügyi teljesítményét/állapotát, akkor hamar szembesülsz olyan tétellel ami olyan számlákat érint egyszerre mint: adóalapok, részesedés, házipénztár. Egy plugin által felbővített tétellel ezek a bonyolult számítások elvégezhetőek minimális user input-ból.

### Művelet
Ez változatja a számla egyenlegét. Ezzel a végfelhasználó nem találkozik, a tétel használja őket.

# Exporter
A kincstárban történt könyvelési eseményeket lehet vele exportálni. Ez például használható arra, hogy azonnal értesüljön az ismerősöd ha felírtál hozzá egy tartozást vagy hogy egy másik Wrisbi automatikusan importálja.

Az email exporter nem tartja meg a tranzakció-tétel eredeti strukturáját: sort képez belőle, ami egyszerűbb, az ember hamarabb megérti, a belátható igényeknek így is bőven megfelel.

Egyelőre csak kategóriához kapcsolható.

# Kincstárak, gyakorlati példák
* [Family plugin](plugins/family/README.md)
