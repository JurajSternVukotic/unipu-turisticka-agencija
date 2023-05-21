    CREATE DATABASE Turisticka_agencija;
USE Turisticka_agencija;

-- DROP DATABASE IF EXISTS Turisticka_agencija;

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
    metoda ENUM('gotovina', 'kredit', 'debit', 'ček', 'redirect', 'transfer', 'voucher', 'wallet', 'ostalo') NOT NULL,
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
    tecaj_u_eurima DECIMAL(5,10),
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

//Mateo i Karlo

// Tko bude imao guide neka nam napomene kako je tocno preveo da mozemo preimenovat zadnju zablicu

CREATE TABLE zaposlenik (
	id INT PRIMARY KEY,
    ime VARCHAR(20),
    prezime VARCHAR(30),
    broj_mobitela INT,
    adresa_id INT,
    plaća INT);


CREATE TABLE adresa (
	id INT PRIMARY KEY,
    država VARCHAR(30),
    grad VARCHAR (30),
    ulica VARCHAR (50),
    poštanski_broj INT
);

CREATE TABLE pozicija (
	id INT PRIMARY KEY,
    ime_pozicije CHAR (30),
    opis_pozicije TEXT(500));

CREATE TABLE radna_smjena (
	employee_id int,
    smjena INT,
    datum DATE);

CREATE TABLE pozicija_zaposlenika (
	id_zaposlenik INT ,
    id_pozicija INT );


CREATE TABLE korisnik (
	id INT PRIMARY KEY,
    ime VARCHAR(20),
    prezime VARCHAR(30),
    broj_mobitela INT,
    adresa_id INT,
    email VARCHAR (100));

CREATE TABLE recenzija(
	id INT PRIMARY KEY,
    korisnik_id INT,
    ocjena INT,
    komentar TEXT(500),
    datum date);

CREATE TABLE recenzija_prijevoza(
	id_prijevoz INT,
    id_recenzija INT);

CREATE TABLE recenzija_hotela(
	id_hotel INT,
    id_recenzija INT);

CREATE TABLE recenzija_paketa(
	id_paket INT,
    id_recenzija INT);

CREATE TABLE recenzija_zaposlenika(
	id_zaposelnik INT,
    id_recenzija INT);

CREATE TABLE recenzija_aktivnosti(
	id_aktivnost INT,
    id_recenzija INT);

CREATE TABLE recenzija_guide(
	id_guide INT,
    id_recenzija INT);