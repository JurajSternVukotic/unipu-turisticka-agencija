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
    pokrice VARCHAR (200) NOT NULL,
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
    valuta VARCHAR(50) NOT NULL, # Ime valute koja se koristi
    tecaj_u_eurima NUMERIC(10, 6) NOT NULL, # Koliko je jedan euro vrijedan ove valute 
    dokumenti_za_ulaz TEXT(500), # Kratki opis kakva je trenutna procedura za ulazak u drzavu, kasnije se moze dodati tablica koja gleda relaciju izmedju svake dvije drzave
    jezik VARCHAR(50) NOT NULL, # Naziv jezika koji se prica
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
    puno_ime VARCHAR(100) NOT NULL,
	datum_rodenja DATE NOT NULL,
	kontaktni_broj VARCHAR(15) NOT NULL UNIQUE,
	email VARCHAR(100) NOT NULL UNIQUE,
    korisnicki_bodovi INT NOT NULL DEFAULT 0,
    CHECK (korisnicki_bodovi >= 0),
    id_adresa INT NOT NULL REFERENCES adresa (id)
);

CREATE TABLE dodatni_jezik (
    id_osoba INT NOT NULL REFERENCES osoba (id) ON DELETE CASCADE,
    dodatni_jezik VARCHAR (50) NOT NULL,
    PRIMARY KEY (id_osoba, dodatni_jezik)
);
    
-- Autor: Lucia Labinjan

