# yaml_importer
Automatizált tranzakció bevitel API-n keresztül YAML forrásból.

Remekül használható visszatérő tranzakciók bevitelére, például albérleti díjhoz. Bármilyen bonyolult tranzakció felvihető vele.

# Függőségek telepítése
```
$ cd vendor/yaml_importer
$ bundle
```

# Hozzáférés beállítása
A `config/wrisbi.yml.example` fájl alapján hozd létre a `config/wrisbi.yml` fájlt. Ajánlott egy új felhasználót generálni a scriptnek, hogy ne kerüljön ki a személyes jelszavad akkor sem, ha esetleg feltörik a szervert.

# Crontab bejegyzések
Cron helyett ajánlom az anacron-t, ami akkor se hagy ki felvitelt, ha nem megy 24 órában a szerver.

```
1 1 * * 7  cd vendor/yaml_importer/ && bundle exec script/yaml_importer.rb transactions/weekly/*.yml
1 0 1 * *  cd vendor/yaml_importer/ && bundle exec script/yaml_importer.rb transactions/monthly/*.yml
1 0 1 1 *  cd vendor/yaml_importer/ && bundle exec script/yaml_importer.rb transactions/yearly/*.yml
```

Ezután a `vendor/yaml_importer/transactions/*` mappák alá pakolhatod a .yml fájokat.
