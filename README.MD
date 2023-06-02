# Kako pokrenuti projekt

Implementacija projekta turističke agencije podijeljena je u više SQL skriptnih datoteka. Sljedeće su upute za pokretanje čitavog projekta:

1. Preuzmite sve priložene SQL datoteke i mapu `data` s CSV datotekama.
2. Mapu `data` premjestite ili kopirajte u konfiguriranu putanju prema vrijednosti koju vraća SQL sljedeći upit u MySQL Workbenchu: `SHOW VARIABLES LIKE "secure_file_priv";` Svima nama je to obično bila apsolutna putanja `C:\ProgramData\MySQL\MySQL Server 8.0\Uploads`.
3. Pri ulasku u MySQL Workbench desnim klikom na `Connection` kojim ćete se spajati odaberite `Edit Connection…`, otvorite karticu `Advanced` i unesite u `Others` `OPT_LOCAL_INFILE=1`.
4. Po potrebi kliknite `Test Connection`, `Close`, a možda je potrebno i ponovno pokretanje MySQL Workbencha.
5. Odaberite isti `Connection` koji ste konfigurirali te otvorite naše SQL skripte.
6. Prvo se pokreće čitavi `Main.sql`.
7. Zatim se pokreće čitavi `load_data.sql`
8. Upite možete sami testirati samim odabirom skripte s vlastitim imenom svakog studenta.
