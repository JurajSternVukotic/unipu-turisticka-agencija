DROP DATABASE IF EXISTS turisticka_agencija;
CREATE DATABASE turisticka_agencija;
USE turisticka_agencija;
SET GLOBAL local_infile=1;


-- Odjeljak relacije
CREATE TABLE cjepivo (
	id INT AUTO_INCREMENT PRIMARY KEY,
    naziv VARCHAR(50) UNIQUE
);

CREATE TABLE kontinent (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime VARCHAR(25) NOT NULL UNIQUE,
    opis TEXT(500)
);

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

CREATE TABLE drzava_kontinent ( 
	id_drzava INT NOT NULL,
    id_kontinent INT NOT NULL,
    FOREIGN KEY (id_drzava) REFERENCES drzava (id) ON DELETE CASCADE,
    FOREIGN KEY (id_kontinent) REFERENCES kontinent (id) ON DELETE CASCADE
);

CREATE TABLE cjepivo_drzava (
	id_drzava INT NOT NULL,
    id_cjepivo INT NOT NULL,
    PRIMARY KEY (id_drzava, id_cjepivo),
    FOREIGN KEY (id_drzava) REFERENCES drzava (id),
    FOREIGN KEY (id_cjepivo) REFERENCES cjepivo (id)
);

CREATE TABLE grad (
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
    naziv VARCHAR(64) NOT NULL, # Najduzi naziv grada na svijetu ima 58 znakova, 64 bi trebalo biti dovoljno
    opis TEXT(500), # 500 znakova bi trebalo biti dovoljno za opis da ne bude predug
    postanski_broj VARCHAR(32) NOT NULL UNIQUE, # Postanski brojevi mogu imati i slova, u nasem modelu jedan grad ima jedan postanski broj za razliku od inace gdje svaka ulica moze imati u nekim drzavama
	id_drzava INT NOT NULL, # svaki grad je u tocno jednoj drzavi (radi simplifikacije)
    FOREIGN KEY (id_drzava) REFERENCES drzava (id) ON DELETE CASCADE
);

CREATE TABLE adresa (
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
	naziv_ulice VARCHAR(128) NOT NULL, # 128 bi trebalo biti dovoljno za bilo koju ulicu
    dodatan_opis TEXT(256), # Dodatne informacije o kako doci do ulice, koji kat, itd.
    id_grad INT NOT NULL, # posto svaka adresa ima tocno jedan grad, ne treba specijalna tablica za ovo, ako grad nestane nestane i adresa
    FOREIGN KEY (id_grad) REFERENCES grad (id) ON DELETE CASCADE
);

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

CREATE TABLE recenzija (
	id INT AUTO_INCREMENT PRIMARY KEY,
    id_osoba INT NOT NULL,
    ocjena ENUM ('1', '2', '3', '4', '5'),
    komentar TEXT(500),
    datum DATE NOT NULL,
    FOREIGN KEY (id_osoba) REFERENCES osoba (id)
);

CREATE TABLE zaposlenik (
    id INT NOT NULL PRIMARY KEY,
    ugovor_o_radu ENUM ('studentski', 'honorarno', 'na neodređeno','na određeno') NOT NULL,
    placa NUMERIC (10, 2) NOT NULL,
    CHECK (placa >= 0),
    FOREIGN KEY (id) REFERENCES osoba (id) ON DELETE CASCADE
);

CREATE TABLE pozicija (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime_pozicije ENUM ('turistički agent', 'putni agent', 'računovođa', 'promotor', 'IT podrška') NOT NULL UNIQUE,
    opis_pozicije TEXT(500)
);

CREATE TABLE pozicija_zaposlenika (
	id_zaposlenik INT NOT NULL,
    id_pozicija INT NOT NULL,
    FOREIGN KEY (id_zaposlenik) REFERENCES zaposlenik (id) ON DELETE CASCADE,
    FOREIGN KEY (id_pozicija) REFERENCES pozicija (id) ON DELETE CASCADE,
    PRIMARY KEY (id_zaposlenik, id_pozicija)
);

CREATE TABLE radna_smjena (
	id_zaposlenik INT NOT NULL,
    smjena ENUM('jutarnja', 'popodnevna') NOT NULL,
    datum DATE NOT NULL,
    FOREIGN KEY (id_zaposlenik) REFERENCES zaposlenik (id) ON DELETE CASCADE
);

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

