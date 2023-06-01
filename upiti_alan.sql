USE turisticka_agencija;

-- Autor: Alan Burić

### Alan Burić ###
-- POGLEDI - pohranjeni upiti

-- Prikazuje sve IDjeve zaposlenika koji su putni agenti.
-- CREATE VIEW svi_putni_agenti AS SELECT id_zaposlenik AS id FROM pozicija_zaposlenika WHERE id_pozicija = (SELECT id FROM pozicija WHERE ime_pozicije = 'putni agent');

-- 1. Pronađi ID pozicije 'putni agent'
-- 2. Pronađi sve zaposlenike s tom pozicijom (preko IDja)
-- 3. Pobroji njihova pojavljivanja
-- 4. Sortiraj ih od najmanjeg prema najvećem

-- CREATE VIEW zaposlenost_rezervacije AS 
-- 	SELECT *, COUNT(*) AS kolicina_posla 
-- 		FROM svi_putni_agenti 
-- 			LEFT JOIN 
-- 	(SELECT zaposlenik_id AS id FROM rezervacija) AS rezervacija 
-- 			USING (id);
