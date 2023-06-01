USE turisticka_agencija;

### Alan Burić ###

-- Testni primjeri:
INSERT INTO kupon VALUE(NULL, 'Čščđćž32', MAKEDATE(2023, 100), MAKEDATE(2023, 140), 20, 1);
SELECT * FROM kupon;

INSERT INTO rezervacija VALUE(NULL, 50, 113, 48, NOW());

-- Pogled rezervacija i kupona koji su primjenjeni na njih s iznosom i vrsti kupona
CREATE VIEW kuponi_rezervacije AS SELECT * FROM kupon INNER JOIN kupon_rezervacija USING (id_kupon);

-- Test
SELECT * FROM kuponi_rezervacije;

-- Pogled cijena rezervacija prema njihovim paketima
CREATE VIEW rezervacija_paket_cijena AS SELECT * FROM (SELECT id AS id_paket, cijena_po_turistu AS cijena FROM paket) AS paket INNER JOIN (SELECT id AS id_rezervacija, id_paket FROM rezervacija) AS rezervacija USING (id_paket);

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

-- Test
SELECT * FROM cijene_rezervacija;

-- 2. Prikažite sve potpuno plaćene rezervacije
SELECT * FROM 
		(SELECT id_rezervacija, SUM(iznos) AS uplaceno 
			FROM uplata 
			GROUP BY id_rezervacija) 
			AS uplata 
	INNER JOIN 
		(SELECT id_rezervacija, cijena 
        FROM cijene_rezervacija) 
        AS cr
	INNER JOIN 
		(SELECT id AS id_rezervacija, id_osoba, id_paket, id_zaposlenik, vrijeme 
        FROM rezervacija) 
        AS r
	USING (id_rezervacija) 
    HAVING uplaceno >= cijena;

-- 4. Pronađite najčešće korištene kupone sortirane prema padajućemu poretku s novim stupcem "kolicina"
SELECT id_kupon, kod, datum_pocetka, datum_kraja, iznos, postotni, COUNT(*) AS kolicina 
	FROM kupon_rezervacija INNER JOIN kupon USING (id_kupon) 
    GROUP BY id_kupon 
    ORDER BY kolicina DESC;

-- 5. Pronađite pakete čija su putovanja popunjena
SELECT * FROM 
		(SELECT id AS id_paket, naziv, opis, min_ljudi, max_ljudi, cijena_po_turistu 
        FROM paket) 
        AS p 
	INNER JOIN 
		(SELECT id_paket, COUNT(*) AS broj_ljudi 
        FROM rezervacija 
        GROUP BY id_paket) 
        AS p2 
	USING (id_paket) 
    HAVING broj_ljudi >= max_ljudi;

-- 6. Prikažite drugu po redu stranicu najpopularnijih paketa s obzirom na rezervacije s time da se na svakoj stranici prikazuje 20 rezultata.
SELECT * FROM
		(SELECT id_paket, COUNT(*) AS popularnost 
		FROM rezervacija
		GROUP BY id_paket 
		ORDER BY popularnost DESC
		LIMIT 20, 20) AS r
	INNER JOIN
		(SELECT id AS id_paket, naziv, opis, min_ljudi, max_ljudi, cijena_po_turistu FROM paket) AS p
	USING (id_paket);

-- 7. Povežite putne agente rezervacija s prvim posebnim zahtjevom čak i ako nema posebnih zahtjeva, u vremenskome intervalu od 06.05.2023. do 14.05.2023. i čija je cijena rezervacije natprosječna
SELECT * FROM 
		posebni_zahtjev 
    RIGHT OUTER JOIN 
		(SELECT id AS id_rezervacija, vrijeme, id_zaposlenik 
		FROM rezervacija
        WHERE vrijeme BETWEEN STR_TO_DATE('06.05.2023.', '%d.%m.%Y.') AND STR_TO_DATE('14.05.2023.', '%d.%m.%Y.')) # Alternativno DATE('2023-05-06') AND DATE('2023-05-14')
        AS rez 
	USING (id_rezervacija)
    LEFT OUTER JOIN 
		(SELECT id AS id_zaposlenik, ugovor_o_radu, placa FROM zaposlenik) AS z
	USING (id_zaposlenik)
    HAVING (SELECT cijena 
			FROM cijene_rezervacija 
            WHERE cijene_rezervacija.id_rezervacija = rez.id_rezervacija) 
				> 
            (SELECT AVG(cijena) 
            FROM cijene_rezervacija);