CREATE TABLE recenzija_zaposlenika (
	id_zaposlenik INT NOT NULL REFERENCES zaposlenik (id) ON DELETE CASCADE,
    id_recenzija INT NOT NULL REFERENCES recenzija (id) ON DELETE CASCADE,
	PRIMARY KEY (id_zaposlenik, id_recenzija),
    FOREIGN KEY (id_zaposlenik) REFERENCES zaposlenik (id) ON DELETE CASCADE,
    FOREIGN KEY (id_recenzija) REFERENCES recenzija (id) ON DELETE CASCADE
); 

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

CREATE TABLE recenzija_paketa (
	id_paket INT NOT NULL REFERENCES paket (id) ON DELETE CASCADE,
    id_recenzija INT NOT NULL REFERENCES recenzija (id) ON DELETE CASCADE,
	PRIMARY KEY (id_paket, id_recenzija),
    FOREIGN KEY (id_paket) REFERENCES paket (id) ON DELETE CASCADE,
    FOREIGN KEY (id_recenzija) REFERENCES recenzija (id) ON DELETE CASCADE
);

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

CREATE TABLE kupon_rezervacija (
	id_kupon INT NOT NULL,
    id_rezervacija INT NOT NULL,
    PRIMARY KEY (id_kupon, id_rezervacija),
    FOREIGN KEY (id_kupon) REFERENCES kupon (id),
    FOREIGN KEY (id_rezervacija) REFERENCES rezervacija (id)
);


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

CREATE TABLE uplata (
	id INT AUTO_INCREMENT PRIMARY KEY,
    id_rezervacija INT NOT NULL,
    metoda ENUM('gotovina', 'kredit', 'debit', 'cek', 'redirect', 'wallet', 'paypal', 'ostalo') NOT NULL,
    iznos NUMERIC(10, 2) NOT NULL,
    vrijeme DATETIME NOT NULL, # Točno vrijeme uplate.
    CHECK (iznos > 0), # Uplata ničega ili negativnog iznosa nije važeća.
    FOREIGN KEY (id_rezervacija) REFERENCES rezervacija (id) ON DELETE CASCADE
);

CREATE TABLE posebni_zahtjev (
	id INT AUTO_INCREMENT PRIMARY KEY,
    id_rezervacija INT NOT NULL,
    opis TEXT(750),
    FOREIGN KEY (id_rezervacija) REFERENCES rezervacija (id) ON DELETE CASCADE
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
    id_hotel INT NOT NULL,
    id_paket INT NOT NULL,
    datum DATE, # datum kada taj paket ima predvidjeno boravljenje u tom hotelu
    FOREIGN KEY (id_hotel) REFERENCES hotel (id) ON DELETE CASCADE,
    FOREIGN KEY (id_paket) REFERENCES paket (id) ON DELETE CASCADE
);

CREATE TABLE recenzija_hotela (
	id_hotel INT NOT NULL REFERENCES hotel (id) ON DELETE CASCADE,
    id_recenzija INT NOT NULL REFERENCES recenzija (id) ON DELETE CASCADE,
	PRIMARY KEY (id_hotel, id_recenzija),
    FOREIGN KEY (id_hotel) REFERENCES hotel (id) ON DELETE CASCADE,
    FOREIGN KEY (id_recenzija) REFERENCES recenzija (id) ON DELETE CASCADE
);

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

CREATE TABLE recenzija_transporta (
	id_transport INT NOT NULL,
    id_recenzija INT NOT NULL,
    PRIMARY KEY (id_transport, id_recenzija),
    FOREIGN KEY (id_transport) REFERENCES transport (id) ON DELETE CASCADE,
    FOREIGN KEY (id_recenzija) REFERENCES recenzija (id) ON DELETE CASCADE
);

CREATE TABLE odrediste (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime VARCHAR(100) NOT NULL UNIQUE,
    id_grad INT NOT NULL,
    popularne_atrakcije VARCHAR(200),
    opis TEXT(500),
    FOREIGN KEY (id_grad) REFERENCES grad (id)
);

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

CREATE TABLE recenzija_aktivnosti (
	id_aktivnost INT NOT NULL REFERENCES aktivnost (id) ON DELETE CASCADE,
    id_recenzija INT NOT NULL REFERENCES recenzija (id) ON DELETE CASCADE,
	PRIMARY KEY (id_aktivnost, id_recenzija),
    FOREIGN KEY (id_aktivnost) REFERENCES aktivnost (id) ON DELETE CASCADE,
    FOREIGN KEY (id_recenzija) REFERENCES recenzija (id) ON DELETE CASCADE
);

