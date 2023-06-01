DROP DATABASE IF EXISTS turisticka_agencija;
CREATE DATABASE turisticka_agencija;
USE turisticka_agencija;
SET GLOBAL local_infile=1;


-- Odjeljak relacije
### Lucia Labinjan ###
CREATE TABLE cjepivo (
	id INT AUTO_INCREMENT PRIMARY KEY,
    naziv VARCHAR(50) UNIQUE
);
### Lucia Labinjan ###
CREATE TABLE kontinent (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime VARCHAR(25) NOT NULL UNIQUE,
    opis TEXT(500)
);

### Juraj Štern-Vukotić ###
CREATE TABLE drzava (
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
    naziv VARCHAR(64) NOT NULL UNIQUE, # Najduzi naziv drzave je 56, tako da bi ovo trebalo biti dovoljno, ime mora biti jedinstveno
    opis TEXT(500), # 500 znakova bi trebalo biti dovoljno za opis da ne bude predug
    valuta VARCHAR(50) NOT NULL, # Ime valute koja se koristi
    tecaj_u_eurima NUMERIC(10, 6) NOT NULL, # Koliko je jedan euro vrijedan ove valute 
    dokumenti_za_ulaz TEXT(500), # Kratki opis kakva je trenutna procedura za ulazak u drzavu, kasnije se moze dodati tablica koja gleda relaciju izmedju svake dvije drzave
    jezik VARCHAR(50) NOT NULL, # Naziv jezika koji se prica
    pozivni_broj INT NOT NULL UNIQUE, # pretpostavlja se da se ne pise niti 00 niti + izmedju posto je to preferenca formatiranja, takodjer da nema crtice nego samo se nastavi pisati posto je nepotrebno tako da moze biti INT, dvije drzave ne mogu imati isti pozivni broj
	CHECK (pozivni_broj > 0) # pozivni broj ne moze biti negativan niti nula
);

### Juraj Štern-Vukotić ###
CREATE TABLE drzava_kontinent ( 
	id_drzava INT NOT NULL,
    id_kontinent INT NOT NULL,
    FOREIGN KEY (id_drzava) REFERENCES drzava (id) ON DELETE CASCADE,
    FOREIGN KEY (id_kontinent) REFERENCES kontinent (id) ON DELETE CASCADE
);

### Lucia Labinjan ###
CREATE TABLE cjepivo_drzava (
	id_drzava INT NOT NULL,
    id_cjepivo INT NOT NULL,
    PRIMARY KEY (id_drzava, id_cjepivo),
    FOREIGN KEY (id_drzava) REFERENCES drzava (id),
    FOREIGN KEY (id_cjepivo) REFERENCES cjepivo (id)
);

### Juraj Štern-Vukotić ###
CREATE TABLE grad (
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
    naziv VARCHAR(64) NOT NULL, # Najduzi naziv grada na svijetu ima 58 znakova, 64 bi trebalo biti dovoljno
    opis TEXT(500), # 500 znakova bi trebalo biti dovoljno za opis da ne bude predug
    postanski_broj VARCHAR(32) NOT NULL UNIQUE, # Postanski brojevi mogu imati i slova, u nasem modelu jedan grad ima jedan postanski broj za razliku od inace gdje svaka ulica moze imati u nekim drzavama
	id_drzava INT NOT NULL, # svaki grad je u tocno jednoj drzavi (radi simplifikacije)
    FOREIGN KEY (id_drzava) REFERENCES drzava (id) ON DELETE CASCADE
);

### Juraj Štern-Vukotić ###
CREATE TABLE adresa (
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
	naziv_ulice VARCHAR(128) NOT NULL, # 128 bi trebalo biti dovoljno za bilo koju ulicu
    dodatan_opis TEXT(256), # Dodatne informacije o kako doci do ulice, koji kat, itd.
    id_grad INT NOT NULL, # posto svaka adresa ima tocno jedan grad, ne treba specijalna tablica za ovo, ako grad nestane nestane i adresa
    FOREIGN KEY (id_grad) REFERENCES grad (id) ON DELETE CASCADE
);

