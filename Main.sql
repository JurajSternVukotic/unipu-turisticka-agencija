DROP DATABASE IF EXISTS Turisticka_agencija;

CREATE DATABASE Turisticka_agencija;
USE Turisticka_agencija;


-- Alanov dio
CREATE TABLE Osiguranje (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime VARCHAR(128) NOT NULL,
    opis TINYTEXT,
    cijena NUMERIC(10, 2) NOT NULL
);

CREATE TABLE Popust (
	id INT AUTO_INCREMENT PRIMARY KEY,
    kod VARCHAR(20) NOT NULL,
    pocetak DATETIME NOT NULL,
    kraj DATETIME NOT NULL,
    kolicina NUMERIC (10, 2) NOT NULL,
    # Radi li se o postotnom popustu ili o oduzimanju kolicinom?
    postotni BOOL NOT NULL,
    CHECK (pocetak < kraj),
    # Postotak ne bi trebao prekoraciti 100%
    CHECK (NOT postotni OR kolicina <= 100)
);

CREATE TABLE Rezervacija (
	id INT AUTO_INCREMENT PRIMARY KEY,
    korisnik_id INT NOT NULL REFERENCES Korisnik (id) ON DELETE CASCADE,
    paket_id INT NOT NULL REFERENCES Paket (id) ON DELETE CASCADE,
    naziv VARCHAR(64),
    davatelj VARCHAR(64),
    datum DATETIME,
    cijena NUMERIC(10, 2)
);

CREATE TABLE Posebni_zahtjev (
	id INT AUTO_INCREMENT PRIMARY KEY,
    rezervacija_id INT NOT NULL REFERENCES Rezervacija (id) ON DELETE CASCADE,
    opis TEXT(500)
);

CREATE TABLE Osiguranje_Rezervacije (
    rezervacija_id INT NOT NULL REFERENCES Rezervacija (id) ON DELETE CASCADE,
    osiguranje_id INT NOT NULL REFERENCES Osiguranje (id) ON DELETE CASCADE
);

CREATE TABLE Uplata (
	id INT AUTO_INCREMENT PRIMARY KEY,
    rezervacija_id INT NOT NULL REFERENCES Rezervacija (id)  ON DELETE CASCADE,
    metoda ENUM('gotovina', 'kredit', 'debit', 'cek', 'redirect', 'transfer', 'voucher', 'wallet', 'ostalo') NOT NULL,
    kolicina NUMERIC(10, 2) NOT NULL,
    datum DATETIME NOT NULL
);

-- Jurjev dio
CREATE TABLE Grad(
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
    naziv VARCHAR(64) NOT NULL, # Najduzi naziv grada na svijetu ima 58 znakova, 64 bi trebalo biti dovoljno
    opis TEXT(500), # 500 znakova bi trebalo biti dovoljno za opis da ne bude predug
    Postanski_Broj VARCHAR(32) NOT NULL UNIQUE # Postanski brojevi mogu imati i slova, u nasem modelu jedan grad ima jedan postanski broj za razliku od inace gdje svaka ulica moze imati u nekim drzavama
);

CREATE TABLE Adresa(
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
	naziv_ulice VARCHAR(128) NOT NULL, # 128 bi trebalo biti dovoljno za bilo koju ulicu
    broj_ulice INT NOT NULL, # Ulica mora imati broj
	CHECK (broj_ulice > 0), # broj ulice mora biti strogo veci od 0
    dodatan_opis TEXT(256) # Dodatne informacije o kako doci do ulice, koji kat, itd.
);

CREATE TABLE Grad_Adrese( # povezuje gradove sa adresama, ako nestane grad ili adresa se ovo brise
	id_grad INT NOT NULL REFERENCES Grad (id) ON DELETE CASCADE, 
    id_adresa INT NOT NULL REFERENCES Adresa (id) ON DELETE CASCADE
);