CREATE TABLE vodic (
    id INT NOT NULL PRIMARY KEY,
	godine_iskustva INT NOT NULL,
	CHECK (godine_iskustva >= 0),
    FOREIGN KEY (id) REFERENCES osoba (id) ON DELETE CASCADE
);

CREATE TABLE recenzija_vodica (
	id_vodic INT NOT NULL REFERENCES vodic (id) ON DELETE CASCADE,
    id_recenzija INT NOT NULL REFERENCES recenzija (id) ON DELETE CASCADE,
	PRIMARY KEY (id_vodic, id_recenzija),
    FOREIGN KEY (id_vodic) REFERENCES vodic (id) ON DELETE CASCADE,
    FOREIGN KEY (id_recenzija) REFERENCES recenzija (id) ON DELETE CASCADE
);

CREATE TABLE putni_plan_stavka (
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
    id_paket INT NOT NULL, # poveznica sa paketom kojem pripada stavka
    id_transport INT, # poveznica sa transportom koji ukljucuje
    id_odrediste INT, # poveznica sa odredistem na koje ide
    id_aktivnost INT, # poveznica sa aktivnoscu koje ukljucuje
    id_vodic INT , # poveznica na vodica ako ova stavka ukljucuje jednog 
    opis TEXT(500) NOT NULL, # opis sto se dogadja u ovoj stavci
    pocetak DATETIME NOT NULL, # kada pocinje ovaj dio puta 
    trajanje_u_minutama INT, # koliko dugo traje u minutama dio puta okvirno, ne mora biti ukljuceno, u slucaju npr. idenja natrag u hotel
    FOREIGN KEY (id_paket) REFERENCES paket (id) ON DELETE CASCADE,
    FOREIGN KEY (id_transport) REFERENCES transport (id),
    FOREIGN KEY (id_odrediste) REFERENCES odrediste (id),
    FOREIGN KEY (id_aktivnost) REFERENCES aktivnost (id),
    FOREIGN KEY (id_vodic) REFERENCES vodic (id)
);


-- Odjeljak učitavanje podataka
SHOW VARIABLES LIKE "secure_file_priv";

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/cjepivo.csv'
	INTO TABLE cjepivo
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/kontinent.csv'
	INTO TABLE kontinent
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/drzava.csv'
	INTO TABLE drzava
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/drzava_kontinent.csv'
	INTO TABLE drzava_kontinent
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/cjepivo_drzava.csv'
	INTO TABLE cjepivo_drzava
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/grad.csv'
	INTO TABLE grad
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/adresa.csv'
	INTO TABLE adresa
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/osoba.csv'
	INTO TABLE osoba
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/dodatni_jezik.csv' 
	INTO TABLE dodatni_jezik
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n'
	IGNORE 1 ROWS
	(id_osoba, dodatni_jezik);

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/cijepljena_osoba.csv' 
	INTO TABLE cjepljena_osoba
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/recenzija.csv'
	INTO TABLE recenzija
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/zaposlenik.csv'
	INTO TABLE zaposlenik
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/pozicija.csv'
	INTO TABLE pozicija
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/pozicija_zaposlenika.csv'
	INTO TABLE pozicija_zaposlenika
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/radna_smjena.csv'
	INTO TABLE radna_smjena
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/stavka_korisnicke_podrske.csv'
	INTO TABLE stavka_korisnicke_podrske
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/recenzija_zaposlenika.csv'
	INTO TABLE recenzija_zaposlenika
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/paket.csv'
	INTO TABLE paket
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/recenzija_paketa.csv'
	INTO TABLE recenzija_paketa
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/rezervacija.csv'
	INTO TABLE rezervacija
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/kupon.csv' 
	INTO TABLE kupon
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n'
	IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/kupon_rezervacija.csv' 
	INTO TABLE kupon_rezervacija
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n'
	IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/osiguranje.csv'
	INTO TABLE osiguranje
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/uplata.csv' 
	INTO TABLE uplata
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n'
	(id_rezervacija, metoda, iznos, vrijeme);

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/posebni_zahtjev.csv'
	INTO TABLE posebni_zahtjev
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/hotel.csv'
	INTO TABLE hotel
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/hoteli_paketa.csv'
	INTO TABLE hoteli_paketa
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/recenzija_hotela.csv'
	INTO TABLE recenzija_hotela
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/transport.csv' 
	INTO TABLE transport
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n'
	IGNORE 1 ROWS; 

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/recenzija_transporta.csv'
	INTO TABLE recenzija_transporta
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/odrediste.csv'
	INTO TABLE odrediste
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/aktivnost.csv'
	INTO TABLE aktivnost
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/recenzija_aktivnosti.csv'
	INTO TABLE recenzija_aktivnosti
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/vodic.csv'
	INTO TABLE vodic
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/recenzija_vodica.csv'
	INTO TABLE recenzija_vodica
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/putni_plan_stavka.csv'
	INTO TABLE putni_plan_stavka
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n';

