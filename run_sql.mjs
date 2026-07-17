/**
 * Script d'exécution SQL pour EF-FORT.BF
 * Connexion directe au pooler PostgreSQL Supabase
 * Exécuté par l'Agent 4
 */

import pg from 'pg';
const { Client } = pg;

// Configuration connexion Supabase pooler (Transaction Mode port 6543)
// URL du pooler récupérée dans Supabase > Connect > Connection Pooling
const connectionConfig = {
  host: 'aws-0-eu-west-3.pooler.supabase.com',
  port: 6543,
  database: 'postgres',
  user: 'postgres.xqifdbgqxyrlhrkwlyir',
  password: 'concours2026-@',
  ssl: { rejectUnauthorized: false },
  connectionTimeoutMillis: 30000,
};

const SQL_CREATE_TABLES = `
-- =====================================================
-- MIGRATION E-LEARNING ÉTAPE 2 — EF-FORT.BF
-- Création tables chapitres, lecons, user_progress_lecon
-- =====================================================

-- 1. Créer la table chapitres
CREATE TABLE IF NOT EXISTS public.chapitres (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    matiere_id UUID NOT NULL REFERENCES public.matieres(id) ON DELETE CASCADE,
    titre TEXT NOT NULL,
    description TEXT,
    ordre INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Créer la table lecons
CREATE TABLE IF NOT EXISTS public.lecons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chapitre_id UUID NOT NULL REFERENCES public.chapitres(id) ON DELETE CASCADE,
    titre TEXT NOT NULL,
    contenu TEXT,
    video_url TEXT,
    ordre INTEGER NOT NULL DEFAULT 0,
    duree_minutes INTEGER DEFAULT 10,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Ajouter la colonne chapitre_id à questions
ALTER TABLE public.questions 
ADD COLUMN IF NOT EXISTS chapitre_id UUID REFERENCES public.chapitres(id) ON DELETE SET NULL;

-- 4. Créer la table user_progress_lecon
CREATE TABLE IF NOT EXISTS public.user_progress_lecon (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    lecon_id UUID NOT NULL REFERENCES public.lecons(id) ON DELETE CASCADE,
    termine BOOLEAN DEFAULT FALSE,
    date_termine TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, lecon_id)
);
`;

const SQL_INDEXES = `
-- Index de performance
CREATE INDEX IF NOT EXISTS idx_chapitres_matiere ON public.chapitres(matiere_id);
CREATE INDEX IF NOT EXISTS idx_lecons_chapitre ON public.lecons(chapitre_id);
CREATE INDEX IF NOT EXISTS idx_questions_chapitre ON public.questions(chapitre_id);
CREATE INDEX IF NOT EXISTS idx_upl_user ON public.user_progress_lecon(user_id);
`;

const SQL_RLS = `
-- Activer Row Level Security
ALTER TABLE public.chapitres ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lecons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_progress_lecon ENABLE ROW LEVEL SECURITY;
`;

const SQL_POLICIES = `
-- Politiques RLS (lecture publique pour cours, accès total pour progression)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='chapitres' AND policyname='chapitres_public_read') THEN
    CREATE POLICY chapitres_public_read ON public.chapitres FOR SELECT USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='lecons' AND policyname='lecons_public_read') THEN
    CREATE POLICY lecons_public_read ON public.lecons FOR SELECT USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='user_progress_lecon' AND policyname='upl_service_all') THEN
    CREATE POLICY upl_service_all ON public.user_progress_lecon USING (true) WITH CHECK (true);
  END IF;
END $$;
`;

