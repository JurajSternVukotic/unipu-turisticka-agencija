CREATE DATABASE Turisticka_agencija;
USE Turisticka_agencija;

-- DROP DATABASE IF EXISTS Travel_Agency;

CREATE TABLE Osiguranje (
	id INT AUTO_INCREMENT PRIMARY KEY,
    ime VARCHAR(128) NOT NULL,
    opis VARCHAR(256) DEFAULT "",
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
    naziv VARCHAR(128),
    davatelj VARCHAR(128),
    datum DATETIME,
    cijena NUMERIC(10, 2)
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