### Mateo Udovičić ###
CREATE TABLE osoba (
	id INT AUTO_INCREMENT PRIMARY KEY,
    puno_ime VARCHAR(100) NOT NULL,
	datum_rodenja DATE NOT NULL,
	kontaktni_broj VARCHAR(15) NOT NULL UNIQUE,
	email VARCHAR(100) NOT NULL UNIQUE,
    korisnicki_bodovi INT NOT NULL DEFAULT 0,
    CHECK (korisnicki_bodovi >= 0),
    id_adresa INT NOT NULL REFERENCES adresa (id)
);

### Juraj Štern-Vukotić ###
CREATE TABLE dodatni_jezik (
    id_osoba INT NOT NULL,
    dodatni_jezik VARCHAR (50) NOT NULL,
    PRIMARY KEY (id_osoba, dodatni_jezik),
    FOREIGN KEY (id_osoba) REFERENCES osoba (id) ON DELETE CASCADE
);


CREATE TABLE cjepljena_osoba (
    id_osoba INT NOT NULL REFERENCES osoba (id),
	id_cjepivo INT NOT NULL REFERENCES cjepivo (id),
    PRIMARY KEY (id_cjepivo, id_osoba)
);

### Mateo Udovičić ###
CREATE TABLE recenzija (
	id INT AUTO_INCREMENT PRIMARY KEY,
    id_osoba INT NOT NULL,
    ocjena ENUM ('1', '2', '3', '4', '5'),
    komentar TEXT(500),
    datum DATE NOT NULL,
    FOREIGN KEY (id_osoba) REFERENCES osoba (id)
);

### Karlo Bazina ###
CREATE TABLE zaposlenik (
    id INT NOT NULL PRIMARY KEY,
    ugovor_o_radu ENUM ('studentski', 'honorarno', 'na neodređeno','na određeno') NOT NULL,
    placa NUMERIC (10, 2) NOT NULL,
    CHECK (placa >= 0),
    FOREIGN KEY (id) REFERENCES osoba (id) ON DELETE CASCADE
);

### Karlo Bazina ###
CREATE TABLE pozicija (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime_pozicije ENUM ('turistički agent', 'putni agent', 'računovođa', 'promotor', 'IT podrška') NOT NULL UNIQUE,
    opis_pozicije TEXT(500)
);

### Karlo Bazina ###
CREATE TABLE pozicija_zaposlenika (
	id_zaposlenik INT NOT NULL,
    id_pozicija INT NOT NULL,
    FOREIGN KEY (id_zaposlenik) REFERENCES zaposlenik (id) ON DELETE CASCADE,
    FOREIGN KEY (id_pozicija) REFERENCES pozicija (id) ON DELETE CASCADE,
    PRIMARY KEY (id_zaposlenik, id_pozicija)
);

### Karlo Bazina ###
CREATE TABLE radna_smjena (
	id_zaposlenik INT NOT NULL,
    smjena ENUM('jutarnja', 'popodnevna') NOT NULL,
    datum DATE NOT NULL,
    FOREIGN KEY (id_zaposlenik) REFERENCES zaposlenik (id) ON DELETE CASCADE
);

### Juraj Štern-Vukotić ###
CREATE TABLE stavka_korisnicke_podrske ( #support ticket
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
	id_osoba INT NOT NULL, # zelimo znati koji korisnik je zatrazio podrsku, i da to ostane cak i ako korisnika vise nema
    id_zaposlenik INT NOT NULL, # zelimo uvijek imati tocno jednu osobu koja radi na ovoj podrsci, i da ostane cak i ako taj zaposlenik ode 
    vrsta_problema ENUM ('Plaćanje', 'Rezervacija', 'Problemi sa zaposlenicima', 'Tehnički problemi', 'Povrat novca', 'Drugo') NOT NULL, # ticket podrske moze biti samo jedna od ovih stvari
    opis_problema TEXT (2500), # opis problema mora biti teksutalan i imati manje od 2500 znakova
    CHECK (LENGTH(opis_problema) >= 50), # opis mora imati vise od 49 znakova kako bi smanjili zlouporabu sa praznim ili nedostatnim opisima 
	status_problema ENUM('Zaprimljeno', 'U obradi', 'Na čekanju', 'Rješeno') NOT NULL, # svaki ticket ima svoje stanje, ovisno u kojoj fazi proceisranja je
    FOREIGN KEY (id_osoba) REFERENCES osoba (id),
    FOREIGN KEY (id_zaposlenik) REFERENCES zaposlenik (id)
);

