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
	id INT AUTO_INCREMENT PRIMARY KEY,
    naziv VARCHAR(64),
    opis TEXT(500),
    Postanski_Broj VARCHAR(32)
);

CREATE TABLE Adresa(
	id INT AUTO_INCREMENT PRIMARY KEY,
	naziv VARCHAR(64)
);

CREATE TABLE Grad_Adrese(
	id_grad INT NOT NULL REFERENCES Grad (id) ON DELETE CASCADE,
    id_adresa INT NOT NULL REFERENCES Adresa (id) ON DELETE CASCADE
);

CREATE TABLE Drzava(
	id INT AUTO_INCREMENT PRIMARY KEY,
    naziv VARCHAR(64),
    opis TEXT(500),
    valuta VARCHAR(32),
    cijena NUMERIC(10, 2),
    dokumenti_za_ulaz TEXT(500),
    jezik VARCHAR(32),
    pozivni_broj INT
);

CREATE TABLE Drzava_Grada(
	id_Drzava INT NOT NULL REFERENCES Drzava (id) ON DELETE CASCADE,
    id_Grad INT NOT NULL REFERENCES Grad (id) ON DELETE CASCADE
);

CREATE TABLE Stavka_Korisnicke_Podrske(
	id INT AUTO_INCREMENT PRIMARY KEY,
    # Mozda treba napraviti specijalnu tablicu sa id stavke, id korisnika i id zaposnelika???
	id_korisnik INT NOT NULL REFERENCES Korisnik (id) ON DELETE CASCADE,
    id_zaposlenik INT NOT NULL REFERENCES Zaposlenik (id) ON DELETE CASCADE,
    vrsta_problema ENUM ('Placanje', 'Rezervacija', 'Problemi sa zaposlenicima', 'Tehnicki problemi', 'Povrat novca', 'Drugo'),
    opis_problema TEXT (500),
    status_problema ENUM('Zaprimljeno', 'U obradi', 'Na cekanju', 'Rjeseno')
);

CREATE TABLE Paket(
	id INT AUTO_INCREMENT PRIMARY KEY,
    naziv VARCHAR (64),
    opis TEXT (1000),
    min_ljudi INT,
    max_ljudi INT,
    popunjenih_mjesta INT,
    pocetak_puta DATE,
    kraj_puta DATE,
    cijena_po_turistu DECIMAL(12,2)
);

CREATE TABLE Putni_Plan_Stavka(
	id INT AUTO_INCREMENT PRIMARY KEY,
    id_paket INT NOT NULL REFERENCES Paket (id) ON DELETE CASCADE,
    id_transport INT NOT NULL REFERENCES transport (id) ON DELETE CASCADE,
    id_odrediste INT NOT NULL REFERENCES odrediste (id) ON DELETE CASCADE,
    id_aktivnost INT NOT NULL REFERENCES aktivnost (id) ON DELETE CASCADE,
    id_vodic INT NOT NULL REFERENCES vodic (id) ON DELETE CASCADE,
    opis TEXT(500),
    upute TEXT(500),
    pocetak TIME,
    trajanje_u_minutama INT
);


    
-- lucijin dio
CREATE TABLE Vodic (
  id INT PRIMARY KEY AUTO_INCREMENT,
  ime VARCHAR(50),
  prezime VARCHAR(50),
  datum_rodenja DATE,
  kontaktni_broj VARCHAR(15),
  email VARCHAR(100),
  jezik_pricanja VARCHAR(50),
  godine_iskustva INT
);

CREATE TABLE Transport (
  id INT PRIMARY KEY AUTO_INCREMENT,
  tip_transporta ENUM ('bus', 'avion', 'brod', 'vlak'),
  kapacitet INT,
  cijena DECIMAL(10,2),
  ime_dobavljaca VARCHAR(100),
  kontakt_dobavljaca VARCHAR(15),
  vrijeme_odlaska DATETIME,
  vrijeme_dolaska  DATETIME
);

CREATE TABLE Aktivnosti (
  id INT PRIMARY KEY AUTO_INCREMENT,
  ime VARCHAR(100),
  opis TEXT,
  cijena DECIMAL(10,2),
  lokacija VARCHAR(100),
  duracije INT,
  pocetak_aktivnosti TIME,
  kvaliteta VARCHAR(100)
);

CREATE TABLE Turisticko_odrediste (
  id INT PRIMARY KEY AUTO_INCREMENT,
  ime VARCHAR(100),
  id_kontinent VARCHAR(100),
  id_drzava VARCHAR(50),
  grad VARCHAR(50),
  popularne_atrakcije VARCHAR(100)
);

CREATE TABLE Hotel (
  id INT PRIMARY KEY AUTO_INCREMENT,
  ime VARCHAR(100),
  star_Rating INT,
  adresa VARCHAR(200),
  kontaktni_broj VARCHAR(15),
  email VARCHAR(100),
  slobodne_sobe INT,
  pogodnosti TEXT,
  turisticko_odrediste_Id INT NOT NULL REFERENCES Turisticko_odrediste (id) ON DELETE CASCADE
);

-- Mateo i Karlo


CREATE TABLE Zaposlenik (
	id INT PRIMARY KEY,
    ime VARCHAR(20) NOT NULL,
    prezime VARCHAR(30) NOT NULL,
    broj_mobitela INT NOT NULL,
    adresa_id INT NOT NULL,
    placa INT NOT NULL,
    UNIQUE (broj_mobitela),
    FOREIGN KEY (adresa_id) REFERENCES Adresa(id)
    );


#CREATE TABLE Adresa (
#	id INT PRIMARY KEY,
#    drzava VARCHAR(30) NOT NULL,
#    grad VARCHAR (30) NOT NULL,
#    ulica VARCHAR (50) NOT NULL,
#    postanski_broj INT NOT NULL
#);

CREATE TABLE Pozicija (
	id INT PRIMARY KEY,
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
	id INT PRIMARY KEY,
    ime VARCHAR(20) NOT NULL,
    prezime VARCHAR(30) NOT NULL,
    broj_mobitela INT NOT NULL,
    adresa_id INT NOT NULL,
    email VARCHAR (100)NOT NULL,
    UNIQUE (broj_mobitela, email),
    FOREIGN KEY (adresa_id) REFERENCES Adresa(id)
    );

CREATE TABLE Recenzija(
	id INT PRIMARY KEY,
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


    