-- Odjeljak EXECUTABLES

-- Autor: Alan Burić

-- POGLEDI - pohranjeni upiti

-- Prikazuje sve IDjeve zaposlenika koji su putni agenti.
-- CREATE VIEW svi_putni_agenti AS SELECT id_zaposlenik AS id FROM pozicija_zaposlenika WHERE id_pozicija = (SELECT id FROM pozicija WHERE ime_pozicije = 'putni agent');

-- -- 1. Pronađi ID pozicije 'putni agent'
-- -- 2. Pronađi sve zaposlenike s tom pozicijom (preko IDja)
-- -- 3. Pobroji njihova pojavljivanja
-- -- 4. Sortiraj ih od najmanjeg prema najvećem

-- CREATE VIEW zaposlenost_rezervacije AS 
-- 	SELECT *, COUNT(*) AS kolicina_posla 
-- 		FROM svi_putni_agenti 
-- 			LEFT JOIN 
-- 	(SELECT zaposlenik_id AS id FROM rezervacija) AS rezervacija 
-- 			USING (id);

-- -- OKIDAČI - event handlers

-- -- Nužno je za razlikovanja završetka naredbe.
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

-- Autor: Juraj Štern-Vukotić

-- Koje cjepivo drzave zahtjevaju, ime drzave i cjepiva sa idevima
CREATE VIEW drzave_sa_cjepivima AS
SELECT drzava.id AS id_drzava, 
       drzava.naziv AS naziv_drzava, 
       cjepivo.id AS id_cjepivo, 
       cjepivo.naziv AS naziv_cjepivo
FROM drzava
INNER JOIN cjepivo_drzava ON drzava.id = cjepivo_drzava.id_drzava
INNER JOIN cjepivo ON cjepivo_drzava.id_cjepivo = cjepivo.id;

-- Prikaz iz koje je drzave osoba
CREATE VIEW drzava_osobe AS
SELECT osoba.id, drzava.id FROM osoba
JOIN adresa ON osoba.id_adresa = adresa.id
JOIN grad ON adresa.id_grad = grad.id
JOIN drzava ON grad.id_drzava = drzava.id;

-- Prikaz osoba sa materinjim jezikom
CREATE VIEW materini_jezik AS
SELECT osoba.id, drzava.jezik
FROM osoba
JOIN adresa ON osoba.id_adresa = adresa.id
JOIN grad ON adresa.id_grad = grad.id
JOIN drzava ON grad.id_drzava = drzava.id;

-- Prikaz svih jezika koje osoba prica sa materinjim
CREATE VIEW jezici_osobe AS
SELECT * FROM materini_jezik
UNION
SELECT osoba.id, dodatni_jezik.dodatni_jezik FROM dodatni_jezik
JOIN osoba WHERE dodatni_jezik.id_osoba = osoba.id;

-- Filtriramo zaposlenike iz jezika osoba
CREATE VIEW jezici_zaposlenika AS
SELECT zaposlenik.id, jezici_osobe.jezik FROM zaposlenik
JOIN jezici_osobe WHERE zaposlenik.id = jezici_osobe.id;

-- Ovdje nalazimo sve rezervacije gdje zaposlenik ne prica nijedan jezik ko osoba koje je rezervirala
CREATE VIEW rezervacija_krivi_jezik AS
SELECT rezervacija.id AS rezervacija_id, zaposlenik.id AS zaposlenik_id, osoba.id AS osoba_id
FROM rezervacija
JOIN zaposlenik ON rezervacija.id_zaposlenik = zaposlenik.id
JOIN osoba ON rezervacija.id_osoba = osoba.id
WHERE NOT EXISTS (
    SELECT 1
    FROM jezici_zaposlenika jz 
    JOIN jezici_osobe jo ON jz.jezik = jo.jezik
    WHERE jz.id = zaposlenik.id AND jo.id = osoba.id
);

