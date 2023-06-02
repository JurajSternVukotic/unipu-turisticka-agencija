USE turisticka_agencija;

-- Autor: Juraj Štern-Vukotić

### Juraj Štern-Vukotić ###
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
CREATE VIEW zaposlenik_zaposlenost AS
SELECT z.id, COUNT(r.id) + COUNT(s.id) AS task_count
FROM zaposlenik z
LEFT JOIN rezervacija r ON r.id_zaposlenik = z.id
LEFT JOIN stavka_korisnicke_podrske s ON s.id_zaposlenik = z.id
GROUP BY z.id
ORDER BY task_count DESC;

-- Alternativni zaposlenici koji bi se mogli pridonjeti rezervacijama sa krivim jezikom
SELECT 
    rezervacija_krivi_jezik.rezervacija_id, 
    rezervacija_krivi_jezik.osoba_id, 
    alt_zaposlenik.id AS id_zaposlenik,
    z_z.task_count AS alt_zaposlenik_task_count
FROM 
    rezervacija_krivi_jezik
JOIN 
    jezici_osobe jo ON rezervacija_krivi_jezik.osoba_id = jo.id
JOIN 
    jezici_zaposlenika jz ON jo.jezik = jz.jezik
JOIN 
    zaposlenik alt_zaposlenik ON jz.id = alt_zaposlenik.id
JOIN 
    zaposlenik_zaposlenost z_z ON alt_zaposlenik.id = z_z.id;


-- Alternativni zaposlenici koji bi se mogli pridonjeti rezervacijama sa krivim jezikom
SELECT 
    podrska_krivi_jezik.stavka_korisnicke_podrske_id, 
    podrska_krivi_jezik.osoba_id, 
    alt_zaposlenik.id AS alt_zaposlenik_id,
    z_z.task_count AS alt_zaposlenik_task_count
FROM 
    podrska_krivi_jezik
JOIN 
    jezici_osobe jo ON podrska_krivi_jezik.osoba_id = jo.id
JOIN 
    jezici_zaposlenika jz ON jo.jezik = jz.jezik
JOIN 
    zaposlenik alt_zaposlenik ON jz.id = alt_zaposlenik.id
JOIN 
    zaposlenik_zaposlenost z_z ON alt_zaposlenik.id = z_z.id;

-- ----------------------------------------------------------

-- Za svaki datum koliko zaposlenika je u kojoj smjeni
SELECT datum, smjena, COUNT(id_zaposlenik) AS broj_zaposlenika
FROM radna_smjena
GROUP BY datum, smjena;

-- Prebrojati koliko imamo zaposlenika na nekoj poziciji
SELECT p.ime_pozicije, COUNT(pz.id_zaposlenik) AS broj_zaposlenika
FROM pozicija_zaposlenika pz
JOIN pozicija p ON pz.id_pozicija = p.id
GROUP BY p.ime_pozicije;

CREATE VIEW pozicije_zaposlenika AS
SELECT pz.id_zaposlenik, p.ime_pozicije
FROM pozicija_zaposlenika pz
JOIN pozicija p ON pz.id_pozicija = p.id;

-- Koliko je u svakoj smjeni određene pozicije zaposlenika
SELECT radna_smjena.datum, radna_smjena.smjena, pozicije_zaposlenika.ime_pozicije, COUNT(radna_smjena.id_zaposlenik) AS broj_zaposlenika
FROM radna_smjena
JOIN pozicije_zaposlenika ON radna_smjena.id_zaposlenik = pozicije_zaposlenika.id_zaposlenik
GROUP BY radna_smjena.datum, radna_smjena.smjena, pozicije_zaposlenika.ime_pozicije;

-- ----------------------------------------
-- naci sve posebne zahjeve za paket X
SELECT pz.*, os.puno_ime, os.kontaktni_broj
FROM posebni_zahtjev pz
JOIN rezervacija r ON pz.id_rezervacija = r.id
JOIN osoba os ON r.id_osoba = os.id
WHERE r.id_paket = 12;

-- naci sve rezervacije bez osiguranja za paket X
SELECT r.*, os.puno_ime, os.kontaktni_broj
FROM rezervacija r
JOIN osoba os ON r.id_osoba = os.id
LEFT JOIN osiguranje o ON r.id = o.id_rezervacija
WHERE r.id_paket = 12 AND o.id IS NULL;

-- --------------------------

-- Koje cjepivo drzave zahtjevaju, ime drzave i cjepiva sa idevima
CREATE VIEW drzave_sa_cjepivima AS
SELECT drzava.id AS id_drzava, 
       drzava.naziv AS naziv_drzava, 
       cjepivo.id AS id_cjepivo, 
       cjepivo.naziv AS naziv_cjepivo
FROM drzava
INNER JOIN cjepivo_drzava ON drzava.id = cjepivo_drzava.id_drzava
INNER JOIN cjepivo ON cjepivo_drzava.id_cjepivo = cjepivo.id;

SELECT DISTINCT d.naziv AS drzava_name
FROM drzava d
WHERE NOT EXISTS (
  SELECT 1
  FROM cjepivo_drzava cd
  WHERE cd.id_drzava = d.id
    AND NOT EXISTS (
      SELECT 1
      FROM cjepljena_osoba co
      WHERE co.id_cjepivo = cd.id_cjepivo AND co.id_osoba = 532 -- KOJU OSOBU GLEDAMO
    )
);

-- -------------------------

