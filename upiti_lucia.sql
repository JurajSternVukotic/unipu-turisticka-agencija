USE turisticka_agencija;

-- Autor: Lucia Labinjan

-- upit 1
 CREATE VIEW paket_recenzije AS
SELECT
    paket.naziv AS ime_paketa,
    recenzija.ocjena AS recenzija_ocjene,
    recenzija.komentar AS komentar_recenzije,
    recenzija.datum AS datum_recenzije,
    osoba.puno_ime AS ime_korisnika
FROM
    paket
JOIN
    recenzija_paketa ON paket.id = recenzija_paketa.id_paket
JOIN
    recenzija ON recenzija_paketa.id_recenzija = recenzija.id
JOIN
    osoba ON recenzija.id_osoba = osoba.id;



CREATE VIEW korisnicke_podrske AS
SELECT
    skp.vrsta_problema,
    skp.opis_problema ,
    skp.status_problema ,
    osoba.puno_ime 
FROM
    stavka_korisnicke_podrske skp
JOIN
    osoba ON skp.id_osoba = osoba.id;

SELECT
    pr.naziv_paketa ,
    pr.recenzija_ocjene ,
    pr.komentar_recenzije  ,
    pr.datum_recenzije ,
    kp.vrsta_problema,
    kp.opis_problema,
    kp.status_problema
FROM
    paket_recenzije pr
JOIN
    korisnicke_podrske kp ON pr.ime_korisnika = kp.ime_osobe;
    
    
-- Upit 2

SELECT 
    osoba.puno_ime AS ime_korisnika,
    paket.naziv AS ime_paketa,
    rezervacija.vrijeme AS vrijeme_rezervacije,
    recenzija.ocjena AS recenzija_ocjena, 
    recenzija.komentar AS komentar_recenzije,
    recenzija.datum AS datum_recenzije,
    kupon.kod AS kod_kupona,
    kupon.iznos AS iznos_kupona,
    kupon.postotni AS postotak_kupona,
    stavka_korisnicke_podrske.vrsta_problema AS TicketType,
    stavka_korisnicke_podrske.opis_problema AS TicketDescription,
    stavka_korisnicke_podrske.status_problema AS TicketStatus
FROM 
    osoba
LEFT JOIN 
    rezervacija ON osoba.id = rezervacija.id_osoba
LEFT JOIN 
    paket ON rezervacija.id_paket = paket.id
LEFT JOIN 
    recenzija ON osoba.id = recenzija.id_osoba
LEFT JOIN 
    kupon_rezervacija ON rezervacija.id = kupon_rezervacija.id_rezervacija
LEFT JOIN 
    kupon ON kupon_rezervacija.id_kupon = kupon.id_kupon
LEFT JOIN 
    stavka_korisnicke_podrske ON osoba.id = stavka_korisnicke_podrske.id_osoba
ORDER BY 
    osoba.puno_ime ASC, rezervacija.vrijeme DESC;
    
    

SELECT 
    osoba.puno_ime AS CustomerName,
    paket.naziv AS naziv_paketa,
    rezervacija.vrijeme AS BookingTime,
    recenzija.ocjena AS recenzija_ocjene, 
    recenzija.komentar AS komentar_recenzije,
    recenzija.datum AS datum_recenzije,
    kupon.kod AS CouponCode,
    kupon.iznos AS CouponAmount,
    kupon.postotni AS IsCouponPercentage,
    stavka_korisnicke_podrske.vrsta_problema AS TicketType,
    stavka_korisnicke_podrske.opis_problema AS TicketDescription,
    stavka_korisnicke_podrske.status_problema AS TicketStatus
FROM 
    osoba
LEFT JOIN 
    rezervacija ON osoba.id = rezervacija.id_osoba
LEFT JOIN 
    paket ON rezervacija.id_paket = paket.id
LEFT JOIN 
    recenzija ON osoba.id = recenzija.id_osoba
