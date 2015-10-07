# Family plugin

Kiadások, bevételek, kölcsönök, illetmények és a tiszta vagyon
nyilvántartása.

A legalapvetőbb felhasználása, hogy a kincstár léterhozásánál
létrejött személy alá felveszed a létező (valós) számláid (pl bank,
párnaciha, tárca) és könyveled a bevételeid, kiadásaid. A kategóriák
használatával vissza tudod nézni, hogy mikor mire költöttél. Meglepő,
hogy ez mennyire hasznos tud lenni hosszútávon.

Ki a személy és mikor kell felvenni? Mindenki, akivel elszámolási számlát
akarsz fenntartani. Pl ha te abszolút közös kasszán vagy a pároddal, akkor
őt nem muszáj külön személyként felvenni, a számlái tartozhatnak a
kincstár személye alá is. Azt viszont, akinek adsz kölcsön, már érdemes
felvenni, hiszen van vele szemben egy követelésed, ami az elszámolási
számlára tartozik.

A létrehozott személyekhez automatikusan létrejön egy elszámolási számla
*Készpénz (HUF)* néven. Ezen lesz felírva a tartozás, követelés. Más
pénznemekhez hozhatsz létre új elszámolási számlát kézzel, pl
*Készpénz (EUR)* néven.

Választható tételek:

- Bevétel/kiadás (továbbiakban **+-**): Minden, ami a tiszta vagyonod
gyarapítja vagy apasztja illetve likviditását befolyásolja. Bármilyen
számlán szerepelhet.

- Átvezetés: Minden, amivel csak egyik zsebedből a másikba rakod a pénz,
tehát a tiszta vagyonod illetve annak likviditását sem befolyásolja,
pl. ATM levét, átutalás saját számlák között, pénzváltás. Mindig
párban jár, a másik oldala ellentétes előjelű. Bármilyen számlán
szerepelhet.

A likviditás például akkor romlik, amikor valami elszámolási számlára
kerül (valakinek a tartozása lesz), adott esetben a bizonytalan törlesztési
dátum- vagy szándék miatt. Technikailag felírható lenne átvezetésként
is, de statisztikai megfontolásból ajánlott ezt az utat követni.

Ha nem pénzben történik a törlesztés, akkor csak az elszámolási
számlára írjuk az egy lábú tranzakciót a +- tétellel, amin a kategória
jelzi a jószág fajátáját.

A segédszámlára írt tételek jelentése a segédszámla funkciójától
függ, ezt a kincstár nem definiálja.

Agyfasz, mi? Még sokat írhatnék az elméletről, de inkább gyakorlati
példákat hozok, talán hamarabb felismered benne a saját problémád,
illetve a rendszert, amivel bármit meg lehet oldani.

# A gigoló

Tegyük fel, hogy vagy egy számlád, amit közösen csapolsz a
pároddal. Erről fizeti a közös költségeket, a lakás rezsijét, a
közértet, satöbbit, no meg persze az erősen személyes kiadásokat, pl a
méregdrága személyi edzőt meg a masszőrt. Happy wife, happy life ide vagy
oda, azt mondod, hogy a betyárját, legyen egy havi keret amibe férjen bele a
személyes havi kiadása. Persze lehet, hogy egyik hónap túlszalad, a másik
meg majd alá, ebből ne legyen konfliktus, csak ugye a nagy átlag adja ki.

Mit lehet tenni?

Felveszed a párod a kincstárba, mint személyt. Vegyél fel egy
új egyezséget, a személy részedése legyen **:1**. Vegyél
fel egy új gyökérkategóriát (*antónió*), rendeld hozzá az
egyezséget. Alkategóriákat is létrehozhatsz opcionálisan (*masszázs*),
az egyezséget hierarchikusan örökli.

Ezután már csak a megfelelő kategóriába kell tenni a személyes
költését, terhelje az bármelyk számlát és az elszámolási számlán
követhető, hogy mennyi az annyi. Havonta leírod a követelésedből a neki
szánt összeget az elszámolási számlára létrehozott új tranzakcióval
(*mert "ledolgozta", lásd még: a lejmoló*).

# A háziúr

Tegyük fel, hogy egy külföldi rokon helyett beszeded az albidíjat
kápéban.  Kiadás is van, festés, vízóra 16 évre, ingatlanadó -
befizeted. A kápét persze közben költöd magadra is, hisz minek vennél le
a bankszámláról ha egyszer ott a kápé a kredencbe. A fáradozásaidért
jár 10% a haszonból, ez a deal.

