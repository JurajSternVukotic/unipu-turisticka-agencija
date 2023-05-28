DROP DATABASE IF EXISTS turisticka_agencija;

CREATE DATABASE turisticka_agencija;

USE turisticka_agencija;

SET GLOBAL local_infile=1;

-- Odjeljak TABLICE

-- Autor: Alan Burić
CREATE TABLE osiguranje (
	id INT AUTO_INCREMENT PRIMARY KEY,
    naziv VARCHAR(100) NOT NULL,
    davatelj VARCHAR(100) NOT NULL, # Davatelj osiguranja (eng. insurance provider) obično je osiguravateljska kuća, tj. tvrtka.
    opis TINYTEXT,
    cijena NUMERIC(10, 2) NOT NULL,
    CHECK (cijena >= 0) # Cijena ne može biti negativna, ali može biti besplatno osiguranje.
);

# Omogućava definiciju popisa stavki koje su pokrivene određenim osiguranjem.
CREATE TABLE pokrice_osiguranja (
	id_osiguranje INT NOT NULL REFERENCES osiguranje (id),
    pokrice VARCHAR (100) NOT NULL,
    PRIMARY KEY (id_osiguranje, pokrice)
);

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

CREATE TABLE rezervacija (
	id INT AUTO_INCREMENT PRIMARY KEY,
    osoba_id INT NOT NULL REFERENCES osoba (id), # Nema kaskadnoga brisanja jer moramo biti sigurni da ta osoba želi i otkazati sve rezervacije ukoliko se radi o grešci, inače zadržavamo ovaj podatak o provedenoj povijesti.
    paket_id INT NOT NULL REFERENCES paket (id), # Nema kaskadnog brisanja jer se od turističke agencije očekuje odgovornost - prvo se pojedinačne rezervacije u stvarnosti trebaju razriješiti.
    zaposlenik_id INT NOT NULL REFERENCES zaposlenik (id) ON DELETE SET NULL,
    naziv VARCHAR(100) NOT NULL,
    vrijeme DATETIME NOT NULL, # Točno vrijeme u kojem je uspostavljena rezervacija.
    cijena NUMERIC(10, 2) NOT NULL
    CHECK (cijena >= 0) # Napomena: omogućuje besplatna putovanja iako je neuobičajeno.
);

CREATE TABLE posebni_zahtjev (
	id INT AUTO_INCREMENT PRIMARY KEY,
    rezervacija_id INT NOT NULL REFERENCES rezervacija (id) ON DELETE CASCADE,
    opis TEXT(750)
);

CREATE TABLE osiguranje_rezervacije (
    rezervacija_id INT NOT NULL REFERENCES rezervacija (id) ON DELETE CASCADE,
    osiguranje_id INT NOT NULL REFERENCES osiguranje (id) ON DELETE CASCADE
);

CREATE TABLE uplata (
	id INT AUTO_INCREMENT PRIMARY KEY,
    rezervacija_id INT NOT NULL REFERENCES rezervacija (id)  ON DELETE CASCADE,
    metoda ENUM('gotovina', 'kredit', 'debit', 'cek', 'redirect', 'transfer', 'voucher', 'wallet', 'ostalo') NOT NULL,
    iznos NUMERIC(10, 2) NOT NULL,
    vrijeme DATETIME NOT NULL, # Točno vrijeme uplate.
    CHECK (iznos > 0) # Uplata ničega ili negativnog iznosa nije važeća.
);

-- Autor: Juraj Štern-Vukotić
CREATE TABLE grad (
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
    naziv VARCHAR(64) NOT NULL, # Najduzi naziv grada na svijetu ima 58 znakova, 64 bi trebalo biti dovoljno
    opis TEXT(500), # 500 znakova bi trebalo biti dovoljno za opis da ne bude predug
    postanski_broj VARCHAR(32) NOT NULL UNIQUE, # Postanski brojevi mogu imati i slova, u nasem modelu jedan grad ima jedan postanski broj za razliku od inace gdje svaka ulica moze imati u nekim drzavama
	id_drzava INT NOT NULL REFERENCES drzava (id) ON DELETE CASCADE # svaki grad je u tocno jednoj drzavi (radi simplifikacije) 
);