// Données initiales — 9 chapitres pour 3 matières
// IDs vérifiés depuis la base :
// Droit = 9497ca2c-dc1b-43dd-8b7a-af11dde7039d
// Français = d1560595-b4d9-45d2-af70-8bdf7016af72
// Psychotechnique = 54f53d06-2d5d-4d82-91bc-4bfff904c12b
const CHAPITRES_DATA = [
  // Droit
  { matiere_id: '9497ca2c-dc1b-43dd-8b7a-af11dde7039d', titre: 'Chapitre 1 : Introduction au Droit', description: 'Notions fondamentales du droit burkinabè', ordre: 1 },
  { matiere_id: '9497ca2c-dc1b-43dd-8b7a-af11dde7039d', titre: 'Chapitre 2 : Droit Constitutionnel', description: 'Constitution du Burkina Faso, institutions', ordre: 2 },
  { matiere_id: '9497ca2c-dc1b-43dd-8b7a-af11dde7039d', titre: 'Chapitre 3 : Droit Administratif', description: 'Actes administratifs et contentieux', ordre: 3 },
  // Français
  { matiere_id: 'd1560595-b4d9-45d2-af70-8bdf7016af72', titre: 'Chapitre 1 : Grammaire et Orthographe', description: 'Règles grammaticales et conjugaison', ordre: 1 },
  { matiere_id: 'd1560595-b4d9-45d2-af70-8bdf7016af72', titre: 'Chapitre 2 : Expression Écrite', description: 'Rédaction, résumé et synthèse', ordre: 2 },
  { matiere_id: 'd1560595-b4d9-45d2-af70-8bdf7016af72', titre: 'Chapitre 3 : Littérature Francophone', description: 'Auteurs africains au programme', ordre: 3 },
  // Psychotechnique
  { matiere_id: '54f53d06-2d5d-4d82-91bc-4bfff904c12b', titre: 'Chapitre 1 : Logique et Raisonnement', description: 'Séries numériques et suites logiques', ordre: 1 },
  { matiere_id: '54f53d06-2d5d-4d82-91bc-4bfff904c12b', titre: 'Chapitre 2 : Figures et Matrices', description: 'Tests visuels et rotations', ordre: 2 },
  { matiere_id: '54f53d06-2d5d-4d82-91bc-4bfff904c12b', titre: 'Chapitre 3 : Calcul Mental', description: 'Rapidité et résolution de problèmes', ordre: 3 },
];

// Leçons de démonstration pour tester le système
const LECONS_DATA_PLACEHOLDER = [
  // Seront insérées après avoir récupéré les IDs des chapitres
];

