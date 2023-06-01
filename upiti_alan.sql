USE turisticka_agencija;

### Alan Burić ###

-- Testni primjeri:
INSERT INTO kupon VALUE(NULL, 'Čščđćž32', MAKEDATE(2023, 100), MAKEDATE(2023, 140), 20, 1);
SELECT * FROM kupon;

-- Pogled rezervacija i kupona koji su primjenjeni na njih s iznosom i vrsti kupona
CREATE VIEW kuponi_rezervacije AS SELECT * FROM kupon JOIN kupon_rezervacija USING (id_kupon);
            
SELECT * FROM kuponi_rezervacije;

-- Pogled cijena rezervacija prema njihovim paketima
CREATE VIEW rezervacija_paket_cijena AS SELECT * FROM (SELECT id AS id_paket, cijena_po_turistu AS cijena FROM paket) AS paket JOIN (SELECT id AS id_rezervacija, id_paket FROM rezervacija) AS rezervacija USING (id_paket);

SELECT * FROM rezervacija_paket_cijena;

-- 1. Pronađite prave iznose cijena rezervacija s obzirom na primjenu kupon koda prema formuli novi_iznos = max(0, (cijena - SUM(ne postotnih kupona)) * max(1, 1 - SUM(postotnih kupona) / 100)
CREATE VIEW cijene_rezervacija AS SELECT id_rezervacija, 
			GREATEST(0, 
				cijena - IFNULL((SELECT SUM(iznos) 
								FROM kuponi_rezervacije AS kr 
								WHERE NOT postotni AND kr.id_rezervacija = rpc.id_rezervacija),
								0) 
            * GREATEST(1, 
				IFNULL(1 - (SELECT SUM(iznos) 
							FROM kuponi_rezervacije AS kr 
                            WHERE postotni AND kr.id_rezervacija = rpc.id_rezervacija) / 100, 1))) 
			AS cijena
	FROM rezervacija_paket_cijena AS rpc;

SELECT * FROM cijene_rezervacija;

-- 2. Prikažite sve potpuno plaćene rezervacije
SELECT * FROM 
		(SELECT id_rezervacija, SUM(iznos) AS uplaceno 
			FROM uplata 
			GROUP BY id_rezervacija) 
			AS uplata 
	JOIN 
		(SELECT id_rezervacija, cijena 
        FROM cijene_rezervacija) 
        AS cr
	JOIN 
		(SELECT id AS id_rezervacija, id_osoba, id_paket, id_zaposlenik, vrijeme 
        FROM rezervacija) 
        AS r
	USING (id_rezervacija) 
    HAVING uplaceno >= cijena;

-- 4. Pronađite najčešće korištene kupone sortirane prema padajućemu poretku s novim stupcem "kolicina"
SELECT id_kupon, kod, datum_pocetka, datum_kraja, iznos, postotni, COUNT(*) AS kolicina 
	FROM 
		kupon_rezervacija 
        JOIN 
        kupon 
		USING (id_kupon) 
    GROUP BY id_kupon 
    ORDER BY kolicina DESC;

-- 5. Prikažite drugu po redu stranicu najpopularnijih paketa s obzirom na rezervacije s time da se na svakoj stranici prikazuje 20 rezultata.
SELECT id_paket, COUNT(*) popularnost 
	FROM rezervacija
    GROUP BY id_paket 
    ORDER BY popularnost DESC
    LIMIT 20, 20;