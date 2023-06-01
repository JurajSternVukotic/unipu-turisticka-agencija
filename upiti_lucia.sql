USE turisticka_agencija;

-- Autor: Lucia Labinjan

### Lucia Labinjan ###
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

-- upit 2
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
-- Upit 3
SELECT 
    osoba.puno_ime AS CustomerName,
    paket.naziv AS PackageName,
    rezervacija.vrijeme AS BookingTime,
    recenzija.ocjena AS ReviewRating,
    recenzija.komentar AS ReviewComment,
    recenzija.datum AS ReviewDate,
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
    kupon ON kupon_rezervacija.id_kupon = kupon.id
LEFT JOIN 
    stavka_korisnicke_podrske ON osoba.id = stavka_korisnicke_podrske.id_osoba
ORDER BY 
    osoba.puno_ime ASC, rezervacija.vrijeme DESC;