SELECT 
  paket.naziv AS naziv_paketa,
  GROUP_CONCAT(DISTINCT hotel.ime) AS hoteli,
  GROUP_CONCAT(DISTINCT transport.ime_tvrtke) AS trvtka_transport,
  GROUP_CONCAT(DISTINCT transport.tip_transporta) AS tip_transporta,
  GROUP_CONCAT(DISTINCT vodic.godine_iskustva) AS vodic_iskustvo,
  GROUP_CONCAT(DISTINCT odrediste.ime) AS odrediste,
  GROUP_CONCAT(DISTINCT aktivnost.ime) AS aktivnosti
FROM 
  putni_plan_stavka 
JOIN 
  paket ON putni_plan_stavka.id_paket = paket.id 
LEFT JOIN 
  hoteli_paketa ON paket.id = hoteli_paketa.id_paket 
LEFT JOIN 
  hotel ON hoteli_paketa.id_hotel = hotel.id
LEFT JOIN 
  transport ON putni_plan_stavka.id_transport = transport.id
LEFT JOIN 
  vodic ON putni_plan_stavka.id_vodic = vodic.id
LEFT JOIN 
  odrediste ON putni_plan_stavka.id_odrediste = odrediste.id
LEFT JOIN 
  aktivnost ON putni_plan_stavka.id_aktivnost = aktivnost.id
WHERE 
  paket.id = 25
GROUP BY
  paket.id;


CREATE VIEW putni_plan_stavka_vodici AS 
SELECT id_vodic FROM putni_plan_stavka WHERE id_paket = 9;

CREATE VIEW putni_plan_stavka_transporti AS 
SELECT id_transport FROM putni_plan_stavka WHERE id_paket = 9;

CREATE VIEW putni_plan_stavka_aktivnosti AS 
SELECT id_aktivnost FROM putni_plan_stavka WHERE id_paket = 9;

CREATE VIEW hoteli_paketa_hoteli AS 
SELECT id_hotel FROM hoteli_paketa WHERE id_paket = 9;

(SELECT 
  paket.naziv AS predmet_recenzije,
  pake_recenzija.ocjena AS ocjena,
  pake_recenzija.komentar AS komentar,
  osoba.puno_ime AS ime_ocjenjivaca,
  pake_recenzija.datum AS datum_recenzije
FROM 
  paket 
JOIN 
  recenzija_paketa ON paket.id = recenzija_paketa.id_paket 
JOIN 
  recenzija pake_recenzija ON recenzija_paketa.id_recenzija = pake_recenzija.id
JOIN 
  osoba ON pake_recenzija.id_osoba = osoba.id
WHERE 
  paket.id = 9)
UNION
(SELECT   
  osoba.puno_ime AS predmet_recenzije,   
  vodic_recenzija.ocjena AS ocjena,   
  vodic_recenzija.komentar AS komentar,   
  osoba.puno_ime AS ime_ocjenjivaca,   
  vodic_recenzija.datum AS datum_recenzije 
FROM    
  vodic  
JOIN    
  recenzija_vodica ON vodic.id = recenzija_vodica.id_vodic  
JOIN    
  recenzija vodic_recenzija ON recenzija_vodica.id_recenzija = vodic_recenzija.id 
JOIN    
  osoba ON vodic_recenzija.id_osoba = osoba.id 
WHERE    
  vodic.id IN (SELECT id_vodic FROM putni_plan_stavka_vodici))
UNION
(SELECT 
  hotel.ime AS predmet_recenzije,
  hotel_recenzija.ocjena AS ocjena,
  hotel_recenzija.komentar AS komentar,
  osoba.puno_ime AS ime_ocjenjivaca,
  hotel_recenzija.datum AS datum_recenzije
FROM 
  hotel 
JOIN 
  recenzija_hotela ON hotel.id = recenzija_hotela.id_hotel 
JOIN 
  recenzija hotel_recenzija ON recenzija_hotela.id_recenzija = hotel_recenzija.id
JOIN 
  osoba ON hotel_recenzija.id_osoba = osoba.id
WHERE 
  hotel.id IN (SELECT id_hotel FROM hoteli_paketa_hoteli))
UNION
(SELECT 
  transport.tip_transporta AS predmet_recenzije,
  transport_recenzija.ocjena AS ocjena,
  transport_recenzija.komentar AS komentar,
  osoba.puno_ime AS ime_ocjenjivaca,
  transport_recenzija.datum AS datum_recenzije
FROM 
  transport 
JOIN 
  recenzija_transporta ON transport.id = recenzija_transporta.id_transport 
JOIN 
  recenzija transport_recenzija ON recenzija_transporta.id_recenzija = transport_recenzija.id
JOIN 
  osoba ON transport_recenzija.id_osoba = osoba.id
WHERE 
  transport.id IN (SELECT id_transport FROM putni_plan_stavka_transporti))
UNION
(SELECT 
  aktivnost.ime AS predmet_recenzije,
  aktivnost_recenzija.ocjena AS ocjena,
  aktivnost_recenzija.komentar AS komentar,
  osoba.puno_ime AS ime_ocjenjivaca,
  aktivnost_recenzija.datum AS datum_recenzije
FROM 
  aktivnost 
JOIN 
  recenzija_aktivnosti ON aktivnost.id = recenzija_aktivnosti.id_aktivnost 
JOIN 
  recenzija aktivnost_recenzija ON recenzija_aktivnosti.id_recenzija = aktivnost_recenzija.id
JOIN 
  osoba ON aktivnost_recenzija.id_osoba = osoba.id
WHERE 
  aktivnost.id IN (SELECT id_aktivnost FROM putni_plan_stavka_aktivnosti));




-- ---------------------
