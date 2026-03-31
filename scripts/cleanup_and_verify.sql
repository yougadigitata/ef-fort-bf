-- ================================================================
-- EF-FORT.BF — Script de nettoyage et vérification
-- À exécuter dans Supabase SQL Editor :
-- https://supabase.com/dashboard/project/xqifdbgqxyrlhrkwlyir/sql/new
-- ================================================================

-- 1. VOIR L'ÉTAT ACTUEL PAR MATIÈRE
SELECT 
  m.code,
  m.nom,
  COUNT(q.id) AS nb_questions,
  COUNT(DISTINCT q.serie_id) AS nb_series
FROM matieres m
LEFT JOIN questions q ON q.matiere_id = m.id AND q.published = true
GROUP BY m.id, m.code, m.nom
ORDER BY nb_questions DESC;

-- 2. VÉRIFIER LA MATIÈRE HISTO (Figure Africaine - 600 questions / 30 séries)
SELECT 
  m.id AS matiere_id, m.code, m.nom,
  COUNT(q.id) AS nb_questions,
  COUNT(DISTINCT q.serie_id) AS nb_series
FROM matieres m
JOIN questions q ON q.matiere_id = m.id
WHERE UPPER(m.code) = 'HISTO'
GROUP BY m.id, m.code, m.nom;

-- 3. VÉRIFIER LES SÉRIES DE HISTO (30 séries attendues de 20 questions chacune)
SELECT 
  s.numero, s.titre, COUNT(q.id) AS vraies_questions
FROM series_qcm s
JOIN matieres m ON m.id = s.matiere_id
LEFT JOIN questions q ON q.serie_id = s.id
WHERE UPPER(m.code) = 'HISTO'
GROUP BY s.id, s.numero, s.titre
ORDER BY s.numero;

-- 4. NETTOYER : SUPPRIMER TOUS LES QCM SAUF HISTO (Figure Africaine)
-- ⚠️ À EXÉCUTER SEULEMENT APRÈS VALIDATION DE L'IMPORT HISTO
-- Décommenter les lignes ci-dessous :

/*
-- a) Supprimer les questions des autres matières
DELETE FROM questions
WHERE matiere_id IN (
  SELECT id FROM matieres WHERE UPPER(code) != 'HISTO'
);

-- b) Supprimer les séries des autres matières
DELETE FROM series_qcm
WHERE matiere_id IN (
  SELECT id FROM matieres WHERE UPPER(code) != 'HISTO'
);

-- c) Mettre à jour nb_questions à 0 pour les autres matières
UPDATE matieres SET nb_questions = 0
WHERE UPPER(code) != 'HISTO';

-- d) Vérification post-nettoyage
SELECT m.code, m.nom, COUNT(q.id) AS nb_questions_restantes
FROM matieres m
LEFT JOIN questions q ON q.matiere_id = m.id
GROUP BY m.id, m.code, m.nom
ORDER BY nb_questions_restantes DESC;
*/

-- 5. VÉRIFICATION FINALE DES SÉRIES HISTO SANS RÉPÉTITION
SELECT 
  q.numero_serie,
  COUNT(q.id) AS nb_questions,
  COUNT(DISTINCT q.enonce) AS nb_uniques
FROM questions q
JOIN matieres m ON m.id = q.matiere_id
WHERE UPPER(m.code) = 'HISTO'
GROUP BY q.numero_serie
ORDER BY q.numero_serie;