-- Ovdje nalazimo sve stavke korisnicke podrske koje nisu rjesene gdje zaposlenik ne prica nijedan jezik ko osoba koje ju je podnjela
CREATE VIEW podrska_krivi_jezik AS
SELECT stavka_korisnicke_podrske.id AS stavka_korisnicke_podrske_id, zaposlenik.id AS zaposlenik_id, osoba.id AS osoba_id
FROM stavka_korisnicke_podrske
JOIN zaposlenik ON stavka_korisnicke_podrske.id_zaposlenik = zaposlenik.id
JOIN osoba ON stavka_korisnicke_podrske.id_osoba = osoba.id
WHERE NOT EXISTS (
    SELECT 1
    FROM jezici_zaposlenika jz 
    JOIN jezici_osobe jo ON jz.jezik = jo.jezik
    WHERE jz.id = zaposlenik.id AND jo.id = osoba.id
) AND stavka_korisnicke_podrske.status_problema != 'Rješeno';

-- Gledamo koliko su zaposlenici zaposleni odnosno za koliko su rezervacija i korisnickih podrski zasluzni
CREATE VIEW ZaposlenikView AS
SELECT z.id, COUNT(r.id) + COUNT(s.id) AS task_count
FROM zaposlenik z
LEFT JOIN rezervacija r ON r.id_zaposlenik = z.id
LEFT JOIN stavka_korisnicke_podrske s ON s.id_zaposlenik = z.id
GROUP BY z.id
ORDER BY task_count DESC;

-- Alternativni zaposlenici koji bi se mogli pridonjeti rezervacijama sa krivim jezikom
SELECT rezervacija_krivi_jezik.rezervacija_id, rezervacija_krivi_jezik.osoba_id, alt_zaposlenik.id AS id_zaposlenik
FROM rezervacija_krivi_jezik
JOIN jezici_osobe jo ON rezervacija_krivi_jezik.osoba_id = jo.id
JOIN jezici_zaposlenika jz ON jo.jezik = jz.jezik
JOIN zaposlenik alt_zaposlenik ON jz.id = alt_zaposlenik.id;

-- Alternativni zaposlenici koji bi se mogli pridonjeti rezervacijama sa krivim jezikom
SELECT podrska_krivi_jezik.stavka_korisnicke_podrske_id, podrska_krivi_jezik.osoba_id, alt_zaposlenik.id AS alt_zaposlenik_id
FROM podrska_krivi_jezik
JOIN jezici_osobe jo ON podrska_krivi_jezik.osoba_id = jo.id
JOIN jezici_zaposlenika jz ON jo.jezik = jz.jezik
JOIN zaposlenik alt_zaposlenik ON jz.id = alt_zaposlenik.id;

-- Za svaki datum koliko zaposlenika je u kojoj smjeni
SELECT datum, smjena, COUNT(id_zaposlenik) AS broj_zaposlenika
FROM radna_smjena
GROUP BY datum, smjena;

-- Prebrojati koliko imamo zaposlenika na nekoj poziciji
CREATE VIEW broj_pozicija AS
SELECT p.ime_pozicije, COUNT(pz.id_zaposlenik) AS broj_zaposlenika
FROM pozicija_zaposlenika pz
JOIN pozicija p ON pz.id_pozicija = p.id
GROUP BY p.ime_pozicije;

CREATE VIEW radna_smjena_view AS
SELECT datum, smjena, id_zaposlenik
FROM radna_smjena;

CREATE VIEW pozicija_zaposlenika_view AS
SELECT pz.id_zaposlenik, p.ime_pozicije
FROM pozicija_zaposlenika pz
JOIN pozicija p ON pz.id_pozicija = p.id;

-- Koliko je u svakoj smjeni određene pozicije zaposlenika
SELECT rs_view.datum, rs_view.smjena, pz_view.ime_pozicije, COUNT(rs_view.id_zaposlenik) AS broj_zaposlenika
FROM radna_smjena_view rs_view
JOIN pozicija_zaposlenika_view pz_view ON rs_view.id_zaposlenik = pz_view.id_zaposlenik
GROUP BY rs_view.datum, rs_view.smjena, pz_view.ime_pozicije;

-- nac broj rezervacija za svaki paket
SELECT p.naziv AS Paket, COUNT(r.id) AS Broj_Rezervacija
FROM paket p
LEFT JOIN rezervacija r ON p.id = r.id_paket
GROUP BY p.id;

-- naci sve posebne zahjeve za paket X
SELECT pz.*, os.puno_ime, os.kontaktni_broj
FROM posebni_zahtjev pz
JOIN rezervacija r ON pz.id_rezervacija = r.id
JOIN osoba os ON r.id_osoba = os.id
WHERE r.id_paket = X;