CREATE TABLE adresa (
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
	naziv_ulice VARCHAR(128) NOT NULL, # 128 bi trebalo biti dovoljno za bilo koju ulicu
    dodatan_opis TEXT(256), # Dodatne informacije o kako doci do ulice, koji kat, itd.
    id_grad INT NOT NULL REFERENCES grad (id) ON DELETE CASCADE # posto svaka adresa ima tocno jedan grad, ne treba specijalna tablica za ovo, ako grad nestane nestane i adresa
);

CREATE TABLE drzava (
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
    naziv VARCHAR(64) NOT NULL UNIQUE, # Najduzi naziv drzave je 56, tako da bi ovo trebalo biti dovoljno, ime mora biti jedinstveno
    opis TEXT(500), # 500 znakova bi trebalo biti dovoljno za opis da ne bude predug
    valuta VARCHAR(32) NOT NULL, # Ime valute koja se koristi
    tecaj_u_eurima NUMERIC(10, 2) NOT NULL, # Koliko je jedan euro vrijedan ove valute 
    dokumenti_za_ulaz TEXT(500), # Kratki opis kakva je trenutna procedura za ulazak u drzavu, kasnije se moze dodati tablica koja gleda relaciju izmedju svake dvije drzave
    jezik VARCHAR(32) NOT NULL, # Naziv jezika koji se prica
    pozivni_broj INT NOT NULL UNIQUE, # pretpostavlja se da se ne pise niti 00 niti + izmedju posto je to preferenca formatiranja, takodjer da nema crtice nego samo se nastavi pisati posto je nepotrebno tako da moze biti INT, dvije drzave ne mogu imati isti pozivni broj
	CHECK (pozivni_broj > 0) # pozivni broj ne moze biti negativan niti nula
);	

CREATE TABLE stavka_korisnicke_podrske ( #support ticket
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
    # Mozda treba napraviti specijalnu tablicu sa id stavke, id korisnika i id zaposnelika???
	id_osoba INT NOT NULL REFERENCES osoba (id), # zelimo znati koji korisnik je zatrazio podrsku, i da to ostane cak i ako korisnika vise nema
    id_zaposlenik INT NOT NULL REFERENCES zaposlenik (id), # zelimo uvijek imati tocno jednu osobu koja radi na ovoj podrsci, i da ostane cak i ako taj zaposlenik ode 
    vrsta_problema ENUM ('Placanje', 'Rezervacija', 'Problemi sa zaposlenicima', 'Tehnicki problemi', 'Povrat novca', 'Drugo') NOT NULL, # ticket podrske moze biti samo jedna od ovih stvari
    opis_problema TEXT (2500), # opis problema mora biti teksutalan i imati manje od 2500 znakova
    CHECK (LENGTH(opis_problema) >= 50), # opis mora imati vise od 49 znakova kako bi smanjili zlouporabu sa praznim ili nedostatnim opisima 
	status_problema ENUM('Zaprimljeno', 'U obradi', 'Na cekanju', 'Rjeseno') NOT NULL # svaki ticket ima svoje stanje, ovisno u kojoj fazi proceisranja je
);

CREATE TABLE paket (
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
    naziv VARCHAR (100) NOT NULL UNIQUE, # unique kako ne bi imali duplikatne nazive paketa, 64 znakova bi trebalo biti dovoljno za naslov 
    opis TEXT (1000), # 1000 znakova za opis paketa, ako se zele detaljne informacije moze se poslati upit za putni plan
    min_ljudi INT NOT NULL DEFAULT 1, # minimalno ljudi koliko je potrebno da se odrzi putovanje 
    max_ljudi INT NOT NULL DEFAULT 1, # maksimalno ljudi koji mogu sudjelovati na putovanju
    CHECK (min_ljudi >= 1), # ne mozemo imati paket za manje od jednu osobu
    CHECK (max_ljudi >= min_ljudi), # maksimalan broj ljudi mora biti jednak ili veci od minimalnog
    popunjenih_mjesta INT NOT NULL DEFAULT 0,
    CHECK (popunjenih_mjesta <= max_ljudi), # ne moze biti vise popunjenih mjesta od max
    CHECK (popunjenih_mjesta >= 0), # ne moze biti negativno ljudi
    cijena_po_turistu NUMERIC(10, 2) NOT NULL # koliko kosta za jednu osobu paket
);