CREATE TABLE vodic (
    id INT NOT NULL PRIMARY KEY REFERENCES osoba (id) ON DELETE CASCADE,
	godine_iskustva INT NOT NULL,
	CHECK (godine_iskustva >= 0)
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

CREATE TABLE aktivnost (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime VARCHAR(100) NOT NULL UNIQUE,
    opis TEXT(500),
    cijena NUMERIC(10,2) NOT NULL, 
    id_adresa INT NOT NULL REFERENCES adresa (id) ON DELETE CASCADE,
    trajanje INT NOT NULL,
    vrijeme_odlaska TIME NOT NULL,
    CHECK (cijena >= 0),
    CHECK (trajanje> 0)
);

CREATE TABLE cjepivo (
	id INT AUTO_INCREMENT PRIMARY KEY,
    naziv ENUM('Žuta groznica', 'Hepatitis A', 'Hepatitis B', 'Hepatitis C', 'Tifus', 'Bjesnoća', 'Japanski encefalitis', 'Polio', 'Meningokokni meningitis', 'COVID-19', 'Ebola', 'Malarija', 'Gripa', 'Tetanus', 'Kolera', 'Ospice', 'Zaušnjaci', 'Rubela', 'Difterija', 'Hripavost', 'Vodene kozice') UNIQUE
);

CREATE TABLE kontinent (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime VARCHAR(25) NOT NULL UNIQUE,
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
	id_cjepivo INT NOT NULL REFERENCES cjepivo (id),
    id_osoba INT NOT NULL REFERENCES osoba (id)
);

CREATE TABLE odrediste (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime VARCHAR(100) NOT NULL UNIQUE,
    id_grad INT NOT NULL REFERENCES grad (id),
    popularne_atrakcije VARCHAR(200),
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
    id INT NOT NULL PRIMARY KEY REFERENCES osoba (id) ON DELETE CASCADE,
    ugovor_o_radu ENUM ('studentski', 'honorarno', 'na neodređeno','na određeno') NOT NULL,
    plaća NUMERIC (10, 2) NOT NULL,
    CHECK (plaća >= 0)
);

CREATE TABLE pozicija (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime_pozicije ENUM ('turistički agent', 'putni agent', 'računovođa', 'promotor', 'IT podrška') NOT NULL UNIQUE,
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

CREATE VIEW gradovi_sa_drzavama AS
SELECT grad.id as grad_id, grad.naziv as grad_naziv, drzava.naziv as drzava_naziv, drzava.id as drzava_id FROM grad
JOIN drzava ON grad.id_drzava = drzava.id;

CREATE VIEW drzava_grad_adresa AS
SELECT drzava_naziv, grad_naziv, adresa.naziv_ulice AS ulica, adresa.id AS adresa_id 
FROM gradovi_sa_drzavama 
JOIN adresa
ON grad_id = adresa.id_grad; 

CREATE VIEW drzave_sa_cjepivima AS
SELECT drzava.id AS id_drzava, 
       drzava.naziv AS naziv_drzava, 
       cjepivo.id AS id_cjepivo, 
       cjepivo.naziv AS naziv_cjepivo
FROM drzava
INNER JOIN cjepivo_drzava ON drzava.id = cjepivo_drzava.id_drzava
INNER JOIN cjepivo ON cjepivo_drzava.id_cijepiva = cjepivo.id;

CREATE VIEW drzava_grad_adresa_hotel AS
SELECT drzava_naziv, grad_naziv, ulica, adresa_id, hotel.ime AS hotel_naziv, hotel.id AS hotel_id
FROM drzava_grad_adresa
JOIN hotel
ON adresa_id = hotel.id_adresa;

-- CREATE VIEW studentski_ugovori AS
-- SELECT * FROM osoba
-- JOIN zaposlenik
-- ON osoba.id = zaposlenik.id
-- WHERE zaposlenik.ugovor_o_radu = "studentski";


-- Autor: Lucia Labinjan
-- SELECT a.*
-- FROM adresa a
-- LEFT JOIN hotel h
-- ON a.id = h.id_adresa
-- WHERE h.id_adresa IS NULL;

-- SELECT g.naziv AS naziv_grad, o.ime AS naziv_odrediste, a.naziv_ulice, a.id AS id_adresa, o.id
-- FROM odrediste AS o
-- JOIN grad AS g ON o.id_grad = g.id
-- JOIN adresa AS a ON a.id_grad = g.id
-- LEFT JOIN hotel AS h ON a.id = h.id_adresa
-- WHERE h.id_adresa IS NULL;

-- 1.List all packages a person has booked
-- 2.List all the countries and the total number of persons from that country
-- 3. apply a 10% discount to the price of reservations that have an associated coupon with a discount greater than 20%
-- 4. the count of reservations for each insurance
-- 5.the most expensive reservation for each package
-- 6.list of customers who have spent more than $5000, sorted by total expenditure
-- 7. Get the information about the packages that a certain user has booked
-- 8. Get the list of all tourist packages with the number of available places (maximum places - filled places)
-- 9.Get a report of all the payments made within a certain time period, including the reservation details
-- 10.Find all the packages which are insured by a specific insurance provider
-- 11.Select the top 5 most popular packages (in terms of reservations)
-- 12. Create a VIEW that shows a summary of the total sales by product
-- 13.create a view that aggregates all bookings by destination, and then shows the destinations sorted by popularity
-- 14. Client Travel History- view shows all trips a particular client has made, sorted by the booking date
-- 15. all packages that have not been booked yet



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
 
INSERT INTO paket (id, naziv, opis, min_ljudi, max_ljudi, popunjenih_mjesta, cijena_po_turistu) 
VALUES 
    (1, 'Zagreb Discovery', 'Explore the hidden gems of Zagreb, the vibrant capital of Croatia. Discover its rich history and enjoy the local cuisine.', 2, 6, 0, 300.00),
    (2, 'Dubrovnik Adventure', 'Embark on an exciting adventure in the breathtaking city of Dubrovnik. Explore its medieval walls and indulge in the beauty of the Adriatic Sea.', 4, 10, 0, 500.00),
    (3, 'Zadar Sunset Cruise', 'Experience the magic of Zadar with a mesmerizing sunset cruise. Enjoy the beautiful coastline and witness the famous Sea Organ.', 2, 8, 4, 200.00),
    (4, 'Pula Roman Heritage', 'Immerse yourself in the rich Roman heritage of Pula. Explore the ancient amphitheater and stroll through the charming streets of the old town.', 2, 4, 1, 250.00),
    (5, 'Rijeka Coastal Escape', 'Escape to the picturesque coastal city of Rijeka. Relax on the stunning beaches and indulge in delicious seafood cuisine.', 2, 6, 0, 350.00),
    (6, 'Šibenik Island Hopping', 'Embark on an island-hopping adventure from Šibenik. Discover the hidden gems of the Adriatic islands and soak up the sun and crystal-clear waters.', 4, 8, 0, 400.00),
    (7, 'Osijek Countryside Retreat', 'Experience the tranquility of the Osijek countryside. Enjoy the picturesque landscapes, visit local vineyards, and taste traditional delicacies.', 6, 12, 7, 280.00),
    (8, 'Los Angeles Hollywood Glam', 'Indulge in the glitz and glamour of Hollywood in Los Angeles. Visit iconic landmarks, stroll along the Walk of Fame, and experience the vibrant nightlife.', 2, 4, 1, 800.00),
    (9, 'New York City Explorer', 'Immerse yourself in the energy of New York City. Discover iconic attractions, enjoy world-class shopping, and savor diverse culinary delights.', 4, 10, 1, 1000.00),
    (10, 'Miami Beach Getaway', 'Escape to the tropical paradise of Miami Beach. Relax on the pristine beaches, experience vibrant nightlife, and enjoy water sports and shopping.', 2, 6, 5, 600.00),
    (11, 'Singapore Urban Adventure', 'Embark on an urban adventure in the dynamic city-state of Singapore. Explore futuristic architecture, savor diverse street food, and visit world-class attractions.', 2, 8, 3, 700.00),
    (12, 'Sydney Harbor Cruise', 'Experience the beauty of Sydney on a harbor cruise. Sail past iconic landmarks, enjoy panoramic views, and soak up the vibrant atmosphere of the city.', 4, 12, 0, 450.00),
    (13, 'Tel Aviv Beach Retreat', 'Relax and unwind on the stunning beaches of Tel Aviv. Enjoy vibrant nightlife, explore the ancient city of Jaffa, and indulge in delicious Mediterranean cuisine.', 2, 6, 0, 550.00),
    (14, 'Jerusalem Holy Pilgrimage', 'Embark on a sacred pilgrimage to Jerusalem. Visit holy sites, experience the spiritual atmosphere, and explore the rich history of this ancient city.', 4, 10, 2, 400.00),
    (15, 'Warsaw Cultural Immersion', 'Immerse yourself in the vibrant cultural scene of Warsaw. Explore historic landmarks, visit world-class museums, and indulge in traditional Polish cuisine.', 2, 4, 6, 300.00),
    (16, 'Madrid Tapas Tour', 'Embark on a culinary adventure in the vibrant city of Madrid. Sample delicious tapas, explore the art scene, and experience the lively Spanish culture.', 4, 8, 0, 350.00),
    (17, 'Barcelona Gaudi Experience', 'Discover the architectural wonders of Barcelona inspired by Gaudi. Visit iconic landmarks such as Sagrada Familia and Park Güell, and enjoy the vibrant atmosphere.', 2, 6, 1, 450.00),
    (18, 'London Royal Retreat', 'Experience the elegance of London on a royal retreat. Visit historic palaces, explore world-class museums, and indulge in traditional afternoon tea.', 4, 12, 0, 600.00),
    (19, 'Prague Bohemian Escape', 'Escape to the bohemian charm of Prague. Wander through cobbled streets, visit fairytale-like castles, and enjoy the lively nightlife and local beer.', 2, 4, 0, 250.00),
    (20, 'Dublin Pub Crawl', 'Experience the lively pub culture of Dublin. Enjoy traditional Irish music, visit historic pubs, and savor the taste of famous Irish whiskey.', 4, 10, 0, 300.00),
    (21, 'Hiroshima Peace Journey', 'Embark on a journey of peace in Hiroshima. Visit the Peace Memorial Park, learn about the citys history, and experience the resilience of its people.', 2, 8, 3, 400.00),
    (22, 'Paris Romantic Escape', 'Indulge in a romantic escape in the City of Love, Paris. Stroll along the Seine, visit world-renowned museums, and experience the enchanting atmosphere.', 2, 4, 3, 600.00),
    (23, 'Berlin Street Art Tour', 'Explore the vibrant street art scene of Berlin. Discover colorful murals, visit alternative neighborhoods, and immerse yourself in the citys creative spirit.', 4, 8, 4, 350.00),
    (24, 'Tokyo Anime Adventure', 'Embark on an anime adventure in Tokyo. Visit anime-themed cafes, explore vibrant neighborhoods like Akihabara, and experience the unique pop culture.', 4, 12, 6, 800.00),
    (25, 'Graz Wine Tasting', 'Savor the flavors of Graz on a wine tasting journey. Explore the vineyards of Styria, sample exquisite wines, and indulge in regional delicacies.', 2, 6, 0, 300.00),
    (26, 'Buenos Aires Tango Experience', 'Immerse yourself in the passionate world of tango in Buenos Aires. Learn to dance tango, enjoy live performances, and discover the vibrant culture of Argentina.', 4, 10, 0, 400.00),
    (27, 'Rio de Janeiro Carnival Spectacular', 'Experience the excitement of Carnival in Rio de Janeiro. Witness the colorful parades, dance to samba rhythms, and soak up the vibrant energy of the city.', 2, 8, 1, 600.00),
    (28, 'Oslo Fjord Cruise', 'Cruise through the breathtaking fjords of Oslo. Marvel at the stunning landscapes, explore charming coastal villages, and experience the tranquility of nature.', 2, 4, 3, 500.00),
    (29, 'Porto Wine and Port Tasting', 'Indulge in the rich flavors of Porto with a wine and port tasting experience. Visit famous cellars, sample a variety of wines, and explore the charming streets of Porto.', 4, 10, 5, 350.00),
    (30, 'Lisbon Coastal Discovery', 'Discover the beauty of Lisbon and its stunning coastline. Explore historic landmarks, relax on picturesque beaches, and indulge in delicious Portuguese cuisine.', 2, 6, 0, 400.00),
    (31, 'Leipzig Music and Culture', 'Immerse yourself in the music and culture of Leipzig. Visit historic music venues, attend classical concerts, and explore the vibrant arts scene of the city.', 2, 4, 0, 300.00),
    (32, 'Rome Historical Journey', 'Embark on a historical journey through the ancient city of Rome. Visit iconic landmarks such as the Colosseum and the Vatican, and immerse yourself in the rich history.', 4, 8, 2, 500.00),
    (33, 'Milan Fashion and Shopping', 'Experience the world of fashion and luxury in Milan. Shop at high-end boutiques, admire stunning architecture, and indulge in gourmet Italian cuisine.', 2, 6, 0, 700.00),
    (34, 'Moscow Kremlin Tour', 'Explore the grandeur of the Moscow Kremlin. Visit historic palaces, admire iconic cathedrals, and delve into the rich history and culture of Russia.', 2, 4, 3, 400.00),
    (35, 'Ibiza Beach Party', 'Party in style on the legendary island of Ibiza. Dance the night away at world-famous clubs, relax on stunning beaches, and experience the vibrant nightlife.', 4, 12, 0, 600.00),
    (36, 'Toronto City Escape', 'Escape to the multicultural city of Toronto. Explore diverse neighborhoods, visit iconic landmarks such as the CN Tower, and indulge in global cuisine.', 2, 8, 1, 350.00),
    (37, 'Ottawa Capital Discovery', 'Discover the charm of Canada\'s capital, Ottawa. Visit historic sites, explore national museums, and enjoy the picturesque Rideau Canal.', 2, 6, 1, 300.00),
    (38, 'Beijing Great Wall Adventure', 'Embark on an adventure to the Great Wall of China from Beijing. Hike along the ancient wall, learn about its history, and admire the breathtaking views.', 4, 10, 9, 500.00),
    (39, 'Istanbul Bosphorus Cruise', 'Cruise along the mesmerizing Bosphorus Strait in Istanbul. Marvel at the stunning waterfront palaces, experience Turkish hospitality, and indulge in delicious cuisine.', 2, 4, 2, 400.00);

 
SHOW VARIABLES LIKE "secure_file_priv";

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/kontinent.csv' 
	INTO TABLE kontinent 
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n' ;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/drzava.csv' 
	INTO TABLE drzava 
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n' ;
    
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/drzava_kontinent.csv' 
	INTO TABLE drzava_kontinent
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n' ;    
    
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
    
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/cjepivo.csv' 
	INTO TABLE cjepivo
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n';
    
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/cjepivo_drzava.csv' 
	INTO TABLE cjepivo_drzava
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n';
    
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/hotel.csv' 
	INTO TABLE hotel
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n';    

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/pozicija.csv' 
	INTO TABLE pozicija
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n'; 
    
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/kupon.csv' 
	INTO TABLE kupon
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n' 
	IGNORE 1 ROWS
    (kod, datum_pocetka, datum_kraja, iznos, postotni);
    
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/osiguranje.csv' 
	INTO TABLE osiguranje
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n'; 

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/pokrice_osiguranja.csv' 
	INTO TABLE pokrice_osiguranja
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n'; 

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/transport.csv' 
	INTO TABLE transport
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS
    (tip_transporta, kapacitet, cijena, ime_tvrtke, telefonski_broj, email, trajanje_u_minutama); 

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
	
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/osoba.csv' 
	INTO TABLE osoba
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n'; 

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/cijepljena_osoba.csv' 
	INTO TABLE cijepljena_osoba
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS
    (id_cjepivo, id_osoba);

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/dodatni_jezik.csv' 
	INTO TABLE dodatni_jezik
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n'
    IGNORE 1 ROWS
    (id_osoba, dodatni_jezik);

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/zaposlenik.csv' 
	INTO TABLE zaposlenik
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/pozicija_zaposlenika.csv' 
	INTO TABLE pozicija_zaposlenika
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/vodic.csv' 
	INTO TABLE vodic
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/radna_smjena.csv' 
	INTO TABLE radna_smjena
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"' 
	LINES TERMINATED BY '\r\n';
    
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
-- SELECT * FROM osiguranje;
-- SELECT * FROM pokrice_osiguranja;	
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