CREATE TABLE Drzava(
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

CREATE TABLE Drzava_Grada( # povezuje gradove sa drzavama, ako nestane grad ili drzava se ovo brise (nuklarna eksplozija)
	id_Drzava INT NOT NULL REFERENCES Drzava (id) ON DELETE CASCADE,
    id_Grad INT NOT NULL REFERENCES Grad (id) ON DELETE CASCADE
);

CREATE TABLE Stavka_Korisnicke_Podrske( #support ticket
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
    # Mozda treba napraviti specijalnu tablicu sa id stavke, id korisnika i id zaposnelika???
	id_korisnik INT NOT NULL REFERENCES Korisnik (id), # zelimo znati koji korisnik je zatrazio podrsku, i da to ostane cak i ako korisnika vise nema
    id_zaposlenik INT NOT NULL REFERENCES Zaposlenik (id), # zelimo uvijek imati tocno jednu osobu koja radi na ovoj podrsci, i da ostane cak i ako taj zaposlenik ode 
    vrsta_problema ENUM ('Placanje', 'Rezervacija', 'Problemi sa zaposlenicima', 'Tehnicki problemi', 'Povrat novca', 'Drugo') NOT NULL, # ticket podrske moze biti samo jedna od ovih stvari
    opis_problema TEXT (2500), # opis problema mora biti teksutalan i imati manje od 2500 znakova
    CHECK (LENGTH(opis_problema) >= 50), # opis mora imati vise od 49 znakova kako bi smanjili zlouporabu sa praznim ili nedostatnim opisima 
	status_problema ENUM('Zaprimljeno', 'U obradi', 'Na cekanju', 'Rjeseno') NOT NULL # svaki ticket ima svoje stanje, ovisno u kojoj fazi proceisranja je
);

CREATE TABLE Paket(
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
    naziv VARCHAR (64) NOT NULL UNIQUE, # unique kako ne bi imali duplikatne nazive paketa, 64 znakova bi trebalo biti dovoljno za naslov 
    opis TEXT (1000), # 1000 znakova za opis paketa, ako se zele detaljne informacije moze se poslati upit za putni plan
    min_ljudi INT NOT NULL DEFAULT 1, # minimalno ljudi koliko je potrebno da se odrzi putovanje 
    max_ljudi INT NOT NULL DEFAULT 1, # maksimalno ljudi koji mogu sudjelovati na putovanju
    CHECK (min_ljudi >= 1), # ne mozemo imati paket za manje od jednu osobu
    CHECK (max_ljudi >= min_ljudi), # maksimalan broj ljudi mora biti jednak ili veci od minimalnog
    popunjenih_mjesta INT NOT NULL DEFAULT 0,
    CHECK (popunjenih_mjesta < max_ljudi), # ne moze biti vise popunjenih mjesta od max
    CHECK (popunjenih_mjesta >= 0), # ne moze biti negativno ljudi
    pocetak_puta DATETIME NOT NULL, # datum i vrijeme kada put pocinje 
    kraj_puta DATETIME NOT NULL, # datum i vrijeme kada put zavrsava
    cijena_po_turistu NUMERIC(10, 2) NOT NULL # koliko kosta za jednu osobu paket
);

CREATE TABLE Putni_Plan_Stavka(
	id INT AUTO_INCREMENT PRIMARY KEY, # ID je numericki, sam se povecava kako ne bi morali unositi uvijek, te nam je to primarni kljuc uvijek
    id_paket INT NOT NULL REFERENCES Paket (id) ON DELETE CASCADE, # poveznica sa paketom kojem pripada stavka
    id_transport INT NOT NULL REFERENCES transport (id) ON DELETE CASCADE, # poveznica sa transportom koji ukljucuje
    id_odrediste INT NOT NULL REFERENCES odrediste (id) ON DELETE CASCADE, # poveznica sa odredistem na koje ide
    id_aktivnost INT NOT NULL REFERENCES aktivnost (id) ON DELETE CASCADE, # poveznica sa aktivnoscu koje ukljucuje
    id_vodic INT REFERENCES vodic (id) ON DELETE CASCADE, # poveznica na vodica ako ova stavka ukljucuje jednog 
    opis TEXT(500) NOT NULL, # opis sto se dogadja u ovoj stavci
    upute TEXT(500), # dodatne upute ako su potrebne
    pocetak DATETIME NOT NULL, # kada pocinje ovaj dio puta 
    trajanje_u_minutama INT # koliko dugo traje u minutama dio puta okvirno, ne mora biti ukljuceno, u slucaju npr. idenja natrag u hotel
);


    
-- lucijin dio

CREATE TABLE Vodic (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ime VARCHAR(50) NOT NULL,
  prezime VARCHAR(50) NOT NULL,
  datum_rodenja DATE NOT NULL CHECK (datum_rodenja <= CURRENT_DATE),
  CHECK ((CURRENT_DATE - datum_rodenja) / 365 >= 18),
  kontaktni_broj VARCHAR(15) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  jezik_pricanja VARCHAR(50) NOT NULL,
  godine_iskustva INT NOT NULL CHECK (godine_iskustva >= 0)
);

CREATE TABLE Transport (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tip_transporta ENUM ('bus', 'avion', 'brod', 'vlak'),
  kapacitet INT NOT NULL CHECK (kapacitet >= 0),
  cijena NUMERIC(10, 2) NOT NULL CHECK (cijena >= 0),
  ime_tvrtke VARCHAR(100) NOT NULL,
  telefonski_broj VARCHAR(15) NOT NULL UNIQUE, 
  email VARCHAR(50) NOT NULL UNIQUE,
  vrijeme_odlaska DATETIME NOT NULL,
  vrijeme_dolaska  DATETIME NOT NULL,
  CHECK (vrijeme_dolaska > vrijeme_odlaska)
);

CREATE TABLE Aktivnosti (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ime VARCHAR(100) NOT NULL UNIQUE,
  opis TEXT(500),
  cijena NUMERIC(10,2) NOT NULL CHECK (cijena >= 0),
  id_adresa INT,
  vrijeme_trajanja INT NOT NULL CHECK (duracija > 0),
  vrijeme_odlaska TIME NOT NULL,
  id_recenzija INT,
  FOREIGN KEY (id_recenzije) REFERENCES recenzije(id),
  FOREIGN KEY (id_adresa) REFERENCES adresa(id) ON DELETE CASCADE

);

CREATE TABLE Kontinent (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ime VARCHAR(100) NOT NULL UNIQUE,
  opis TEXT(500),
  id_cijepiva INT NOT NULL ,
  FOREIGN KEY (id_cijepiva) REFERENCES cijepiva (id)

);

  CREATE TABLE Cijepiva (
 id INT AUTO_INCREMENT PRIMARY KEY,
 cijepivo ENUM('Žuta groznica', 'Hepatitis A i B', 'Tifus', 'Bjesnoća','Tifus', 'Japanski encefalitis', 'Polio', 'Meningokokni meningitis')
 
);

CREATE TABLE Cijepiva_kontinent (
id_kontinent INT NOT NULL,
FOREIGN KEY (id_kontinent) REFERENCES kontinent(id),
id_cijepivo INT NOT NULL,
FOREIGN KEY (id_cijepivo) REFERENCES cijepivo(id)

);


CREATE TABLE Cijepljeni_korisnici (
id_cijepiva INT NOT NULL,
FOREIGN KEY (id_cijepivo) REFERENCES cijepivo(id),
id_korisnik INT,
FOREIGN KEY (id_korisnik) REFERENCES korisnik(id)

);

CREATE TABLE Odrediste (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ime VARCHAR(100) NOT NULL UNIQUE,
  id_grad INT NOT NULL UNIQUE,
  popularne_atrakcije VARCHAR(100) NOT NULL,
  opis TEXT(500),
  FOREIGN KEY (id_grad) REFERENCES grad(id) ON DELETE CASCADE
);

CREATE TABLE Hotel (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ime VARCHAR(100) NOT NULL ,
  id_recenzija INT,
  id_adresa INT,
  kontaktni_broj VARCHAR(15), 
  email VARCHAR(100) NOT NULL UNIQUE,
  slobodne_sobe INT NOT NULL CHECK (slobodne_sobe >= 0),
  pogodnosti TEXT(500),
  opis TEXT(500),
  odrediste_id INT NOT NULL,
  FOREIGN KEY (odrediste_Id) REFERENCES odrediste(id) ON DELETE CASCADE,
  FOREIGN KEY (id_recenzija) REFERENCES recenzija(id) ON DELETE CASCADE,
  FOREIGN KEY (id_adresa) REFERENCES adresa(id) ON DELETE CASCADE
);

-- Mateo i Karlo


CREATE TABLE Zaposlenik (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime VARCHAR(20) NOT NULL,
    prezime VARCHAR(30) NOT NULL,
    broj_mobitela INT NOT NULL,
    adresa_id INT NOT NULL,
    placa INT NOT NULL,
    UNIQUE (broj_mobitela),
    FOREIGN KEY (adresa_id) REFERENCES Adresa(id)
    );


#CREATE TABLE Adresa (
#	id INT AUTO_INCREMENT PRIMARY KEY,
#    drzava VARCHAR(30) NOT NULL,
#    grad VARCHAR (30) NOT NULL,
#    ulica VARCHAR (50) NOT NULL,
#    postanski_broj INT NOT NULL
#);

CREATE TABLE Pozicija (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime_pozicije CHAR (30) NOT NULL,
    opis_pozicije TEXT(500));

CREATE TABLE Radna_smjena (
	zaposlenik_id INT NOT NULL,
    smjena INT NOT NULL,
    datum DATE NOT NULL,
    FOREIGN KEY (zaposlenik_id) REFERENCES Zaposlenik(id)
    );

CREATE TABLE Pozicija_zaposlenika (
	id_zaposlenik INT NOT NULL,
    id_pozicija INT NOT NULL,
    FOREIGN KEY (id_zaposlenik) REFERENCES Zaposlenik(id),
    FOREIGN KEY (id_pozicija) REFERENCES Pozicija(id)
    );


CREATE TABLE Korisnik (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime VARCHAR(20) NOT NULL,
    prezime VARCHAR(30) NOT NULL,
    broj_mobitela INT NOT NULL,
    adresa_id INT NOT NULL,
    email VARCHAR (100)NOT NULL,
    UNIQUE (broj_mobitela, email),
    FOREIGN KEY (adresa_id) REFERENCES Adresa(id)
    );

CREATE TABLE Recenzija(
	id INT AUTO_INCREMENT PRIMARY KEY,
    korisnik_id INT NOT NULL,
    ocjena INT NOT NULL,
    komentar TEXT(500) ,
    datum date NOT NULL,
    CHECK (ocjena > 0 AND ocjena < 6),
    FOREIGN KEY (korisnik_id) REFERENCES Korisnik(id)
    );

CREATE TABLE Recenzija_transporta(
	id_transport INT NOT NULL,
    id_recenzija INT NOT NULL,
    FOREIGN KEY (id_transport) REFERENCES Transport(id),
    FOREIGN KEY (id_recenzija) REFERENCES Recenzija(id)
    );

CREATE TABLE Recenzija_hotela(
	id_hotel INT NOT NULL,
    id_recenzija INT NOT NULL,
    FOREIGN KEY (id_hotel) REFERENCES Hotel(id),
    FOREIGN KEY (id_recenzija) REFERENCES Recenzija(id)
    );

CREATE TABLE Recenzija_paketa(
	id_paket INT NOT NULL,
    id_recenzija INT NOT NULL,
    FOREIGN KEY (id_paket) REFERENCES Paket(id),
    FOREIGN KEY (id_recenzija) REFERENCES Recenzija(id)
    );

CREATE TABLE Recenzija_zaposlenika(
	id_zaposelnik INT NOT NULL,
    id_recenzija INT NOT NULL,
    FOREIGN KEY (id_zaposelnik) REFERENCES Zaposlenik(id),
    FOREIGN KEY (id_recenzija) REFERENCES Recenzija(id)
    );

CREATE TABLE Recenzija_aktivnosti(
	id_aktivnost INT NOT NULL,
    id_recenzija INT NOT NULL,
    FOREIGN KEY (id_aktivnost) REFERENCES Aktivnosti(id),
    FOREIGN KEY (id_recenzija) REFERENCES Recenzija(id)
    );

CREATE TABLE Recenzija_vodica(
	id_vodic INT NOT NULL,
    id_recenzija INT NOT NULL,
    FOREIGN KEY (id_vodic) REFERENCES Vodic(id),
    FOREIGN KEY (id_recenzija) REFERENCES Recenzija(id)
    );


    