-- Naci sva osiguranja za paket X
SELECT o.*, os.puno_ime
FROM osiguranje o
JOIN rezervacija r ON o.id_rezervacija = r.id
JOIN osoba os ON r.id_osoba = os.id
WHERE r.id_paket = X;

-- naci sve rezervacije bez osiguranja za paket X
SELECT r.*, os.puno_ime, os.kontaktni_broj
FROM rezervacija r
JOIN osoba os ON r.id_osoba = os.id
LEFT JOIN osiguranje o ON r.id = o.id_rezervacija
WHERE r.id_paket = 1 AND o.id IS NULL;

######## za neku osobu naci sve destinacije u koju moze sa dokumentom, cjepivima i di zna jezik mozda?
######## naci za rezervaciju alternative neke stakve ako se ne svidja osobi naci ono na sto misli i ne svidja joj se jedan dio putne stavke, ponuditi alternative u blizini
######## nadji nadjbolje/najgore X po recenzijama, da bi mogli izbaciti ili vise koristiti nesto od toga kako bi paketi bili bolji

SELECT 
  paket.naziv AS PackageName,
  hotel.ime AS HotelName,
  transport.tip_transporta AS TransportType,
  transport.ime_tvrtke AS TransportCompany,
  vodic.godine_iskustva AS GuideExperienceYears,
  odrediste.ime AS DestinationName,
  aktivnost.ime AS ActivityName
FROM 
  putni_plan_stavka 
JOIN 
  paket ON putni_plan_stavka.id_paket = paket.id 
JOIN 
  hoteli_paketa ON paket.id = hoteli_paketa.id_paket 
JOIN 
  hotel ON hoteli_paketa.id_hotel = hotel.id
JOIN 
  transport ON putni_plan_stavka.id_transport = transport.id
JOIN 
  vodic ON putni_plan_stavka.id_vodic = vodic.id
JOIN 
  odrediste ON putni_plan_stavka.id_odrediste = odrediste.id
JOIN 
  aktivnost ON putni_plan_stavka.id_aktivnost = aktivnost.id
WHERE 
  paket.id = 49;

(SELECT 
  paket.naziv AS ReviewSubject,
  paketRecenzija.ocjena AS Rating,
  paketRecenzija.komentar AS Comment,
  osoba.puno_ime AS ReviewerName,
  paketRecenzija.datum AS ReviewDate
FROM 
  paket 
JOIN 
  recenzija_paketa ON paket.id = recenzija_paketa.id_paket 
JOIN 
  recenzija paketRecenzija ON recenzija_paketa.id_recenzija = paketRecenzija.id
JOIN 
  osoba ON paketRecenzija.id_osoba = osoba.id
WHERE 
  paket.id = 49)
UNION
(SELECT 
  vodic.id AS ReviewSubject,
  vodicRecenzija.ocjena AS Rating,
  vodicRecenzija.komentar AS Comment,
  osoba.puno_ime AS ReviewerName,
  vodicRecenzija.datum AS ReviewDate
FROM 
  vodic 
JOIN 
  recenzija_vodica ON vodic.id = recenzija_vodica.id_vodic 
JOIN 
  recenzija vodicRecenzija ON recenzija_vodica.id_recenzija = vodicRecenzija.id
JOIN 
  osoba ON vodicRecenzija.id_osoba = osoba.id
WHERE 
  vodic.id IN (SELECT id_vodic FROM putni_plan_stavka WHERE id_paket = 49))
UNION
(SELECT 
  hotel.ime AS ReviewSubject,
  hotelRecenzija.ocjena AS Rating,
  hotelRecenzija.komentar AS Comment,
  osoba.puno_ime AS ReviewerName,
  hotelRecenzija.datum AS ReviewDate
FROM 
  hotel 
JOIN 
  recenzija_hotela ON hotel.id = recenzija_hotela.id_hotel 
JOIN 
  recenzija hotelRecenzija ON recenzija_hotela.id_recenzija = hotelRecenzija.id
JOIN 
  osoba ON hotelRecenzija.id_osoba = osoba.id
WHERE 
  hotel.id IN (SELECT id_hotel FROM hoteli_paketa WHERE id_paket = 49))
UNION
(SELECT 
  transport.tip_transporta AS ReviewSubject,
  transportRecenzija.ocjena AS Rating,
  transportRecenzija.komentar AS Comment,
  osoba.puno_ime AS ReviewerName,
  transportRecenzija.datum AS ReviewDate
FROM 
  transport 
JOIN 
  recenzija_transporta ON transport.id = recenzija_transporta.id_transport 
JOIN 
  recenzija transportRecenzija ON recenzija_transporta.id_recenzija = transportRecenzija.id
JOIN 
  osoba ON transportRecenzija.id_osoba = osoba.id
WHERE 
  transport.id IN (SELECT id_transport FROM putni_plan_stavka WHERE id_paket = 49))