### Mateo Udovičić ###
CREATE TABLE recenzija_zaposlenika (
	id_zaposlenik INT NOT NULL REFERENCES zaposlenik (id) ON DELETE CASCADE,
    id_recenzija INT NOT NULL REFERENCES recenzija (id) ON DELETE CASCADE,
	PRIMARY KEY (id_zaposlenik, id_recenzija),
    FOREIGN KEY (id_zaposlenik) REFERENCES zaposlenik (id) ON DELETE CASCADE,
    FOREIGN KEY (id_recenzija) REFERENCES recenzija (id) ON DELETE CASCADE
); 

### Juraj Štern-Vukotić ###
CREATE TABLE paket (
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
    naziv VARCHAR (100) NOT NULL UNIQUE, # unique kako ne bi imali duplikatne nazive paketa, 64 znakova bi trebalo biti dovoljno za naslov 
    opis TEXT (1000), # 1000 znakova za opis paketa, ako se zele detaljne informacije moze se poslati upit za putni plan
    min_ljudi INT NOT NULL DEFAULT 1, # minimalno ljudi koliko je potrebno da se odrzi putovanje 
    max_ljudi INT NOT NULL DEFAULT 1, # maksimalno ljudi koji mogu sudjelovati na putovanju
    CHECK (min_ljudi >= 1), # ne mozemo imati paket za manje od jednu osobu
    CHECK (max_ljudi >= min_ljudi), # maksimalan broj ljudi mora biti jednak ili veci od minimalnog
    cijena_po_turistu NUMERIC(10, 2) NOT NULL # koliko kosta za jednu osobu paket
);

### Mateo Udovičić ###
CREATE TABLE recenzija_paketa (
	id_paket INT NOT NULL REFERENCES paket (id) ON DELETE CASCADE,
    id_recenzija INT NOT NULL REFERENCES recenzija (id) ON DELETE CASCADE,
	PRIMARY KEY (id_paket, id_recenzija),
    FOREIGN KEY (id_paket) REFERENCES paket (id) ON DELETE CASCADE,
    FOREIGN KEY (id_recenzija) REFERENCES recenzija (id) ON DELETE CASCADE
);

### Alan Burić ###
CREATE TABLE rezervacija (
	id INT AUTO_INCREMENT PRIMARY KEY,
    id_osoba INT NOT NULL, # Nema kaskadnoga brisanja jer moramo biti sigurni da ta osoba želi i otkazati sve rezervacije ukoliko se radi o grešci, inače zadržavamo ovaj podatak o provedenoj povijesti.
    id_paket INT NOT NULL, # Nema kaskadnog brisanja jer se od turističke agencije očekuje odgovornost - prvo se pojedinačne rezervacije u stvarnosti trebaju razriješiti.
    id_zaposlenik INT NOT NULL REFERENCES zaposlenik (id) ON DELETE SET NULL,
    vrijeme DATETIME NOT NULL, # Točno vrijeme u kojem je uspostavljena rezervacija.
    FOREIGN KEY (id_osoba) REFERENCES osoba (id),
    FOREIGN KEY (id_paket) REFERENCES paket (id),
	FOREIGN KEY (id_zaposlenik) REFERENCES zaposlenik (id)
);

### Alan Burić ###
CREATE TABLE kupon (
	id INT AUTO_INCREMENT PRIMARY KEY,
	kod VARCHAR(20) NOT NULL,
    datum_pocetka DATETIME NOT NULL,
    datum_kraja DATETIME NOT NULL,
    iznos NUMERIC (10, 2) NOT NULL,
    postotni BOOL NOT NULL, # Ukazuje na to radi li se o postotnom popustu ili o oduzimanju iznosom.
	CHECK (datum_pocetka < datum_kraja), # Datum početka nikako ne može biti poslije datuma završetka.
    CHECK (iznos > 0 AND (NOT postotni OR iznos <= 100)) # Kupon je postojan ako uopće ima neki iznos (=/= 0), a postotni popust ne bi trebao prekoraciti 100%
);