LEFT JOIN 
    kupon_rezervacija ON rezervacija.id = kupon_rezervacija.id_rezervacija
LEFT JOIN 
    kupon ON kupon_rezervacija.id_kupon = kupon.id_kupon
LEFT JOIN 
    stavka_korisnicke_podrske ON osoba.id = stavka_korisnicke_podrske.id_osoba
WHERE 
    osoba.id = 273  -- OSOBA KOJU TRAZIMO
ORDER BY 
    osoba.puno_ime ASC, rezervacija.vrijeme DESC;






-- upit 3 --

SELECT 
      paket.id,
      paket.naziv,
      paket.opis,
      AVG(recenzija.ocjena) as AvgOcjenaPaketa,
      COUNT(DISTINCT rezervacija.id) as BrojRezervacija,
      MAX(hotel.ime) as NajboljeOcijenjeniHotel,
      MAX(odrediste.ime) as NajpopularnijeOdrediste,
      MAX(aktivnost.ime) as NajpopularnijaAktivnost,
      MAX(CONCAT(osoba.puno_ime, ' (', vodic.godine_iskustva, ' god. iskustva)')) as NajiskusnijiVodic
FROM 
      paket
LEFT JOIN 
      recenzija_paketa ON paket.id = recenzija_paketa.id_paket
LEFT JOIN 
      recenzija ON recenzija_paketa.id_recenzija = recenzija.id
LEFT JOIN 
      rezervacija ON paket.id = rezervacija.id_paket
LEFT JOIN 
      hoteli_paketa ON paket.id = hoteli_paketa.id_paket
LEFT JOIN 
      hotel ON hoteli_paketa.id_hotel = hotel.id
LEFT JOIN 
      putni_plan_stavka ON paket.id = putni_plan_stavka.id_paket
LEFT JOIN 
      odrediste ON putni_plan_stavka.id_odrediste = odrediste.id
LEFT JOIN 
      aktivnost ON putni_plan_stavka.id_aktivnost = aktivnost.id
LEFT JOIN 
      vodic ON putni_plan_stavka.id_vodic = vodic.id
LEFT JOIN 
      osoba ON vodic.id = osoba.id
GROUP BY 
      paket.id
HAVING 
      BrojRezervacija > 3
ORDER BY 
      AvgOcjenaPaketa DESC,
      BrojRezervacija DESC
LIMIT 10;



-- upit 4--
SELECT 
    z.id,
    o.puno_ime,
    o.datum_rodenja,
    o.kontaktni_broj,
    o.email,
    z.ugovor_o_radu,
    z.placa,
    poz.ime_pozicije,
    rs.smjena,
    rs.datum,
    AVG(rec.ocjena) as AvgOcjenaZaposlenika,
    COUNT(DISTINCT skp.id) as UkupnoStavkiPodrske,
    COUNT(DISTINCT rez.id) as UkupnoProdanihPaketa,
    COUNT(DISTINCT rez.id_osoba) as UkupnoKorisnikaObradenih
FROM 
    zaposlenik z
INNER JOIN 
    osoba o ON z.id = o.id
INNER JOIN 
    pozicija_zaposlenika pz ON z.id = pz.id_zaposlenik
INNER JOIN 
    pozicija poz ON pz.id_pozicija = poz.id
INNER JOIN 
    radna_smjena rs ON z.id = rs.id_zaposlenik
LEFT JOIN 
    recenzija_zaposlenika rz ON z.id = rz.id_zaposlenik
LEFT JOIN 
    recenzija rec ON rz.id_recenzija = rec.id
LEFT JOIN 
    stavka_korisnicke_podrske skp ON z.id = skp.id_zaposlenik
LEFT JOIN 
    rezervacija rez ON z.id = rez.id_zaposlenik
WHERE 
    rs.datum = '2023-06-01'
GROUP BY 
    z.id,
    poz.ime_pozicije,
    rs.smjena;