UNION
(SELECT 
  aktivnost.ime AS ReviewSubject,
  aktivnostRecenzija.ocjena AS Rating,
  aktivnostRecenzija.komentar AS Comment,
  osoba.puno_ime AS ReviewerName,
  aktivnostRecenzija.datum AS ReviewDate
FROM 
  aktivnost 
JOIN 
  recenzija_aktivnosti ON aktivnost.id = recenzija_aktivnosti.id_aktivnost 
JOIN 
  recenzija aktivnostRecenzija ON recenzija_aktivnosti.id_recenzija = aktivnostRecenzija.id
JOIN 
  osoba ON aktivnostRecenzija.id_osoba = osoba.id
WHERE 
  aktivnost.id IN (SELECT id_aktivnost FROM putni_plan_stavka WHERE id_paket = 49));


########sve drzave di moze osoba ici sa cjepivima dokumentima i jezicima
SELECT DISTINCT d.*
FROM drzava d
JOIN cjepivo_drzava cd ON d.id = cd.id_drzava
JOIN cjepljena_osoba co ON co.id_cjepivo = cd.id_cjepivo
WHERE co.id_osoba = 1389 AND d.id NOT IN (
  SELECT d.id
  FROM drzava d
  JOIN cjepivo_drzava cd ON d.id = cd.id_drzava
  LEFT JOIN cjepljena_osoba co ON co.id_cjepivo = cd.id_cjepivo AND co.id_osoba = 1
  WHERE co.id_cjepivo IS NULL
);


#SELECT id_osoba, id_zaposlenik FROM rezervacija
#JOIN jezici_osobe ON id_osoba;

-- CREATE VIEW studentski_ugovori AS
-- SELECT * FROM osoba
-- JOIN zaposlenik
-- ON osoba.id = zaposlenik.id
-- WHERE zaposlenik.ugovor_o_radu = "studentski";


-- Autor: Lucia Labinjan
SELECT
    paket.naziv AS Naziv_Paketa,
    COUNT(rezervacija.id) AS Broj_Rezervacija,
    AVG(
        CASE WHEN recenzija.ocjena IS NULL THEN 0 ELSE recenzija.ocjena END
    ) AS Prosjecna_Ocjena
FROM
    paket
LEFT JOIN
    rezervacija ON paket.id = rezervacija.id_paket
LEFT JOIN
    recenzija_paketa ON paket.id = recenzija_paketa.id_paket
LEFT JOIN
    recenzija ON recenzija_paketa.id_recenzija = recenzija.id
GROUP BY
    paket.naziv;


 CREATE VIEW paket_recenzije AS
SELECT
    paket.naziv AS PackageName,
    recenzija.ocjena AS ReviewRating,
    recenzija.komentar AS ReviewComment,
    recenzija.datum AS ReviewDate,
    osoba.puno_ime AS ReviewerName
FROM
    paket
JOIN
    recenzija_paketa ON paket.id = recenzija_paketa.id_paket
JOIN
    recenzija ON recenzija_paketa.id_recenzija = recenzija.id
JOIN
    osoba ON recenzija.id_osoba = osoba.id;


-- Create a view linking support tickets to the person who created them
CREATE VIEW korisnicke_podrske AS
SELECT
    skp.vrsta_problema AS SupportTicketType,
    skp.opis_problema AS SupportTicketDescription,
    skp.status_problema AS SupportTicketStatus,
    osoba.puno_ime AS PersonName
FROM
    stavka_korisnicke_podrske skp
JOIN
    osoba ON skp.id_osoba = osoba.id;


-- Retrieve all the package reviews written by a person who has also made a support ticket
SELECT
    pr.PackageName,
    pr.ReviewRating,
    pr.ReviewComment,
    pr.ReviewDate,
    kp.SupportTicketType,
    kp.SupportTicketDescription,
    kp.SupportTicketStatus
FROM
    paket_recenzije pr
JOIN
    korisnicke_podrske kp ON pr.ReviewerName = kp.PersonName;



--


-- Autor: Mateo Udovčić

-- Autor: Karlo Bazina