### Alan Burić ###
CREATE TABLE kupon_rezervacija (
	id_kupon INT NOT NULL,
    id_rezervacija INT NOT NULL,
    PRIMARY KEY (id_kupon, id_rezervacija),
    FOREIGN KEY (id_kupon) REFERENCES kupon (id),
    FOREIGN KEY (id_rezervacija) REFERENCES rezervacija (id)
);

### Alan Burić ###
CREATE TABLE osiguranje (
	id INT AUTO_INCREMENT PRIMARY KEY,
    id_rezervacija INT NOT NULL UNIQUE,
    naziv VARCHAR(100) NOT NULL,
    davatelj VARCHAR(100) NOT NULL, # Davatelj osiguranja (eng. insurance provider) obično je osiguravateljska kuća, tj. tvrtka.
    opis TINYTEXT,
    cijena NUMERIC(10, 2) NOT NULL,
    CHECK (cijena >= 0), # Cijena ne može biti negativna, ali može biti besplatno osiguranje.
    FOREIGN KEY (id_rezervacija) REFERENCES rezervacija (id) ON DELETE CASCADE
);

### Alan Burić ###
CREATE TABLE uplata (
	id INT AUTO_INCREMENT PRIMARY KEY,
    id_rezervacija INT NOT NULL,
    metoda ENUM('gotovina', 'kredit', 'debit', 'cek', 'redirect', 'wallet', 'paypal', 'ostalo') NOT NULL,
    iznos NUMERIC(10, 2) NOT NULL,
    vrijeme DATETIME NOT NULL, # Točno vrijeme uplate.
    CHECK (iznos > 0), # Uplata ničega ili negativnog iznosa nije važeća.
    FOREIGN KEY (id_rezervacija) REFERENCES rezervacija (id) ON DELETE CASCADE
);

### Alan Burić ###
CREATE TABLE posebni_zahtjev (
	id INT AUTO_INCREMENT PRIMARY KEY,
    id_rezervacija INT NOT NULL,
    opis TEXT(750),
    FOREIGN KEY (id_rezervacija) REFERENCES rezervacija (id) ON DELETE CASCADE
);

### Lucia Labinjan ###
CREATE TABLE hotel (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime VARCHAR(100) NOT NULL,
    id_adresa INT NOT NULL REFERENCES adresa (id),
    kontaktni_broj VARCHAR(15), 
    email VARCHAR(100) NOT NULL UNIQUE,
    CHECK (email LIKE '%@%.%'),
    slobodne_sobe INT NOT NULL,
    pogodnosti TEXT(500),
    opis TEXT(500),
    CHECK (slobodne_sobe >= 0)
);

### Lucia Labinjan ###
CREATE TABLE hoteli_paketa ( # ova relacija povezuje paket sa njegovim rezerviranim hotelima
	id INT AUTO_INCREMENT PRIMARY KEY,
    id_hotel INT NOT NULL,
    id_paket INT NOT NULL,
    datum DATE, # datum kada taj paket ima predvidjeno boravljenje u tom hotelu
    FOREIGN KEY (id_hotel) REFERENCES hotel (id) ON DELETE CASCADE,
    FOREIGN KEY (id_paket) REFERENCES paket (id) ON DELETE CASCADE
);

### Mateo Udovičić ###
CREATE TABLE recenzija_hotela (
	id_hotel INT NOT NULL REFERENCES hotel (id) ON DELETE CASCADE,
    id_recenzija INT NOT NULL REFERENCES recenzija (id) ON DELETE CASCADE,
	PRIMARY KEY (id_hotel, id_recenzija),
    FOREIGN KEY (id_hotel) REFERENCES hotel (id) ON DELETE CASCADE,
    FOREIGN KEY (id_recenzija) REFERENCES recenzija (id) ON DELETE CASCADE
);

