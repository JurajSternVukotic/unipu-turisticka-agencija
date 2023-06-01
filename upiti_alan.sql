USE turisticka_agencija;

-- Autor: Alan Burić

-- Testni primjer:
INSERT INTO kupon VALUE(NULL, 'Čščđćž32', MAKEDATE(2023, 100), MAKEDATE(2023, 140), 20, 1);

### Alan Burić ###
-- POGLEDI - pohranjeni upiti

-- Prikazuje sve IDjeve zaposlenika koji su putni agenti.
CREATE VIEW svi_putni_agenti AS 
	SELECT id_zaposlenik AS id 
    FROM pozicija_zaposlenika 
    WHERE id_pozicija = (SELECT id 
						FROM pozicija 
                        WHERE ime_pozicije = 'putni agent');
/*
 * I. Pronađi ID pozicije 'putni agent'
 * II. Pronađi sve zaposlenike s tom pozicijom (preko IDja)
 * III. Pobroji njihova pojavljivanja
 * IV. Sortiraj ih od najmanjeg prema najvećem
 */

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

-- 1. Pronađite prave iznose cijena rezervacija s obzirom na primjenu kupon koda prema formuli novi_iznos = max(0, (cijena - SUM(ne postotnih kupona)) * min(0, 1 - SUM(postotnih kupona) / 100)
SELECT id, 
			GREATEST(0, (cijena 
				- IFNULL((SELECT SUM(iznos) 
								FROM kuponi_rezervacije 
                                WHERE NOT postotni AND id_rezervacija = id 
                                GROUP BY id_kupon), 0))
				* LEAST(0, IFNULL((SELECT SUM(iznos) 
								FROM kuponi_rezervacije 
                                WHERE postotni AND id_rezervacija = id 
                                GROUP BY id_kupon), 0) / 100)) AS novi_iznos
	FROM 
		rezervacija 
			JOIN 
        (SELECT id AS id_paket, cijena_po_turistu AS cijena FROM paket) AS paket 
	USING (id_paket);

-- 2. Pronađite sve id_rezervacija za potpuno plaćene rezervacija
CREATE VIEW placene_rezervacije AS 
	SELECT id_rezervacija, p.id_paket, p.cijena, SUM(iznos) AS iznos 
		FROM 
			(SELECT id AS id_paket, cijena_po_turistu AS cijena FROM paket) AS p,
			(SELECT id AS id_rezervacija, id_paket FROM rezervacija) AS r 
				JOIN 
			uplata USING (id_rezervacija) 
		WHERE p.id_paket = r.id_paket
		GROUP BY id_rezervacija
		HAVING iznos >= cijena;

-- 4. Pronađite najviše korištene kupone s nazivom koda prema padajućemu poretku
SELECT id_kupon, kod, COUNT(*) AS kolicina 
	FROM kupon_rezervacija 
		JOIN (SELECT id AS id_kupon, kod FROM kupon) AS k 
    USING (id_kupon) 
    GROUP BY id_kupon 
    ORDER BY kolicina DESC;

-- 5. Prikažite drugu po redu stranicu najpopularnijih paketa s obzirom na rezervacije s time da se na svakoj stranici prikazuje 20 rezultata.
SELECT id_paket, COUNT(*) popularnost 
	FROM rezervacija
    GROUP BY id_paket 
    ORDER BY popularnost DESC
    LIMIT 20, 20;