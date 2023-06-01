USE turisticka_agencija;

-- Autor: Mateo Udovčić

-- Prikaži 5 korisnika sa najviše danih recenzija, te im se dodaje dodatnih 2000 korisničkih boodva


CREATE VIEW recenzijeB AS
SELECT o.id, o.puno_ime, korisnicki_bodovi, COUNT(r.id_osoba) AS broj_recenzija
FROM osoba o JOIN recenzija r ON o.id = r.id_osoba
GROUP BY o.id, o.puno_ime
ORDER BY broj_recenzija DESC
LIMIT 5
;

SELECT id, puno_ime, broj_recenzija, korisnicki_bodovi, korisnicki_bodovi + 2000 AS novi_bodovi
FROM recenzijeB;

-- Prikaži broj ukupan broj rezervacija u 5. mjesecu od korisnika koji imaju više od 5000 korisničkih bodova

CREATE VIEW broj_rezervacija AS
SELECT o.puno_ime, o.korisnicki_bodovi, r.vrijeme
FROM osoba o JOIN rezervacija r ON o.id = r.id_osoba
WHERE MONTH(r.vrijeme)=5 AND korisnicki_bodovi>5000
;

SELECT COUNT(*) AS broj_rezervacija_ukupno
FROM broj_rezervacija 
;


-- Prikaži 3 zaposlenika koja pričaju najviše stranih jezika, dok jedan od tih jezika mora biti njemački


CREATE VIEW Njemci AS 
SELECT  o.id, o.puno_ime
FROM zaposlenik z JOIN osoba o ON z.id=o.id
JOIN dodatni_jezik dj ON dj.id_osoba=o.id
WHERE dj.dodatni_jezik='german'
;

CREATE VIEW jezici AS
SELECT Nj.puno_ime, count(dj.dodatni_jezik) AS broj_jezika
FROM Njemci Nj JOIN dodatni_jezik dj ON Nj.id=dj.id_osoba
GROUP BY Nj.puno_ime
ORDER BY broj_jezika DESC
; 

SELECT *
FROM jezici
LIMIT 3
;

-- Prikaži prosječne ocjene svih transportnih tvrtki kako bi se korisnik mogao odlučiti kojom da putuje, te ih poredaj od bolje prema lošijoj

SELECT t.ime_tvrtke, AVG(r.ocjena) AS prosjecna_ocjena
FROM transport t
JOIN recenzija_transporta rt ON t.id = rt.id_transport
JOIN recenzija r ON rt.id_recenzija = r.id
GROUP BY t.ime_tvrtke
ORDER BY prosjecna_ocjena DESC
;