-- osoba XX se zeli uzivo naci u popodnevnim satima sa nasim zaposlenikom
-- Pronađi sve zaposlenike 'turistički agent', koji XX datuma rade 'popodnevna smjenu' i nalaze se u gradu gdje je osoba XX, 
-- te ih poredaj po veličini prihoda (pretpostavka je da je najbolji zaposelnik najplaćeniji) 

-- pronadi sve zaposelnika koji rade 'na odredeno' ili 'na neodredeno' te svima koji imaju vise od 5 ocijena, a prosijek ocjena je veci od 4,5 povecaj placu za 10%

-- predstavljanje kompanije je
-- prikaži mi samo zaposelnika sa najvecom placom iz gradova (Zagreb, Split, Rijeka, Osijek) 

-- prikaži mi 3 zaposelnika koja pričaju najviše stranih jezika, a jedan od tih jezikam ora biti njemački


-- Odjeljak VRIJEDNOSTI

/*
 * Ukoliko je MySQL server (lokalno na računalu ili negdje drugdje) inicijaliziran sa opcijom
 * --secure_file_priv, koristit će samo postavljenu mapu čija je putanja navedena u rezultatu
 * sljedećeg upita. Potom se ta mapa može upotrebljavati za pohranu datoteka za učitavanje i
 * zapis.
 * Očekivani rezultat: C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/
 * Ukoliko se rezultat razlikuje, lokalno promijenite u skripti datoteku te tamo postavite datoteke.
 */
 
--  INSERT INTO putni_plan_stavka (id, id_paket, id_transport, id_odrediste, id_aktivnost, id_vodic, opis, pocetak, trajanje_u_minutama)
--  VALUES (1, 1, 253, 736, 327, 1, 'Visit Zagreb Cathedral, located in the heart of the city. Explore the stunning interior, including beautiful stained glass windows and an impressive altar. Afterwards, take a walk around Jelacic Square and savor the flavors of Croatian traditional food.', '2023-06-01 09:00:00', 180),
-- 		(2, 1, 253, NULL, NULL, 1, 'We will return to the Zagreb hotel for a well-deserved rest and a delicious dinner nearby. Recharge and relax in the hotels comfortable ambiance, savoring local cuisine and preparing for the next days adventures.', '2023-06-01 12:00:00', 30),
--         (3, 1, 253, 737, NULL, 1, 'Visiting Mirogoj will be an unforgettable experience. This beautiful cemetery park in Zagreb offers a peaceful oasis for walking and contemplation. After exploring Mirogoj, its time for us to part ways and head back to our respective homes.' '2023-06-01 09:00:00', 180),
--         (4, 2, 209, 740, 327, 1, 'X' '2023-06-01 09:00:00', 180),
--         (1, 1, 253, 736, 327, 1, 'X' '2023-06-01 09:00:00', 180);
-- 		
--  ;
 
--  INSERT INTO hotel (ime, id_adresa, kontaktni_broj, email, slobodne_sobe, pogodnosti, opis)
-- VALUES ('Hotel Pula', 1834, '123454321', 'hotelpula@example.com', 100, "['Free Wi-Fi', 'Swimming Pool', 'Spa']", 'A luxurious hotel situated in the beautiful city of Pula, offering stunning views of the Adriatic Sea and top-notch amenities for a memorable stay.'),
-- 		('Hotel Osijek', 1843, '383654322', 'hotelosijek@example.com', 80, "['Free Wi-Fi', 'Fitness Center', 'Conference Rooms']", 'A modern hotel located in the vibrant city of Osijek, offering comfortable accommodations and excellent facilities for both business and leisure travelers.'),
-- 		('Hotel Sakura', 752, '9935437899', 'hotelsakura@example.com', 120, "['Free Wi-Fi', 'Swimming Pool', 'Spa']", 'A serene and elegant hotel nestled amidst the cherry blossoms in Hiroshima, offering a harmonious blend of traditional Japanese hospitality and modern comforts.');
#id ovog hotela pula amora biti 189 
#ID OSIJEK 190
#HIROSHIMA 191


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
-- id paketa posebnog zahtjeva
-- SELECT * FROM stavka_korisnicke_podrske;
-- SELECT * FROM rezervacija;
-- SELECT * FROM kupon_rezervacija;
-- SELECT * FROM grad JOIN drzava ON grad.id_drzava = drzava.id;

-- SELECT DISTINCT id_vodic
-- FROM recenzija_vodica
-- WHERE id_vodic NOT IN (SELECT id FROM vodic);

#SELECT * FROM putni_plan_stavka;

-- SELECT * FROM recenzija_transporta WHERE id_recenzija = 0; 