CREATE TABLE putni_plan_stavka(
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
    id_paket INT NOT NULL REFERENCES paket (id) ON DELETE CASCADE, # poveznica sa paketom kojem pripada stavka
    id_transport INT NOT NULL REFERENCES transport (id) ON DELETE CASCADE, # poveznica sa transportom koji ukljucuje
    id_odrediste INT NOT NULL REFERENCES odrediste (id) ON DELETE CASCADE, # poveznica sa odredistem na koje ide
    id_aktivnost INT NOT NULL REFERENCES aktivnost (id) ON DELETE CASCADE, # poveznica sa aktivnoscu koje ukljucuje
    id_vodic INT REFERENCES vodic (id) ON DELETE CASCADE, # poveznica na vodica ako ova stavka ukljucuje jednog 
    opis TEXT(500) NOT NULL, # opis sto se dogadja u ovoj stavci
    upute TEXT(500), # dodatne upute ako su potrebne
    pocetak DATETIME NOT NULL, # kada pocinje ovaj dio puta 
    trajanje_u_minutama INT # koliko dugo traje u minutama dio puta okvirno, ne mora biti ukljuceno, u slucaju npr. idenja natrag u hotel
);

CREATE TABLE osoba (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime VARCHAR(50) NOT NULL,
	prezime VARCHAR(50) NOT NULL,
	datum_rodenja DATE NOT NULL,
	kontaktni_broj VARCHAR(15) NOT NULL UNIQUE,
	email VARCHAR(100) NOT NULL UNIQUE,
	govorni_jezik VARCHAR(50) NOT NULL,
    korisnicki_bodovi INT NOT NULL DEFAULT 0,
    CHECK (korisnicki_bodovi >= 0),
    id_adresa INT NOT NULL REFERENCES adresa (id)
);

CREATE TABLE dodatni_jezici (
    id_osoba INT NOT NULL REFERENCES osoba (id) ON DELETE CASCADE,
    dodatni_jezik VARCHAR (50) NOT NULL
);
    
-- Autor: Lucia Labinjan

CREATE TABLE vodic (
	id INT AUTO_INCREMENT PRIMARY KEY,
    osoba_id INT NOT NULL UNIQUE REFERENCES osoba (id) ON DELETE CASCADE,
	godine_iskustva INT NOT NULL,
	CHECK (godine_iskustva >= 0)
);

CREATE TABLE transport (
	id INT AUTO_INCREMENT PRIMARY KEY,
	tip_transporta ENUM ('bus', 'avion', 'brod', 'vlak') NOT NULL,
	kapacitet INT DEFAULT 0 NOT NULL, 
	cijena NUMERIC(10, 2) NOT NULL,
	ime_tvrtke VARCHAR(100) NOT NULL,
	telefonski_broj VARCHAR(15) NOT NULL, 
	email VARCHAR(50) NOT NULL,
	vrijeme_odlaska DATETIME NOT NULL,
	trajanje_u_minutama INT NOT NULL,
	CHECK (kapacitet >= 0),
	CHECK (cijena >= 0)
);

CREATE TABLE aktivnosti (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime VARCHAR(100) NOT NULL UNIQUE,
    opis TEXT(500),
    cijena NUMERIC(10,2) NOT NULL, 
    id_adresa INT NOT NULL REFERENCES adresa (id) ON DELETE CASCADE,
    trajanje INT NOT NULL,
    vrijeme_odlaska DATETIME NOT NULL,
    CHECK (cijena >= 0),
    CHECK (trajanje> 0)
);

CREATE TABLE cjepivo (
	id INT AUTO_INCREMENT PRIMARY KEY,
    cijepivo ENUM('Žuta groznica', 'Hepatitis A', 'Hepatitis B', 'Hepatitis C', 'Tifus', 'Bjesnoća', 'Japanski encefalitis', 'Polio', 'Meningokokni meningitis', 'COVID-19', 'Ebola', 'Malarija', 'Gripa', 'Tetanus', 'Kolera', 'Ospice', 'Zaušnjaci', 'Rubela', 'Difterija', 'Hripavost', 'Vodene kozice') 
);

CREATE TABLE kontinent (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime VARCHAR(20) NOT NULL UNIQUE,
    opis TEXT(500)
);

CREATE TABLE drzava_kontinent ( 
	id_drzava INT NOT NULL REFERENCES drzava (id) ON DELETE CASCADE,
    id_kontinent INT NOT NULL REFERENCES kontinent (id) ON DELETE CASCADE
);