### Lucia Labinjan ###
CREATE TABLE transport (
	id INT AUTO_INCREMENT PRIMARY KEY,
	tip_transporta ENUM ('autobus', 'zrakoplov', 'brod', 'vlak') NOT NULL,
	kapacitet INT DEFAULT 0 NOT NULL, 
	cijena NUMERIC(10, 2) NOT NULL,
	ime_tvrtke VARCHAR(100) NOT NULL,
	telefonski_broj VARCHAR(15) NOT NULL, 
	email VARCHAR(50) NOT NULL,
	trajanje_u_minutama INT NOT NULL,
	CHECK (kapacitet >= 0),
	CHECK (cijena >= 0)
);

### Mateo Udovičić ###
CREATE TABLE recenzija_transporta (
	id_transport INT NOT NULL,
    id_recenzija INT NOT NULL,
    PRIMARY KEY (id_transport, id_recenzija),
    FOREIGN KEY (id_transport) REFERENCES transport (id) ON DELETE CASCADE,
    FOREIGN KEY (id_recenzija) REFERENCES recenzija (id) ON DELETE CASCADE
);

### Lucia Labinjan ###
CREATE TABLE odrediste (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime VARCHAR(100) NOT NULL UNIQUE,
    id_grad INT NOT NULL,
    popularne_atrakcije VARCHAR(200),
    opis TEXT(500),
    FOREIGN KEY (id_grad) REFERENCES grad (id)
);

### Lucia Labinjan ###
CREATE TABLE aktivnost (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime VARCHAR(100) NOT NULL UNIQUE,
    opis TEXT(500),
    cijena NUMERIC(10,2) NOT NULL, 
    id_adresa INT NOT NULL,
    trajanje INT NOT NULL,
    vrijeme_odlaska TIME NOT NULL,
    CHECK (cijena >= 0),
    CHECK (trajanje> 0),
    FOREIGN KEY (id_adresa) REFERENCES adresa (id)
);

### Mateo Udovičić ###
CREATE TABLE recenzija_aktivnosti (
	id_aktivnost INT NOT NULL REFERENCES aktivnost (id) ON DELETE CASCADE,
    id_recenzija INT NOT NULL REFERENCES recenzija (id) ON DELETE CASCADE,
	PRIMARY KEY (id_aktivnost, id_recenzija),
    FOREIGN KEY (id_aktivnost) REFERENCES aktivnost (id) ON DELETE CASCADE,
    FOREIGN KEY (id_recenzija) REFERENCES recenzija (id) ON DELETE CASCADE
);

### Lucia Labinjan ###
CREATE TABLE vodic (
    id INT NOT NULL PRIMARY KEY,
	godine_iskustva INT NOT NULL,
	CHECK (godine_iskustva >= 0),
    FOREIGN KEY (id) REFERENCES osoba (id) ON DELETE CASCADE
);

### Mateo Udovičić ###
CREATE TABLE recenzija_vodica (
	id_vodic INT NOT NULL REFERENCES vodic (id) ON DELETE CASCADE,
    id_recenzija INT NOT NULL REFERENCES recenzija (id) ON DELETE CASCADE,
	PRIMARY KEY (id_vodic, id_recenzija),
    FOREIGN KEY (id_vodic) REFERENCES vodic (id) ON DELETE CASCADE,
    FOREIGN KEY (id_recenzija) REFERENCES recenzija (id) ON DELETE CASCADE
);

### Juraj Štern-Vukotić ###
CREATE TABLE putni_plan_stavka (
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
    id_paket INT NOT NULL, # poveznica sa paketom kojem pripada stavka
    id_transport INT, # poveznica sa transportom koji ukljucuje
    id_odrediste INT, # poveznica sa odredistem na koje ide
    id_aktivnost INT, # poveznica sa aktivnoscu koje ukljucuje
    id_vodic INT , # poveznica na vodica ako ova stavka ukljucuje jednog 
    FOREIGN KEY (id_paket) REFERENCES paket (id) ON DELETE CASCADE,
    FOREIGN KEY (id_transport) REFERENCES transport (id),
    FOREIGN KEY (id_odrediste) REFERENCES odrediste (id),
    FOREIGN KEY (id_aktivnost) REFERENCES aktivnost (id),
    FOREIGN KEY (id_vodic) REFERENCES vodic (id)
);



-- OKIDAČI - event handlers

-- Nužno je za razlikovanja završetka naredbe.
-- DELIMITER //

