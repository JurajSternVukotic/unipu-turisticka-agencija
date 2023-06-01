USE  turisticka_agencija;

-- Autor: Karlo Bazina


-- Prikaz svih zaposlenika koji rade na određeno ili na neodređeno koji imaju više od dvije recenzije,
-- a prosjek ocjena im je 4.5 ili veći, te smo im uvećali plaću za 10 %


CREATE VIEW pogled as
	SELECT o.puno_ime, count(r.ocjena) AS broj, AVG(r.ocjena) AS pros, z.placa
	FROM zaposlenik z JOIN osoba o ON z.id=o.id 
	JOIN recenzija_zaposlenika rz ON z.id=rz.id_zaposlenik
	JOIN recenzija r ON r.id=rz.id_recenzija
	WHERE z.ugovor_o_radu='na određeno' OR z.ugovor_o_radu='na neodređeno'
	GROUP BY o.puno_ime, z.placa
	ORDER BY pros DESC
;

SELECT *, placa*1.1 AS uvecana
FROM pogled
WHERE broj>=2 AND pros>=4.5
;


-- Prikaži mi zaposlenika sa največom plaćom iz Zagreba, Osijeka, Splita i Rijeke


SELECT z.id, o.puno_ime, z.placa, g.naziv AS grad
FROM zaposlenik z
JOIN osoba o ON z.id = o.id
JOIN adresa a ON o.id_adresa = a.id
JOIN grad g ON a.id_grad = g.id
WHERE g.naziv IN ('Osijek', 'Zagreb', 'Split', 'Rijeka')
AND z.placa = (
  SELECT MAX(placa)
  FROM zaposlenik z2
  JOIN osoba o2 ON z2.id = o2.id
  JOIN adresa a2 ON o2.id_adresa = a2.id
  JOIN grad g2 ON a2.id_grad = g2.id
  WHERE g2.naziv = g.naziv
)
ORDER BY placa DESC
;


-- Osoba traži putnog agenta koji 1.6. radi popodnevnu smjenu, i može se naći uživo sa njim u Bilbau


SELECT o.puno_ime, z.placa, g.naziv,rs.datum, rs.smjena
FROM zaposlenik z JOIN osoba o ON z.id=o.id 
JOIN adresa a ON o.id_adresa=a.id
JOIN grad g ON a.id_grad=g.id
JOIN radna_smjena rs ON rs.id_zaposlenik=z.id
JOIN pozicija_zaposlenika pz ON pz.id_zaposlenik=z.id
JOIN pozicija p ON p.id=pz.id_pozicija
WHERE rs.datum = '2023-06-01' AND rs.smjena = 'popodnevna' AND p.ime_pozicije ='putni agent' AND g.naziv ='Bilbao'
ORDER BY z.placa DESC 
LIMIT 1
;