CREATE TABLE cjepivo_drzava (
	id_drzava INT NOT NULL REFERENCES drzava (id),
    id_cijepiva INT NOT NULL REFERENCES cjepivo (id)
);

CREATE TABLE cijepljena_osoba (
	id_cjepiva INT NOT NULL REFERENCES cjepivo (id),
    id_osoba INT NOT NULL REFERENCES osoba (id)
);

CREATE TABLE odrediste (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime VARCHAR(100) NOT NULL UNIQUE,
    id_grad INT NOT NULL REFERENCES grad (id),
    popularne_atrakcije VARCHAR(100),
    opis TEXT(500)
);

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

CREATE TABLE hoteli_paketa ( # ova relacija povezuje paket sa njegovim rezerviranim hotelima
	id INT AUTO_INCREMENT PRIMARY KEY,
    id_hotel INT NOT NULL REFERENCES hotel (id) ON DELETE CASCADE,
    id_paket INT NOT NULL REFERENCES paket (id) ON DELETE CASCADE,
    datum DATE # datum kada taj paket ima predvidjeno boravljenje u tom hotelu
);

-- Autori: Mateo Udovčić i Karlo Bazina

CREATE TABLE zaposlenik (
	id INT AUTO_INCREMENT PRIMARY KEY,
    id_osoba INT NOT NULL UNIQUE REFERENCES osoba (id),
    ugovor_o_radu ENUM ('studentski', 'honorarno', 'na neodređeno','na određeno') NOT NULL,
    placa NUMERIC (10, 2) NOT NULL
);

CREATE TABLE pozicija (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime_pozicije ENUM ('turistički agent', 'putni agent', 'računovođa', 'promotor', 'IT podrška') NOT NULL,
    opis_pozicije TEXT(500)
);

CREATE TABLE radna_smjena (
	zaposlenik_id INT NOT NULL REFERENCES zaposlenik (id) ON DELETE CASCADE,
    smjena ENUM('jutarnja', 'popodnevna') NOT NULL,
    datum DATE NOT NULL
);

CREATE TABLE pozicija_zaposlenika (
	id_zaposlenik INT NOT NULL REFERENCES zaposlenik (id) ON DELETE CASCADE,
    id_pozicija INT NOT NULL REFERENCES pozicija (id) ON DELETE CASCADE
);
    
    
CREATE TABLE recenzija (
	id INT AUTO_INCREMENT PRIMARY KEY,
    osoba_id INT NOT NULL REFERENCES osoba (id),
    ocjena ENUM ('1', '2', '3', '4', '5'),
    komentar TEXT(500),
    datum DATE NOT NULL
);

CREATE TABLE recenzija_transporta (
	id_transport INT NOT NULL REFERENCES transport (id) ON DELETE CASCADE,
    id_recenzija INT NOT NULL REFERENCES recenzija (id) ON DELETE CASCADE
);

CREATE TABLE recenzija_hotela (
	id_hotel INT NOT NULL REFERENCES hotel (id) ON DELETE CASCADE,
    id_recenzija INT NOT NULL REFERENCES recenzija (id) ON DELETE CASCADE
);

CREATE TABLE recenzija_paketa (
	id_paket INT NOT NULL REFERENCES paket (id) ON DELETE CASCADE,
    id_recenzija INT NOT NULL REFERENCES recenzija (id) ON DELETE CASCADE
);

CREATE TABLE recenzija_zaposlenika (
	id_zaposelnik INT NOT NULL REFERENCES zaposlenik (id) ON DELETE CASCADE,
    id_recenzija INT NOT NULL REFERENCES recenzija (id) ON DELETE CASCADE
); 

CREATE TABLE recenzija_aktivnosti (
	id_aktivnost INT NOT NULL REFERENCES aktivnosti (id) ON DELETE CASCADE,
    id_recenzija INT NOT NULL REFERENCES recenzija (id) ON DELETE CASCADE
);

CREATE TABLE recenzija_vodica (
	id_vodic INT NOT NULL REFERENCES vodic (id) ON DELETE CASCADE,
    id_recenzija INT NOT NULL REFERENCES recenzija (id) ON DELETE CASCADE
);

-- Odjeljak EXECUTABLES

-- Autor: Alan Burić

-- POGLEDI - pohranjeni upiti