-- CREATE TRIGGER ogranicenje_putnog_agenta BEFORE INSERT ON rezervacija
-- 	FOR EACH ROW
-- 		BEGIN
-- 			DECLARE poruka VARCHAR(128);
--         
-- 			IF NEW.zaposlenik_id NOT IN (svi_putni_agenti) THEN
-- 				SET poruka = CONCAT('Zadani zaposlenik s IDjem ', NEW.zaposlenik_id, ' nije putni agent za rezervacije!');
-- 				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = poruka;
-- 			END IF;
-- 		END//

-- /*
--  * Ukoliko se zaposlenika otpusti, prema ON DELETE SET NULL ograničenju atributa zaposlenik_id u
--  * relaciji rezervacije će atribut s IDjem otpuštenog zaposlenika postati NULL. Potrebno je postaviti novog
--  * zaposlenika na tu poziciju kako bi korisnici imali zaposlenika turističke agencije kojeg mogu kontaktirati
--  * u vezi s njihovom rezervacijom.
--  */
-- CREATE TRIGGER postavi_novog_zaposlenika BEFORE UPDATE ON rezervacija
-- 	FOR EACH ROW
-- 		BEGIN
-- 			IF NEW.zaposlenik_id IS NULL THEN
-- 				SET NEW.zaposlenik_id = (SELECT * FROM zaposlenost_rezervacije GROUP BY id ORDER BY kolicina_posla ASC LIMIT 1);
-- 			END IF;
-- 		END//

-- CREATE TRIGGER istovremeni_kod BEFORE INSERT ON kupon
-- 	FOR EACH ROW
-- 		BEGIN
--             DECLARE poruka VARCHAR(128);
--             
--             -- Želimo da su svi kodovi zapisani velikim slovima radi jednostavnosti i tipičnog formata.
-- 			SET NEW.kod = UPPER(NEW.kod);
--         
-- 			IF EXISTS(SELECT * FROM kupon WHERE NEW.kod = kupon.kod AND NEW.datum_pocetka <= datum_kraja AND NEW.datum_kraja > datum_pocetka) THEN
-- 				SET poruka = CONCAT('Već postoji isti kod u preklapajućem vremenu za kod ', NEW.kod);
-- 				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = poruka;
-- 			END IF;
-- 		END//

-- DELIMITER ;







-- Odjeljak TESTIRANJE

-- SELECT * FROM adresa;
-- SELECT * FROM cjepivo;
-- SELECT * FROM cjepivo_drzava;
-- SELECT * FROM drzava;
-- SELECT * FROM drzava_kontinent;
-- SELECT * FROM grad;
-- SELECT * FROM hotel;
-- SELECT * FROM kontinent;
-- SELECT * FROM kupon;
-- SELECT * FROM pozicija;
-- SELECT * FROM transport;
-- SELECT * FROM odrediste;
-- SELECT * FROM aktivnost;
-- SELECT * FROM osoba;
-- SELECT * FROM cijepljena_osoba
-- SELECT * FROM dodatni_jezik;
-- SELECT * FROM zaposlenik;
-- SELECT * FROM pozicija_zaposlenika;
-- SELECT * FROM vodic;
-- SELECT * FROM radna_smjena;
-- SELECT * FROM paket;
-- SELECT * FROM recenzija;
-- SELECT * FROM recenzija_aktivnosti;
-- SELECT * FROM recenzija_paketa;
-- SELECT * FROM recenzija_hotela;
-- SELECT * FROM recenzija_transporta;
-- SELECT * FROM recenzija_vodica;
-- SELECT * FROM recenzija_zaposlenika;
-- SELECT * FROM stavka_korisnicke_podrske;
-- SELECT * FROM uplata;
-- SELECT * FROM stavka_korisnicke_podrske;
-- SELECT * FROM rezervacija;
-- SELECT * FROM kupon_rezervacija;
-- SELECT * FROM grad JOIN drzava ON grad.id_drzava = drzava.id;
-- SELECT DISTINCT id_vodic
-- FROM recenzija_vodica
-- WHERE id_vodic NOT IN (SELECT id FROM vodic);
-- SELECT * FROM recenzija_transporta WHERE id_recenzija = 0; 