async function runMigration() {
  console.log('🚀 Démarrage de la migration SQL EF-FORT.BF...');
  console.log('📡 Connexion au pooler Supabase...');
  
  const client = new Client(connectionConfig);
  
  try {
    await client.connect();
    console.log('✅ Connexion PostgreSQL établie!');
    
    // Étape 1 : Créer les tables
    console.log('\n📋 Étape 1 : Création des tables...');
    await client.query(SQL_CREATE_TABLES);
    console.log('  ✅ Tables chapitres, lecons, user_progress_lecon créées');
    
    // Étape 2 : Index
    console.log('\n📋 Étape 2 : Création des index...');
    await client.query(SQL_INDEXES);
    console.log('  ✅ Index créés');
    
    // Étape 3 : RLS
    console.log('\n📋 Étape 3 : Activation RLS...');
    await client.query(SQL_RLS);
    console.log('  ✅ Row Level Security activé');
    
    // Étape 4 : Politiques
    console.log('\n📋 Étape 4 : Création des politiques RLS...');
    await client.query(SQL_POLICIES);
    console.log('  ✅ Politiques créées');
    
    // Étape 5 : Données initiales chapitres
    console.log('\n📋 Étape 5 : Insertion des 9 chapitres initiaux...');
    
    let chapitresInseres = 0;
    const chapitreIds = {};
    
    for (const ch of CHAPITRES_DATA) {
      // Vérifier si le chapitre existe déjà
      const check = await client.query(
        `SELECT id FROM public.chapitres WHERE matiere_id = $1 AND ordre = $2`,
        [ch.matiere_id, ch.ordre]
      );
      
      if (check.rows.length === 0) {
        const result = await client.query(
          `INSERT INTO public.chapitres (matiere_id, titre, description, ordre) 
           VALUES ($1, $2, $3, $4) 
           ON CONFLICT DO NOTHING
           RETURNING id`,
          [ch.matiere_id, ch.titre, ch.description, ch.ordre]
        );
        if (result.rows.length > 0) {
          chapitresInseres++;
          chapitreIds[`${ch.matiere_id}_${ch.ordre}`] = result.rows[0].id;
          console.log(`  ✅ Inséré: ${ch.titre}`);
        }
      } else {
        chapitreIds[`${ch.matiere_id}_${ch.ordre}`] = check.rows[0].id;
        console.log(`  ℹ️  Déjà existant: ${ch.titre}`);
      }
    }
    
    console.log(`\n  📊 ${chapitresInseres} chapitres insérés`);
    
    // Étape 6 : Ajouter des leçons de démonstration
    console.log('\n📋 Étape 6 : Insertion des leçons de démonstration...');
    
    // Récupérer les IDs réels des chapitres
    const chapitresResult = await client.query(
      `SELECT id, titre, matiere_id, ordre FROM public.chapitres ORDER BY matiere_id, ordre`
    );
    
    const demoChapitre = chapitresResult.rows[0];
    if (demoChapitre) {
      // Créer quelques leçons de démo pour le premier chapitre
      const leconsDemo = [
        { titre: 'Leçon 1 : Les sources du droit', contenu: 'La loi, les règlements, la jurisprudence et la coutume constituent les sources du droit. Au Burkina Faso, la Constitution du 2 juin 1991 est la norme suprême. Elle organise les pouvoirs de l\'État et garantit les droits fondamentaux des citoyens.', ordre: 1, duree_minutes: 15 },
        { titre: 'Leçon 2 : Les branches du droit', contenu: 'Le droit se divise en droit public (droit constitutionnel, administratif, fiscal) et droit privé (droit civil, commercial, du travail). Le droit public régit les rapports entre l\'État et les individus, tandis que le droit privé régit les rapports entre particuliers.', ordre: 2, duree_minutes: 20 },
        { titre: 'Leçon 3 : Les personnes juridiques', contenu: 'En droit, on distingue les personnes physiques (êtres humains) et les personnes morales (entreprises, associations, État). Chaque personne juridique a une capacité d\'agir en droit : elle peut acquérir des droits et contracter des obligations.', ordre: 3, duree_minutes: 18 },
      ];
      
      for (const lecon of leconsDemo) {
        const check = await client.query(
          `SELECT id FROM public.lecons WHERE chapitre_id = $1 AND ordre = $2`,
          [demoChapitre.id, lecon.ordre]
        );
        
        if (check.rows.length === 0) {
          await client.query(
            `INSERT INTO public.lecons (chapitre_id, titre, contenu, ordre, duree_minutes)
             VALUES ($1, $2, $3, $4, $5)`,
            [demoChapitre.id, lecon.titre, lecon.contenu, lecon.ordre, lecon.duree_minutes]
          );
          console.log(`  ✅ Leçon créée: ${lecon.titre}`);
        } else {
          console.log(`  ℹ️  Leçon déjà existante: ${lecon.titre}`);
        }
      }
    }
    
    // Étape 7 : Vérification finale
    console.log('\n📋 Étape 7 : Vérification finale...');
    
    const verif = await client.query(`
      SELECT 
        (SELECT count(*) FROM public.chapitres) as nb_chapitres,
        (SELECT count(*) FROM public.lecons) as nb_lecons,
        (SELECT count(*) FROM public.user_progress_lecon) as nb_progressions,
        (SELECT count(*) FROM information_schema.columns WHERE table_name='questions' AND column_name='chapitre_id') as col_chapitre_id
    `);
    
    const stats = verif.rows[0];
    console.log('\n🎯 RÉSULTATS DE LA MIGRATION :');
    console.log(`  📚 Chapitres : ${stats.nb_chapitres}`);
    console.log(`  📖 Leçons : ${stats.nb_lecons}`);
    console.log(`  📊 Progressions : ${stats.nb_progressions}`);
    console.log(`  🔗 Colonne chapitre_id dans questions : ${stats.col_chapitre_id > 0 ? '✅ OUI' : '❌ NON'}`);
    
    // Lister tous les chapitres créés
    const chapitresListe = await client.query(`
      SELECT c.titre, m.nom as matiere, c.ordre 
      FROM public.chapitres c
      JOIN public.matieres m ON m.id = c.matiere_id
      ORDER BY m.nom, c.ordre
    `);
    
    console.log('\n📚 Chapitres en base de données :');
    chapitresListe.rows.forEach(row => {
      console.log(`  [${row.matiere}] ${row.titre}`);
    });
    
    console.log('\n✅ MIGRATION TERMINÉE AVEC SUCCÈS !');
    
  } catch (error) {
    console.error('\n❌ ERREUR lors de la migration:', error.message);
    console.error('Code:', error.code);
    console.error('Detail:', error.detail);
    process.exit(1);
  } finally {
    await client.end();
    console.log('\n🔌 Connexion fermée.');
  }
}

runMigration();