Hogy lehet megoldani, hogy a rokon mindig tudja, hogy épp hogy áll és te is
tudd, hogy mennyit kell neki adni mikor hazatoppan?

Vedd fel a rokont a kincstárba, vedd fel mint felhasználót és rendeld
őket össze, korlátozottan. Vegyél fel egy egyezséget, ahol a rokon
részedése legyen **:9** a tiéd **:1** (90-10 %). Vegyél fel egy új
gyökérkategóriát, rendeld hozzá az egyezséget és utána használd azt az
albival kapcsolatos pénzügyekhez.

A rokon be tud lépni az oldalra a jelszavával, látni fogja az egyenlege
alakulását és az exporterrel akár emailt is kaphat a módosításokról. A
bevételt, kiadás intézd a saját tárcádból, nem kell külön kezelni
a pénz.

> *Érdekesség, hogy a kiszámított 10%-os összeg egyik számlára se
lesz felírva. Általános szabály a kincstárban, hogy ha a részesedő
személynek nincs készpénz követelés számlája az adott pénznemben, akkor
az nem kerül felírásra.*

# A lejmoló

Azaz kölcsönadsz. A fentiek után már szerintem kapizsgálod, az elv
hasonló: felveszed mint személyt, egyezség ahol a részesedés csak az
övé, hozzá kategória, majd szépen felírod a pénzmozgást az adott
kategóriával, a készpénz számla egyenlege pedig mindig mutatni fogja az
aktuális állást.

Ha mondjuk nem megadja, hanem ledolgozza, akkor az elszámolási számlán
írod le a tartozását egy új tranzakcióval. Ilyenkor viszont a kategória
ne a kölcsöné legyen, hiszen azt a pénz tulajdonképpen elköltötted
valamire!

Fordított esetben (te dolgoztad le) ugyanúgy igaz a fenti, azaz nem a
szokásos "törlesztés" a kategória, hiszen pénzért dolgoztál, bevételed
lett.

> *Itt felmerülhet az, hogy fölösleges felvenni a személyt egy kölcsön
miatt, hisz a kategóriának is van egyenlege, amivel nyomon lehet követni
a törlesztést. Egyszerű esetben ez működik is, viszont ha nem pénzben
törleszt, akkor nem tudod hova felírni az azt leíró tranzakciót.*

# A fusisok

Tegyük fel, hogy van egy üzlet, amin két ember osztozik 50-50 %. Van egy
stand ahol egyszer az egyik, máskor a másik árulja a közös portékát. A
pénzt a kasszából az viszi el aki ott volt, miközben a másik aznap saját
zsebéből betolt pénzzel vett anyagot.

Hogy lehet köztük korrekt az elszámolás?

Mi sem egyszerűbb: vedd fel mindkettejüket és egy egyezséget **:1** **:1**
aránnyal (50-50 %). Ezt rendeld hozzá a kincstár összes kategóriájához,
hisz mindenen osztoznak. Ezután a teendő már csak annyi, hogy mindketten
írják az összes pénzmozgást, a számlák egyenlege pedig mutatni fogja,
hogy kinél van a cég pénze.

Bolondítsuk meg ezt azzal, hogy mindkettejüknek van saját Wrisbi
könyvelésük, ahova egyszer már ugye felírják a tranzakciókat, hiszen
a pénz egy tárcában van a saját pénzükkel, kétszer pedig minek
dolgozni. Itt jön képbe az exporter és az importer.

A személyes kincstárukba lesz egy üzlettel kapcsolatos kategória, amin lesz
egy exporter, ami mondjuk 1db gmail-es mailboxba küld. A teendő már csak
annyi, hogy az üzlet kincstárához írjunk egy importert amire van is példa
a szoftverben - nem is ragozom tovább.

# A segédszámla

Tegyük fel, hogy apu fizeti a telefonszámlád és minden hónapban
automatikusan átküldi a számlát emailen. Te viszont élelmes vagy, a
telefont odaadtad a lakótársadnak akitől csak a díj felét kéred el, te
meg skype-olsz.

Importer, sima ügy, de felmerül a kérdés, hogy hova lehetne felírni a
teljes összeget? Hiszen ez csak információ, nincs mögötte követelés,
érdektelen az egyenlege. Na, pontosan erre van a segédszámla: minden olyan
dolgot fel lehet írni amit máshova nem.

> *Persze megtehetnéd, hogy az importer eleve csak az összeg 50%-át írja
fel a készpénz követelés számlára, csakhogy ehhez okosabb importer kell -
mennyivel egyszerűbb egy buta importer ami csak kategorizál és majd leosztja
az egyezség.*