-- Prikazuje sve IDjeve zaposlenika koji su putni agenti.
CREATE VIEW svi_putni_agenti AS SELECT id_zaposlenik AS id FROM pozicija_zaposlenika WHERE id_pozicija = (SELECT id FROM pozicija WHERE ime_pozicije = 'putni agent');

-- 1. Pronađi ID pozicije 'putni agent'
-- 2. Pronađi sve zaposlenike s tom pozicijom (preko IDja)
-- 3. Pobroji njihova pojavljivanja
-- 4. Sortiraj ih od najmanjeg prema najvećem

CREATE VIEW zaposlenost_rezervacije AS 
	SELECT *, COUNT(*) AS kolicina_posla 
		FROM svi_putni_agenti 
			LEFT JOIN 
	(SELECT zaposlenik_id AS id FROM rezervacija) AS rezervacija 
			USING (id);

-- OKIDAČI - event handlers

-- Nužno je za razlikovanja završetka naredbe.
DELIMITER //

CREATE TRIGGER ogranicenje_putnog_agenta BEFORE INSERT ON rezervacija
	FOR EACH ROW
		BEGIN
			DECLARE poruka VARCHAR(128);
        
			IF NEW.zaposlenik_id NOT IN (svi_putni_agenti) THEN
				SET poruka = CONCAT('Zadani zaposlenik s IDjem ', NEW.zaposlenik_id, ' nije putni agent za rezervacije!');
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = poruka;
			END IF;
		END//

/*
 * Ukoliko se zaposlenika otpusti, prema ON DELETE SET NULL ograničenju atributa zaposlenik_id u
 * relaciji rezervacije će atribut s IDjem otpuštenog zaposlenika postati NULL. Potrebno je postaviti novog
 * zaposlenika na tu poziciju kako bi korisnici imali zaposlenika turističke agencije kojeg mogu kontaktirati
 * u vezi s njihovom rezervacijom.
 */
CREATE TRIGGER postavi_novog_zaposlenika BEFORE UPDATE ON rezervacija
	FOR EACH ROW
		BEGIN
			IF NEW.zaposlenik_id IS NULL THEN
				SET NEW.zaposlenik_id = (SELECT * FROM zaposlenost_rezervacije GROUP BY id ORDER BY kolicina_posla ASC LIMIT 1);
			END IF;
		END//

CREATE TRIGGER istovremeni_kod BEFORE INSERT ON kupon
	FOR EACH ROW
		BEGIN
            DECLARE poruka VARCHAR(128);
            
            -- Želimo da su svi kodovi zapisani velikim slovima radi jednostavnosti i tipičnog formata.
			SET NEW.kod = UPPER(NEW.kod);
        
			IF EXISTS(SELECT * FROM kupon WHERE NEW.kod = kupon.kod AND NEW.datum_pocetka <= datum_kraja AND NEW.datum_kraja > datum_pocetka) THEN
				SET poruka = CONCAT('Već postoji isti kod u preklapajućem vremenu za kod ', NEW.kod);
				SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = poruka;
			END IF;
		END//

DELIMITER ;

-- Autor: Juraj Štern-Vukotić

-- Autor: Lucija Labinjan

-- Autor: Mateo Udovčić

-- Autor: Karlo Bazina

-- Odjeljak VRIJEDNOSTI

/*
 * Ukoliko je MySQL server (lokalno na računalu ili negdje drugdje) inicijaliziran sa opcijom
 * --secure_file_priv, koristit će samo postavljenu mapu čija je putanja navedena u rezultatu
 * sljedećeg upita. Potom se ta mapa može upotrebljavati za pohranu datoteka za učitavanje i
 * zapis.
 * Očekivani rezultat: C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/
 * Ukoliko se rezultat razlikuje, lokalno promijenite u skripti datoteku te tamo postavite datoteke.
 */
SHOW VARIABLES LIKE "secure_file_priv";

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/kontinent.csv' 
	INTO TABLE kontinent 
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n' 
	IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/drzava.csv' 
	INTO TABLE drzava 
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n' 
	IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/kupon.csv' 
	INTO TABLE kupon
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n' 
	IGNORE 1 ROWS
    (kod, datum_pocetka, datum_kraja, iznos, postotni);

-- Odjeljak TESTIRANJE
    
SELECT * FROM kontinent;
SELECT * FROM drzava;
SELECT * FROM kupon;