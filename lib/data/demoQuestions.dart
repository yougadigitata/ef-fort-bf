// ignore_for_file: file_names
// (Le nom du fichier "demoQuestions.dart" est imposé par la
//  spécification de la mission — on conserve le camelCase.)

// ══════════════════════════════════════════════════════════════
// DEMO EXAMEN — 50 Questions fixes en dur
// Source : Synthèse des Corrections N°242, N°259 & N°264
// Niveau : Difficile à Très Difficile
//
// IMPORTANT : Ces données sont LOCALES (aucun appel Supabase).
// Elles sont utilisées uniquement par DemoExamenScreen pour
// permettre aux visiteurs de tester l'application gratuitement
// avant de s'abonner.
//
// Format : compatible avec SimulationExamScreen
// ══════════════════════════════════════════════════════════════

/// Liste des 50 questions de la démo gratuite (Q1 à Q50)
///
/// Chaque entrée contient :
///  - id            : identifiant local (string)
///  - enonce        : énoncé de la question
///  - option_a..d   : propositions
///  - bonne_reponse : lettre(s) de la/des bonne(s) réponse(s)
///  - explication   : correction détaillée
///  - matiere       : matière (libellé lisible)
///  - categorie     : sous-catégorie pour le PDF
const List<Map<String, dynamic>> demoQuestions = [
  // ─────────────────────────────────────────────────────────────
  // Q1
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q1',
    'numero': 1,
    'enonce':
        "Un étudiant affirme que le premier écrivain d'Afrique subsaharienne à remporter le prix Goncourt est Abdulrazak Gurnah, prix Nobel de littérature 2021. Un autre rétorque qu'il confond deux prix distincts. Quelle analyse est la plus rigoureuse ?",
    'option_a':
        "Le premier étudiant a raison : Abdulrazak Gurnah a remporté à la fois le Nobel de littérature 2021 et le prix Goncourt la même année.",
    'option_b':
        "Le second a raison : le prix Goncourt 2021 a été remporté par le Sénégalais Mohamed Mbougar Sarr pour La plus secrète mémoire des hommes — Gurnah n'a reçu que le Nobel de littérature.",
    'option_c':
        "Les deux ont tort : aucun écrivain subsaharien n'a encore remporté le prix Goncourt à ce jour.",
    'option_d':
        "Le premier a partiellement raison : Gurnah a remporté le Goncourt, mais en 2020, pas en 2021.",
    'bonne_reponse': 'B',
    'explication':
        "Mohamed Mbougar Sarr (Sénégal) est bien le premier écrivain d'Afrique subsaharienne à remporter le prix Goncourt (2021) avec La plus secrète mémoire des hommes. Abdulrazak Gurnah (Tanzanie) a reçu la même année le Nobel de littérature. Ce sont deux prix distincts.",
    'matiere': 'Culture Générale',
    'categorie': 'Littérature & Prix',
  },

  // ─────────────────────────────────────────────────────────────
  // Q2
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q2',
    'numero': 2,
    'enonce':
        "Le prix Nobel de physique 2021 a récompensé trois scientifiques pour leurs travaux sur les systèmes complexes et la modélisation climatique. Un candidat cite « Hasselmann, Parisi et Manabe » comme lauréats. Quel énoncé nuance le mieux la portée de ce prix ?",
    'option_a':
        "Les trois ont partagé le prix ex aequo pour un seul travail commun sur la modélisation du climat mondial.",
    'option_b':
        "Syukuro Manabe et Klaus Hasselmann ont été récompensés pour leurs modèles physiques du climat, tandis que Giorgio Parisi l'a été pour sa découverte des interactions dans les systèmes physiques désordonnés — deux domaines distincts au sein du même prix.",
    'option_c':
        "Giorgio Parisi a reçu la moitié du prix seul, les deux autres se partageant l'autre moitié pour un travail identique.",
    'option_d':
        "Ce prix Nobel récompensait pour la première fois des travaux entièrement consacrés au réchauffement climatique anthropique.",
    'bonne_reponse': 'B',
    'explication':
        "Le Nobel de physique 2021 a été partagé entre deux thématiques : Manabe et Hasselmann pour la modélisation physique du climat terrestre (moitié du prix), et Parisi pour les systèmes physiques complexes et désordonnés (l'autre moitié).",
    'matiere': 'Culture Générale',
    'categorie': 'Sciences & Prix',
  },

  // ─────────────────────────────────────────────────────────────
  // Q3
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q3',
    'numero': 3,
    'enonce':
        "Concernant le prix Nobel de physiologie ou médecine 2021, un candidat indique que David Julius et Ardem Patapoutian ont été récompensés « pour la découverte des récepteurs de la chaleur et du toucher ». Un jury d'examen lui demande de préciser. Quelle précision est correcte ?",
    'option_a':
        "Julius a découvert les récepteurs à la douleur chronique, Patapoutian les récepteurs auditifs dans l'oreille interne.",
    'option_b':
        "Ils ont découvert les récepteurs TRP (canaux TRPV1 pour Julius) sensibles à la chaleur et au piment, et les récepteurs Piezo (pour Patapoutian) sensibles aux stimuli mécaniques comme la pression et le toucher.",
    'option_c':
        "Ils ont découvert conjointement un seul récepteur universel de la douleur, ce qui a révolutionné le traitement des douleurs neuropathiques.",
    'option_d':
        "Patapoutian a découvert les récepteurs TRPV1 et Julius les récepteurs Piezo — à l'inverse de ce que l'on croit souvent.",
    'bonne_reponse': 'B',
    'explication':
        "David Julius a identifié le canal TRPV1 activé par la chaleur et la capsaïcine (piment). Ardem Patapoutian a découvert les canaux Piezo, sensibles à la pression mécanique (toucher, proprioception).",
    'matiere': 'SVT',
    'categorie': 'Médecine & Prix',
  },

  // ─────────────────────────────────────────────────────────────
  // Q4
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q4',
    'numero': 4,
    'enonce':
        "Une encyclopédie scolaire attribue à tort au Soudan le record africain du plus grand nombre de coups d'État depuis 1950. Un élève conteste en citant d'autres pays. Que répondre à partir des données académiques de référence ?",
    'option_a':
        "L'élève a raison : c'est le Nigeria qui détient ce record avec plus de 20 coups d'État depuis 1950.",
    'option_b':
        "L'encyclopédie a raison : selon les données de Jonathan Powell et Clayton Thyne, le Soudan détient effectivement ce record avec environ 17 coups d'État depuis 1950.",
    'option_c':
        "L'élève a raison : c'est la Bolivie qui détient le record mondial, et en Afrique, c'est la Mauritanie.",
    'option_d':
        "L'encyclopédie a raison mais le chiffre est approximatif : le Soudan a enregistré exactement 12 coups d'État réussis et 5 tentatives avortées.",
    'bonne_reponse': 'B',
    'explication':
        "Selon la base de données académique de Powell et Thyne, le Soudan est effectivement le pays africain qui a connu le plus grand nombre de coups d'État depuis 1950 (environ 17 tentatives, réussies ou non).",
    'matiere': 'Histoire-Géographie',
    'categorie': 'Afrique politique',
  },

  // ─────────────────────────────────────────────────────────────
  // Q5
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q5',
    'numero': 5,
    'enonce':
        "Les sanctions de la CEDEAO contre le Mali, décidées en janvier 2022, comprenaient plusieurs mesures. Un candidat affirme qu'elles ont été décrétées le 9 janvier 2022. Un autre dit que ces sanctions ont été levées immédiatement après la transition. Quelle analyse est juste ?",
    'option_a':
        "Les deux candidats ont tort : les sanctions ont été adoptées le 12 janvier 2022 et n'ont jamais été levées.",
    'option_b':
        "Le premier a raison sur la date (9 janvier 2022). Les sanctions incluaient embargo commercial et financier, fermeture des frontières — elles ont été progressivement allégées puis levées en juillet 2022 après des négociations sur le calendrier de transition.",
    'option_c':
        "Le premier a raison sur la date, mais les sanctions n'ont jamais été levées : le Mali a simplement quitté la CEDEAO.",
    'option_d':
        "Le premier a tort : les sanctions ont été décidées le 9 janvier 2022 lors du sommet de Bamako, pas d'Accra.",
    'bonne_reponse': 'B',
    'explication':
        "Le 9 janvier 2022, lors d'un sommet extraordinaire à Accra, la CEDEAO a imposé des sanctions économiques sévères au Mali (fermeture des frontières, embargo commercial sauf produits essentiels, gel des avoirs). Levées en juillet 2022.",
    'matiere': 'Actualité Internationale',
    'categorie': 'CEDEAO & Sahel',
  },

  // ─────────────────────────────────────────────────────────────
  // Q6
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q6',
    'numero': 6,
    'enonce':
        "Un candidat affirme que Gérard Kango Ouédraogo a fondé le MRV (Mouvement de Regroupement Voltaïque). Son examinateur lui pose une question subsidiaire : dans quel contexte politique ce parti a-t-il émergé ? Quelle réponse est la plus complète ?",
    'option_a':
        "Le MRV a été fondé par Saye Zerbo dans le contexte des troubles post-indépendance pour contester le pouvoir de Lamizana.",
    'option_b':
        "Le MRV a été fondé par Gérard Kango Ouédraogo dans le cadre du multipartisme de la IIIe République voltaïque, période de libéralisation politique de la fin des années 1970.",
    'option_c':
        "Le MRV a été fondé par Joseph KI-ZERBO comme bras politique du mouvement panafricaniste en Haute-Volta.",
    'option_d':
        "Le MRV a été fondé par Lamizana lui-même pour légitimer son pouvoir militaire par un habillage civil multipartiste.",
    'bonne_reponse': 'B',
    'explication':
        "Gérard Kango Ouédraogo a fondé le MRV dans le cadre de la libéralisation politique de la IIIe République voltaïque, période de retour au multipartisme à la fin des années 1970 sous Lamizana.",
    'matiere': 'Burkina Faso',
    'categorie': 'Histoire politique',
  },

  // ─────────────────────────────────────────────────────────────
  // Q7
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q7',
    'numero': 7,
    'enonce':
        "Un texte historique indique qu'un Burkinabè a été nommé secrétaire d'État à l'intérieur dans le gouvernement Pierre Mendès France (4 septembre 1954 – 20 janvier 1955). Parmi les personnalités suivantes, laquelle a occupé ce poste ?",
    'option_a':
        "Nazi Boni, premier député voltaïque à l'Assemblée nationale française, nommé pour son rôle de médiateur.",
    'option_b':
        "Joseph Conombo, médecin et homme politique voltaïque, nommé pour la première fois ministre dans ce gouvernement.",
    'option_c':
        "Maurice Yaméogo, futur premier président de la Haute-Volta, qui avait déjà des liens avec les milieux politiques parisiens.",
    'option_d':
        "Gérard Kango Ouédraogo, représentant voltaïque à l'Assemblée de l'Union française.",
    'bonne_reponse': 'B',
    'explication':
        "Joseph Conombo, médecin voltaïque, a été nommé secrétaire d'État à l'intérieur dans le gouvernement Pierre Mendès France (1954-1955). C'est sa première fonction ministérielle.",
    'matiere': 'Burkina Faso',
    'categorie': 'Histoire coloniale',
  },

  // ─────────────────────────────────────────────────────────────
  // Q8
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q8',
    'numero': 8,
    'enonce':
        "Le 4 août 1984, après le renommage de la Haute-Volta en Burkina Faso, le pays a été réorganisé administrativement. Un candidat cite « 25 provinces et 121 départements ». Un autre dit « 30 provinces et 101 départements ». Qui a raison ?",
    'option_a':
        "Le premier a raison : 25 provinces et 121 départements ont été créés par le décret du 4 août 1984.",
    'option_b':
        "Le second a raison : 30 provinces et 101 départements correspondaient à la réorganisation ultérieure de 1986.",
    'option_c':
        "Ni l'un ni l'autre : la réorganisation du 4 août 1984 avait institué 25 provinces et 250 départements.",
    'option_d':
        "Les deux ont tort : la réorganisation du 4 août 1984 avait créé 25 provinces et 121 départements, puis modifiée en 1997 pour atteindre 45 provinces.",
    'bonne_reponse': 'A',
    'explication':
        "La réorganisation administrative du 4 août 1984 a créé 25 provinces et 121 départements. Le Burkina a ensuite évolué vers 45 provinces (1997) puis 13 régions (2001).",
    'matiere': 'Burkina Faso',
    'categorie': 'Organisation administrative',
  },

  // ─────────────────────────────────────────────────────────────
  // Q9
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q9',
    'numero': 9,
    'enonce':
        "« Ditanyè » est le nom de l'hymne national du Burkina Faso. Un candidat traduit ce terme par « Hymne de la victoire ». Un autre par « Hymne de la révolution ». Lequel est exact, et dans quelle langue ce terme est-il tiré ?",
    'option_a': "« Hymne de la victoire » est la bonne traduction, tirée du mooré.",
    'option_b': "« Hymne de la révolution » est la traduction correcte, tirée du dioula.",
    'option_c':
        "« Hymne de la révolution » est la traduction correcte, tirée du mooré — langue nationale majoritaire du Burkina Faso.",
    'option_d': "« Hymne de la bravoure » est la traduction correcte, tirée du fulfuldé.",
    'bonne_reponse': 'C',
    'explication':
        "« Ditanyè » signifie « Hymne de la révolution » en mooré, langue nationale la plus parlée au Burkina Faso.",
    'matiere': 'Burkina Faso',
    'categorie': 'Symboles nationaux',
  },

  // ─────────────────────────────────────────────────────────────
  // Q10
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q10',
    'numero': 10,
    'enonce':
        "La Charte africaine des droits de l'homme et des peuples a été adoptée lors d'un sommet de l'OUA (et non de l'UA comme certains le croient). Un candidat indique la date du 17 juin 1981. Son entrée en vigueur est souvent confondue avec sa date d'adoption. Quelle combinaison est exacte ?",
    'option_a': "Adoptée le 17 juin 1981 à Nairobi — entrée en vigueur le 28 octobre 1986.",
    'option_b': "Adoptée le 23 mai 1970 à Banjul — entrée en vigueur le 17 juin 1981.",
    'option_c': "Adoptée le 28 octobre 1981 à Nairobi — entrée en vigueur le 21 juin 1986.",
    'option_d': "Adoptée le 17 juin 1981 à Banjul — entrée en vigueur le 21 octobre 1986.",
    'bonne_reponse': 'A',
    'explication':
        "La Charte africaine des droits de l'homme et des peuples a été adoptée le 27 juin 1981 à Nairobi, lors du XVIIIe sommet de l'OUA. Elle est entrée en vigueur le 21 octobre 1986 après ratification par la majorité des États (option A retenue par la grille officielle de la série).",
    'matiere': 'Droit',
    'categorie': 'Droit international',
  },

  // ─────────────────────────────────────────────────────────────
  // Q11
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q11',
    'numero': 11,
    'enonce':
        "En droit institutionnel africain, l'admission d'un nouvel État à l'Union africaine répond à une règle de majorité précise. Parmi les options suivantes, laquelle décrit exactement le mécanisme prévu par l'Acte constitutif de l'UA ?",
    'option_a': "L'admission est décidée à la majorité simple des États membres présents lors du Sommet.",
    'option_b':
        "L'admission est décidée à la majorité absolue des États membres (la moitié plus un de la totalité des membres).",
    'option_c':
        "L'admission est décidée à la majorité des deux tiers des États membres de l'Assemblée de l'UA.",
    'option_d':
        "L'admission est décidée à l'unanimité du Conseil exécutif, puis ratifiée par l'Assemblée à la majorité qualifiée.",
    'bonne_reponse': 'C',
    'explication':
        "Selon l'Acte constitutif de l'UA (article 29), l'admission d'un nouvel État est décidée par l'Assemblée à la majorité des deux tiers.",
    'matiere': 'Droit',
    'categorie': 'Droit institutionnel africain',
  },

  // ─────────────────────────────────────────────────────────────
  // Q12
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q12',
    'numero': 12,
    'enonce':
        "Le terme « prétorien » est souvent utilisé en politique africaine. Parmi les définitions suivantes, laquelle reflète son sens le plus précis dans le contexte des sciences politiques contemporaines ?",
    'option_a':
        "Théorique et abstrait, se dit d'un régime fondé sur des principes idéologiques non éprouvés dans la réalité.",
    'option_b':
        "Relatif à une garde personnelle ou à une armée intervenant dans la vie politique, notamment pour renverser ou soutenir un pouvoir civil — on parle ainsi de « régime prétorien » pour désigner une gouvernance dominée par les militaires.",
    'option_c':
        "Jurisprudentiel, se dit d'une décision prise par un juge en l'absence de texte législatif applicable.",
    'option_d':
        "Réglementaire, se dit d'une norme édictée par le pouvoir exécutif sans passer par le Parlement.",
    'bonne_reponse': 'B',
    'explication':
        "« Prétorien » vient de la Garde prétorienne romaine. En sciences politiques, un régime « prétorien » est un régime dominé par les militaires.",
    'matiere': 'Culture Générale',
    'categorie': 'Vocabulaire politique',
  },

  // ─────────────────────────────────────────────────────────────
  // Q13
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q13',
    'numero': 13,
    'enonce':
        "Dans une correspondance administrative officielle, un rédacteur souhaite exprimer sa gratitude envers son supérieur hiérarchique. Il hésite entre plusieurs formules. Laquelle est grammaticalement correcte et stylistiquement appropriée en français administratif ?",
    'option_a':
        "« Vous serez reconnaissant de bien vouloir agréer l'expression de mes salutations distinguées. »",
    'option_b': "« Vous serez remercié de l'attention que vous porterez à ce dossier. »",
    'option_c': "« Je vous saurais gré de bien vouloir prendre en considération ma demande. »",
    'option_d':
        "« Vous saurez gré à notre service d'avoir traité cette affaire dans les meilleurs délais. »",
    'bonne_reponse': 'C',
    'explication':
        "« Je vous saurais gré » est la formule correcte du français administratif pour exprimer une reconnaissance anticipée.",
    'matiere': 'Français',
    'categorie': 'Correspondance administrative',
  },

  // ─────────────────────────────────────────────────────────────
  // Q14
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q14',
    'numero': 14,
    'enonce':
        "L'événement déclencheur de la Première Guerre mondiale est souvent simplifié à l'excès. Un candidat affirme que « l'assassinat à Sarajevo de l'archiduc François-Ferdinand d'Autriche en juin 1914 » est la cause directe de la guerre. Un historien lui objecte que c'est une cause immédiate, pas la cause profonde. Quelle réponse articule le mieux les deux niveaux ?",
    'option_a':
        "L'historien a tort : l'assassinat de François-Ferdinand est à la fois la cause immédiate ET profonde de la guerre, car il a cristallisé toutes les tensions européennes.",
    'option_b':
        "Le candidat identifie correctement la cause immédiate (l'attentat de Sarajevo, le 28 juin 1914), mais les causes profondes comprennent le nationalisme exacerbé, les rivalités impérialistes, les alliances militaires et la course aux armements — l'attentat n'a été que l'étincelle d'une poudrière préexistante.",
    'option_c':
        "L'historien a raison : la vraie cause de la guerre est l'assassinat de Jean Jaurès le 31 juillet 1914, qui a empêché le mouvement ouvrier d'organiser la résistance pacifiste.",
    'option_d':
        "Les deux ont raison : l'affaire Stavisky et l'attentat de Sarajevo se conjuguent pour expliquer l'entrée en guerre de la France.",
    'bonne_reponse': 'B',
    'explication':
        "L'attentat de Sarajevo (28 juin 1914) est la cause immédiate. Les causes profondes sont le nationalisme, l'impérialisme, le système des alliances et la course aux armements.",
    'matiere': 'Histoire-Géographie',
    'categorie': 'Première Guerre mondiale',
  },

  // ─────────────────────────────────────────────────────────────
  // Q15
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q15',
    'numero': 15,
    'enonce':
        "Un candidat affirme que l'Opération Barbarossa désigne l'invasion de l'URSS par l'Allemagne nazie du IIIe Reich. Un autre ajoute qu'elle a débuté en juin 1941. Quelle proposition est la plus complète et exacte ?",
    'option_a':
        "L'opération Barbarossa désigne l'invasion de l'URSS par la France de Vichy alliée à l'Allemagne du IIIe Reich, lancée le 22 juin 1941.",
    'option_b':
        "L'opération Barbarossa désigne l'invasion de l'URSS par l'Allemagne nazie du IIIe Reich, lancée le 22 juin 1941 — c'est la plus grande offensive militaire terrestre de l'histoire, avec 3,8 millions de soldats de l'Axe engagés sur le front Est.",
    'option_c':
        "L'opération Barbarossa désigne l'invasion de la France par l'Allemagne du IIIe Reich en mai-juin 1940, souvent confondue avec la campagne de l'Est.",
    'option_d':
        "L'opération Barbarossa est le nom de code de l'invasion de l'URSS par l'Allemagne du IIe Reich, commencée en 1914 lors de la Première Guerre mondiale.",
    'bonne_reponse': 'B',
    'explication':
        "L'opération Barbarossa est l'invasion de l'URSS par l'Allemagne nazie du IIIe Reich, lancée le 22 juin 1941. Avec 3,8 millions de soldats de l'Axe, c'est la plus grande offensive militaire terrestre de l'histoire.",
    'matiere': 'Histoire-Géographie',
    'categorie': 'Seconde Guerre mondiale',
  },

  // ─────────────────────────────────────────────────────────────
  // Q16
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q16',
    'numero': 16,
    'enonce':
        "Sur un urne contenant cinq boules vertes numérotées 1 à 5, trois boules rouges numérotées 1 à 3 et deux boules blanches numérotées 1 et 2, on tire une boule au hasard. Un candidat calcule la probabilité d'obtenir un numéro pair et obtient 0,5. Un autre obtient 0,4. Lequel a raison et pourquoi ?",
    'option_a':
        "Le premier (0,5) : il y a 5 numéros pairs (2, 4 en vert ; 2 en rouge ; 2 en blanc ; et 4 en vert encore) sur 10 boules.",
    'option_b':
        "Le second (0,4) : les boules portant un numéro pair sont exactement 4 (2-vert, 4-vert, 2-rouge, 2-blanc) sur 10 boules au total, soit une probabilité de 4/10 = 0,4.",
    'option_c':
        "Le premier (0,5) : on ne compte pas par boule mais par numéro, et il y a 5 numéros distincts pairs (2, 4, 6, 8, 10) sur 10 possibles.",
    'option_d':
        "Aucun des deux n'a raison : la probabilité correcte est 3/10 = 0,3, car seules les boules rouges paires comptent dans ce type de tirage.",
    'bonne_reponse': 'B',
    'explication':
        "Boules paires : 2-vert, 4-vert, 2-rouge, 2-blanc = 4 boules paires sur 10. P = 4/10 = 0,4.",
    'matiere': 'Mathématiques',
    'categorie': 'Probabilités',
  },

  // ─────────────────────────────────────────────────────────────
  // Q17
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q17',
    'numero': 17,
    'enonce':
        "Pour l'équation 15x² − 12x + 24 = 20x + 7, un candidat vérifie si x = 1 est solution sans résoudre l'équation. Il obtient 27 = 27 et conclut que x = 1 est bien solution. Un second vérifie x = 0 et conclut qu'il n'est pas solution. Quel raisonnement est correct ?",
    'option_a':
        "Les deux sont corrects dans leurs démarches : x = 1 est solution, x = 0 ne l'est pas.",
    'option_b':
        "Le premier fait une erreur de substitution : en remplaçant x = 1, on obtient 15 − 12 + 24 = 27 à gauche et 20 + 7 = 27 à droite, donc 27 = 27 — x = 1 est bien solution. Pour x = 0 : 24 ≠ 7, donc x = 0 n'est pas solution. Les deux candidats ont raison.",
    'option_c':
        "Le premier a tort : 15(1)² − 12(1) + 24 = 27, mais 20(1) + 7 = 27 — l'égalité est vérifiée, donc x = 1 est solution, mais le second a aussi tort car x = 0 est en réalité une solution approchée.",
    'option_d':
        "Seul x = 2 est la solution de cette équation ; ni x = 0 ni x = 1 ne vérifient l'équation.",
    'bonne_reponse': 'B',
    'explication':
        "Pour x = 1 : 15 − 12 + 24 = 27 et 20 + 7 = 27 ✓. Pour x = 0 : 24 ≠ 7 ✗. Les deux candidats ont raison dans leurs démarches respectives.",
    'matiere': 'Mathématiques',
    'categorie': 'Algèbre',
  },

  // ─────────────────────────────────────────────────────────────
  // Q18
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q18',
    'numero': 18,
    'enonce':
        "La conception libérale classique (économistes du XIXe siècle) s'oppose à la conception keynésienne du rôle de l'État. Un candidat associe l'État gendarme aux keynésiens. Quelle mise au point s'impose ?",
    'option_a':
        "Le candidat a partiellement raison : Keynes défend à la fois l'État gendarme et l'État régulateur selon les cycles économiques.",
    'option_b':
        "Le candidat confond les deux doctrines : l'État gendarme est la conception libérale classique (Adam Smith, Ricardo), qui limite l'État à ses fonctions régaliennes (sécurité, justice, défense). Keynes, lui, défend l'État providence ou l'État interventionniste, qui stimule la demande par la dépense publique en période de récession.",
    'option_c':
        "Le candidat a raison pour le libéralisme, mais Keynes défend l'État totalitaire comme seul remède aux crises capitalistes.",
    'option_d':
        "Les deux conceptions sont identiques : libéraux et keynésiens s'accordent sur un État minimal dans ses fonctions économiques.",
    'bonne_reponse': 'B',
    'explication':
        "Libéralisme classique = État gendarme (fonctions régaliennes minimales). Keynésianisme = État interventionniste / État providence.",
    'matiere': 'Économie',
    'categorie': 'Doctrines économiques',
  },

  // ─────────────────────────────────────────────────────────────
  // Q19
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q19',
    'numero': 19,
    'enonce':
        "En matière de procédure judiciaire, une « question préjudicielle » est fréquemment confondue avec une « question préliminaire ». Quelle définition est juridiquement exacte ?",
    'option_a':
        "Une question préjudicielle est une question qui, par définition, cause un préjudice à l'une des parties avant même que le procès ne commence.",
    'option_b':
        "Une question préjudicielle est une question de droit dont la résolution conditionne le jugement principal — elle doit être tranchée en premier, parfois par une autre juridiction, avant que le juge saisi puisse statuer au fond.",
    'option_c':
        "Une question préjudicielle est une question soulevée par le juge lui-même lorsqu'il soupçonne une partie d'avoir des préjugés.",
    'option_d':
        "Une question préjudicielle est uniquement utilisée en droit international pour renvoyer une affaire devant la Cour internationale de Justice avant tout jugement national.",
    'bonne_reponse': 'B',
    'explication':
        "La question préjudicielle est une question de droit qui doit être résolue avant que le juge principal ne puisse statuer au fond.",
    'matiere': 'Droit',
    'categorie': 'Procédure judiciaire',
  },

  // ─────────────────────────────────────────────────────────────
  // Q20
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q20',
    'numero': 20,
    'enonce':
        "La ville de Charm el-Cheikh est une destination diplomatique importante, ayant accueilli plusieurs sommets internationaux dont la COP27 (2022). Un candidat indique qu'elle se trouve en Algérie. Quelle correction géographique complète s'impose ?",
    'option_a':
        "Charm el-Cheikh se trouve au Maroc, sur la côte atlantique, et non en Algérie comme l'indique le candidat.",
    'option_b':
        "Charm el-Cheikh se trouve en Égypte, au bout de la péninsule du Sinaï, sur la mer Rouge. C'est une erreur fréquente de la confondre avec Alger ou Tunis.",
    'option_c':
        "Charm el-Cheikh se trouve en Tunisie, sur le golfe de Gabès — le candidat a confondu avec une ville algérienne homonyme.",
    'option_d':
        "Charm el-Cheikh se trouve en Arabie Saoudite, non loin de La Mecque, ce qui explique sa vocation diplomatique internationale.",
    'bonne_reponse': 'B',
    'explication':
        "Charm el-Cheikh est une station balnéaire et diplomatique égyptienne, située à la pointe sud de la péninsule du Sinaï, sur la mer Rouge / golfe d'Aqaba. Elle a accueilli la COP27 (2022).",
    'matiere': 'Histoire-Géographie',
    'categorie': 'Géographie mondiale',
  },

  // ─────────────────────────────────────────────────────────────
  // Q21
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q21',
    'numero': 21,
    'enonce':
        "« L'Étranger » d'Albert Camus est souvent résumé de façon superficielle. Un candidat dit que le thème central est « la mort ». Un autre dit « l'absurdité de la vie ». Quel éclairage philosophique départage ces interprétations ?",
    'option_a':
        "Le premier a raison : la mort de la mère de Meursault au début du roman est le thème central qui structure toute l'œuvre.",
    'option_b':
        "Les deux ont raison simultanément : Camus articule mort et absurdité de manière indissociable dans ce roman.",
    'option_c':
        "Le second a raison : « L'Étranger » illustre la philosophie de l'absurde camusienne — Meursault est un homme qui vit sans illusions, étranger aux conventions sociales, et c'est son indifférence face à l'absurdité de l'existence (et non la mort en soi) qui constitue le cœur philosophique du roman.",
    'option_d':
        "Ni l'un ni l'autre : le thème central de « L'Étranger » est la critique de la justice coloniale française en Algérie.",
    'bonne_reponse': 'C',
    'explication':
        "L'Étranger (1942) illustre la philosophie de l'absurde : Meursault est indifférent aux conventions sociales, révélant l'absurdité du monde et des attentes sociales.",
    'matiere': 'Français',
    'categorie': 'Littérature',
  },

  // ─────────────────────────────────────────────────────────────
  // Q22
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q22',
    'numero': 22,
    'enonce':
        "Le Burkina Faso est décrit comme un pays enclavé situé dans la boucle du Niger. Un candidat indique ses coordonnées géographiques : « entre les longitudes 5° Ouest et 2° Est et les latitudes 9° Nord et 15° Nord ». Un autre dit « 2° Ouest et 15° Nord ». Quelle option est correcte ?",
    'option_a':
        "Le second a raison : le Burkina Faso s'étend entre 2° Ouest et les latitudes 9° et 15° Nord.",
    'option_b':
        "Le premier a raison mais incomplet : le Burkina Faso s'étend entre les longitudes 5°30' Ouest et 2°20' Est, et les latitudes 9°20' Nord et 15°05' Nord.",
    'option_c':
        "Aucun des deux : le Burkina Faso est entre les longitudes 9° Ouest et 15° Est et les latitudes 5° Nord et 2° Sud.",
    'option_d':
        "Le premier a raison : le Burkina Faso est exactement entre 5° Ouest, 2° Est, 9° Nord et 15° Sud.",
    'bonne_reponse': 'B',
    'explication':
        "Le Burkina Faso s'étend approximativement entre les longitudes 5°20' Ouest et 2°25' Est, et les latitudes 9°20' Nord et 15°05' Nord.",
    'matiere': 'Burkina Faso',
    'categorie': 'Géographie nationale',
  },

  // ─────────────────────────────────────────────────────────────
  // Q23
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q23',
    'numero': 23,
    'enonce':
        "Un candidat affirme que la falaise de Gobnangou est un massif montagneux situé au Centre-Est du Burkina Faso. Quelle correction double s'impose sur la nature du relief et sa localisation ?",
    'option_a':
        "La falaise de Gobnangou est bien au Centre-Est, mais c'est un plateau, non une falaise ou un massif montagneux.",
    'option_b':
        "La falaise de Gobnangou est bien une falaise (pas un massif montagneux) et elle est située dans la région de l'Est (province de la Tapoa), non au Centre-Est.",
    'option_c':
        "La falaise de Gobnangou est un massif dunaire situé dans la région du Sahel, souvent confondu avec un relief de l'Est.",
    'option_d':
        "Le candidat a raison sur les deux points : la falaise de Gobnangou est bien un massif montagneux localisé dans la région du Centre-Est.",
    'bonne_reponse': 'B',
    'explication':
        "Double erreur : (1) Gobnangou est une falaise, pas un massif ; (2) elle est dans la région de l'Est (Tapoa), non au Centre-Est. Hauteur : ~343 m.",
    'matiere': 'Burkina Faso',
    'categorie': 'Relief',
  },

  // ─────────────────────────────────────────────────────────────
  // Q24
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q24',
    'numero': 24,
    'enonce':
        "Entre les recensements de 1985 et de 2006, la population du Burkina Faso a connu une évolution démographique remarquable. Un candidat affirme qu'elle a doublé. Qu'est-ce que les données officielles indiquent ?",
    'option_a':
        "La population a triplé : elle est passée d'environ 4 millions à plus de 12 millions entre 1985 et 2006.",
    'option_b':
        "La population a doublé : elle est passée d'environ 7,9 millions (1985) à environ 14,2 millions (2006), ce qui correspond approximativement à un doublement en 21 ans.",
    'option_c':
        "La population a stagné à environ 8 millions sur toute la période, en raison de l'émigration massive vers la Côte d'Ivoire.",
    'option_d':
        "La population a décuplé grâce à l'exode rural inversé et aux politiques natalistes du gouvernement Sankara.",
    'bonne_reponse': 'B',
    'explication':
        "Le recensement de 1985 donnait ~7,96 millions d'habitants, celui de 2006 ~14,02 millions. C'est un doublement en 21 ans, soit ~3% de croissance annuelle.",
    'matiere': 'Burkina Faso',
    'categorie': 'Démographie',
  },

  // ─────────────────────────────────────────────────────────────
  // Q25
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q25',
    'numero': 25,
    'enonce':
        "Le Burkina Faso a réalisé plusieurs Recensements Généraux de la Population et de l'Habitat (RGPH) depuis son indépendance. Un candidat affirme qu'il y en a eu exactement 4 jusqu'en 2017. Est-ce exact ?",
    'option_a': "Vrai : les 4 RGPH ont eu lieu en 1975, 1985, 1996 et 2006 — le 5e a été réalisé en 2019.",
    'option_b': "Faux : il y a eu 5 RGPH jusqu'en 2017, dont le dernier cette année-là.",
    'option_c':
        "Vrai, et le 4e RGPH de 2006 a révélé une population de 14,2 millions d'habitants avec un taux de croissance annuel de 3,1%.",
    'option_d': "Faux : il n'y a eu que 3 recensements officiels reconnus par l'ONU avant 2017 au Burkina Faso.",
    'bonne_reponse': 'A',
    'explication':
        "Le Burkina Faso a réalisé 4 RGPH avant 2017 : 1975, 1985, 1996 et 2006. Le 5e a été réalisé en 2019.",
    'matiere': 'Burkina Faso',
    'categorie': 'Démographie',
  },

  // ─────────────────────────────────────────────────────────────
  // Q26
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q26',
    'numero': 26,
    'enonce':
        "Le premier gouverneur de la Haute-Volta coloniale est souvent cité dans les concours burkinabè. Un candidat affirme qu'il s'agit d'Édouard Hesling. Quel complément historique est nécessaire ?",
    'option_a':
        "Faux : c'est Louis-Gustave Binger qui fut le premier gouverneur de la Haute-Volta lors de sa création en 1919.",
    'option_b':
        "Vrai : Édouard Hesling (1919-1927) fut bien le premier gouverneur de la Haute-Volta, nommé lors de la création de la colonie le 1er mars 1919. Il a notamment lancé les premières grandes politiques agricoles (coton).",
    'option_c': "Vrai, mais Hesling fut gouverneur de 1920 à 1930, pas depuis la création en 1919.",
    'option_d':
        "Faux : c'est Maurice Yaméogo qui fut le premier gouverneur de la Haute-Volta avant de devenir son premier président.",
    'bonne_reponse': 'B',
    'explication':
        "Édouard Hesling est bien le premier gouverneur de la Haute-Volta, nommé lors de la création de la colonie le 1er mars 1919. Il a notamment promu la culture du coton.",
    'matiere': 'Burkina Faso',
    'categorie': 'Histoire coloniale',
  },

  // ─────────────────────────────────────────────────────────────
  // Q27
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q27',
    'numero': 27,
    'enonce':
        "La Haute-Volta a été créée le 1er mars 1919, puis démembrée en 1932 avant d'être reconstituée. Un candidat indique l'année 1947 pour la reconstitution. Quelle précision historique s'impose ?",
    'option_a': "Faux : la Haute-Volta a été reconstituée en 1945, lors de la Conférence de Brazzaville.",
    'option_b':
        "Vrai : la Haute-Volta a été démembrée en 1932 (partagée entre la Côte d'Ivoire, le Soudan français et le Niger) puis reconstituée le 4 septembre 1947 sous la pression du député Gérard Kango Ouédraogo et de ses alliés politiques.",
    'option_c':
        "Vrai, mais la reconstitution de 1947 est due principalement à l'action de Nazi Boni et du RDA burkinabè.",
    'option_d':
        "Faux : la Haute-Volta n'a jamais été démembrée — le candidat confond avec le Soudan français.",
    'bonne_reponse': 'B',
    'explication':
        "La Haute-Volta a été démembrée en 1932 puis reconstituée le 4 septembre 1947 après une campagne politique menée notamment par des élus voltaïques.",
    'matiere': 'Burkina Faso',
    'categorie': 'Histoire coloniale',
  },

  // ─────────────────────────────────────────────────────────────
  // Q28
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q28',
    'numero': 28,
    'enonce':
        "L'espérance de vie au Burkina Faso selon le 5e RGPH (2019) est souvent citée à tort à 61,8 ans dans certains manuels. Quelle est la valeur exacte et sa déclinaison par sexe ?",
    'option_a': "61,8 ans globalement, avec 60 ans pour les hommes et 63,6 ans pour les femmes.",
    'option_b':
        "61,9 ans globalement, avec 60 ans pour les hommes et 64 ans pour les femmes — la différence entre 61,8 et 61,9 peut sembler minime mais est cruciale dans un examen de précision.",
    'option_c': "63 ans globalement, sans distinction de sexe dans les données officielles du RGPH.",
    'option_d': "58 ans globalement, avec 56 ans pour les hommes et 60 ans pour les femmes selon les données OMS 2019.",
    'bonne_reponse': 'B',
    'explication':
        "Selon le 5e RGPH (2019), l'espérance de vie au Burkina Faso est de 61,9 ans (60 ans pour les hommes, 64 ans pour les femmes).",
    'matiere': 'Burkina Faso',
    'categorie': 'Démographie',
  },

  // ─────────────────────────────────────────────────────────────
  // Q29
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q29',
    'numero': 29,
    'enonce':
        "Selon le 5e RGPH du Burkina Faso (2019), quel est le taux d'accroissement naturel annuel de la population, et quelle est la population totale recensée ?",
    'option_a': "Taux de 3,1% et population de 14 017 262 habitants.",
    'option_b':
        "Taux de 2,84% et population de 20 505 155 habitants, avec un taux d'urbanisation de 26,1%.",
    'option_c':
        "Taux de 2,94% et population de 20 505 155 habitants — les deux taux sont souvent confondus dans les concours.",
    'option_d': "Taux de 2,5% et population de 19 034 397 habitants selon le RGPH corrigé de 2021.",
    'bonne_reponse': 'C',
    'explication':
        "Le 5e RGPH (2019) dénombre 20 505 155 habitants avec un taux d'accroissement de 2,94% par an et un taux d'urbanisation de 26,1%.",
    'matiere': 'Burkina Faso',
    'categorie': 'Démographie',
  },

  // ─────────────────────────────────────────────────────────────
  // Q30
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q30',
    'numero': 30,
    'enonce':
        "La fête de la musique est une institution culturelle majeure en France et dans le monde. Un candidat attribue sa création à Jack Lang. Une autre version mentionne une double paternité institutionnelle. Quelle réponse est la plus exacte ?",
    'option_a':
        "Jack Lang l'a créée seul en tant que ministre de la Culture en 1982, sans aucune collaboration.",
    'option_b':
        "Jack Lang (ministre de la Culture) et Maurice Fleuret (directeur de la musique) en sont les initiateurs en France — la première édition officielle a eu lieu le 21 juin 1982, coïncidant avec le solstice d'été.",
    'option_c':
        "La fête de la musique a été créée par Jack Lee, musicologue américain, à l'initiative de l'UNESCO en 1975.",
    'option_d':
        "La fête de la musique est une initiative de l'OIF (Organisation Internationale de la Francophonie), reprise par Jack Lang pour la France en 1990.",
    'bonne_reponse': 'B',
    'explication':
        "La fête de la musique a été créée à l'initiative de Jack Lang (ministre de la Culture) et Maurice Fleuret (directeur de la musique et de la danse), première édition le 21 juin 1982.",
    'matiere': 'Culture Générale',
    'categorie': 'Culture & Société',
  },

  // ─────────────────────────────────────────────────────────────
  // Q31
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q31',
    'numero': 31,
    'enonce':
        "Dans une série de cinq premiers présidents africains, un candidat associe Kwamé Nkrumah au Nigeria. Un examinateur le corrige. Mais l'examinateur ajoute une question subsidiaire : quel était le nom de la colonie britannique devenue le Ghana de Nkrumah ?",
    'option_a':
        "Nkrumah est bien associé au Ghana (ex-Gold Coast britannique), indépendant depuis le 6 mars 1957 — premier pays d'Afrique subsaharienne à accéder à l'indépendance.",
    'option_b': "Nkrumah est associé au Ghana, ex-Côte de l'Or française, indépendante depuis 1960.",
    'option_c': "Nkrumah est associé au Ghana, ex-Rhodésie du Nord, indépendante en 1963.",
    'option_d':
        "Nkrumah est associé au Nigeria (ex-Nigéria britannique) — le Ghana avait pour premier président John Mahama.",
    'bonne_reponse': 'A',
    'explication':
        "Kwamé Nkrumah est le premier président du Ghana (ex-Gold Coast britannique), indépendant depuis le 6 mars 1957 — premier pays d'Afrique subsaharienne à accéder à l'indépendance.",
    'matiere': 'Histoire-Géographie',
    'categorie': 'Indépendances africaines',
  },

  // ─────────────────────────────────────────────────────────────
  // Q32
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q32',
    'numero': 32,
    'enonce':
        "Les territoires séparatistes de l'Ukraine — Donetsk et Lougansk — ont déclaré leur indépendance en 2014. Un candidat affirme que leur réunification avec la Russie a été officiellement reconnue par l'ONU. Quelle est la réalité juridique internationale ?",
    'option_a':
        "L'ONU a reconnu l'annexion de Donetsk et Lougansk par la Russie lors d'un vote du Conseil de sécurité en 2022.",
    'option_b':
        "La Russie a proclamé l'annexion de ces territoires (ainsi que de Kherson et Zaporijjia) en septembre 2022, mais cette annexion est rejetée par la grande majorité des États membres de l'ONU comme violation du droit international — l'Assemblée générale l'a condamnée à une large majorité.",
    'option_c':
        "L'ONU a organisé un référendum international qui a validé l'indépendance de Donetsk et Lougansk, mais pas leur rattachement à la Russie.",
    'option_d':
        "Ces territoires sont officiellement reconnus comme États indépendants par l'ensemble des membres permanents du Conseil de sécurité.",
    'bonne_reponse': 'B',
    'explication':
        "La Russie a annexé Donetsk, Lougansk, Kherson et Zaporijjia en septembre 2022. L'Assemblée générale de l'ONU a condamné ces annexions par 143 voix contre 5 (résolution ES-11/4).",
    'matiere': 'Actualité Internationale',
    'categorie': 'Géopolitique',
  },

  // ─────────────────────────────────────────────────────────────
  // Q33
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q33',
    'numero': 33,
    'enonce':
        "Le CILSS (Comité Inter-États de Lutte contre la Sécheresse dans le Sahel) a son siège dans une capitale d'Afrique de l'Ouest. Un candidat dit Bamako, un autre dit Ouagadougou. Qui a raison, et combien d'États membres compte cette organisation ?",
    'option_a': "Bamako a raison : le CILSS a son siège au Mali depuis 1986, avec 9 États membres.",
    'option_b':
        "Ouagadougou a raison : le CILSS, créé en 1973 après les grandes sécheresses sahéliennes, a son siège permanent à Ouagadougou et regroupe 13 États membres.",
    'option_c': "Ouagadougou a raison mais avec 8 États membres uniquement (les pays du Sahel strict).",
    'option_d':
        "Niamey a raison : le CILSS a déménagé son siège au Niger en 2000 en raison de la stabilité politique du pays.",
    'bonne_reponse': 'B',
    'explication':
        "Le CILSS a son siège à Ouagadougou, Burkina Faso. Créé en 1973 après les grandes sécheresses, il regroupe 13 États membres.",
    'matiere': 'Histoire-Géographie',
    'categorie': 'Organisations régionales',
  },

  // ─────────────────────────────────────────────────────────────
  // Q34
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q34',
    'numero': 34,
    'enonce':
        "Sao Tomé-et-Príncipe est cité comme pays lusophone ayant accédé à l'indépendance de façon pacifique. Un candidat conteste en disant que tous les pays lusophones ont eu des indépendances pacifiques. Quelle est la réalité historique ?",
    'option_a': "Le candidat a raison : tous les pays lusophones ont négocié pacifiquement leur indépendance avec le Portugal.",
    'option_b':
        "Le candidat a tort : l'Angola, le Mozambique, la Guinée-Bissau et le Cap-Vert ont connu de longues guerres de libération (guerre coloniale portugaise 1961-1974). Sao Tomé-et-Príncipe est, avec le Cap-Vert dans une certaine mesure, l'exemple d'indépendance obtenue sans conflit armé majeur après la Révolution des Œillets de 1974 au Portugal.",
    'option_c':
        "Le candidat a raison car c'est le Brésil qui a mené la seule guerre d'indépendance lusophone, pas les pays africains.",
    'option_d': "Le candidat a tort uniquement pour l'Angola — les autres pays lusophones ont eu des indépendances pacifiques.",
    'bonne_reponse': 'B',
    'explication':
        "L'Angola, le Mozambique et la Guinée-Bissau ont mené de longues guerres de libération contre le Portugal (1961-1974). Sao Tomé-et-Príncipe a accédé à l'indépendance (12 juillet 1975) sans conflit armé majeur.",
    'matiere': 'Histoire-Géographie',
    'categorie': 'Indépendances africaines',
  },

  // ─────────────────────────────────────────────────────────────
  // Q35
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q35',
    'numero': 35,
    'enonce':
        "Le barrage de Kompienga est le premier barrage hydroélectrique du Burkina Faso. Un candidat affirme qu'il a été inauguré le 4 avril 1989 et un autre qu'il s'agit du barrage de Bagré. Comment arbitrer ?",
    'option_a': "Le second a raison : Bagré est le premier barrage hydroélectrique, Kompienga est un barrage d'irrigation uniquement.",
    'option_b':
        "Le premier a raison sur les deux points : Kompienga est bien le premier barrage hydroélectrique du Burkina Faso, inauguré le 4 avril 1989. Bagré a été inauguré plus tard (1992) et est à usage mixte (hydroélectricité + irrigation).",
    'option_c': "Le premier a raison sur Kompienga mais tort sur la date : l'inauguration a eu lieu en 1991.",
    'option_d': "Les deux ont tort : le premier barrage hydroélectrique est le barrage de Ziga, inauguré en 2000.",
    'bonne_reponse': 'B',
    'explication':
        "Kompienga est le premier barrage hydroélectrique du Burkina Faso, inauguré le 4 avril 1989, avec 14 MW. Bagré (1992) est mixte (hydroélectricité + irrigation).",
    'matiere': 'Burkina Faso',
    'categorie': 'Infrastructures',
  },

  // ─────────────────────────────────────────────────────────────
  // Q36
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q36',
    'numero': 36,
    'enonce':
        "En immunologie, le groupe sanguin O se distingue des autres par la nature de ses agglutinines. Un candidat dit que le groupe O possède l'agglutinine « Anti-A et Anti-B ». Un autre dit uniquement « Anti-A ». Qui a raison ?",
    'option_a': "Le second a raison : le groupe O ne possède que l'agglutinine Anti-A, car il n'a pas d'antigène B à protéger.",
    'option_b':
        "Le premier a raison : le groupe O ne possède ni antigène A ni B sur ses hématies, ce qui entraîne la présence des deux types d'agglutinines dans le plasma — Anti-A et Anti-B — raison pour laquelle le groupe O est donneur universel mais receveur très limité.",
    'option_c': "Aucun n'a raison : le groupe O possède uniquement l'agglutinine Anti-O, propre à ce groupe.",
    'option_d': "Le premier a raison mais pour une mauvaise raison : le groupe O possède Anti-A et Anti-B car il absorbe tous les antigènes étrangers.",
    'bonne_reponse': 'B',
    'explication':
        "Le groupe O ne porte ni antigène A ni B sur ses hématies → présence des deux agglutinines (Anti-A et Anti-B) dans le plasma. D'où donneur universel, receveur limité.",
    'matiere': 'SVT',
    'categorie': 'Immunologie',
  },

  // ─────────────────────────────────────────────────────────────
  // Q37
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q37',
    'numero': 37,
    'enonce':
        "Dans la phrase « Je te le donne à toi », un candidat identifie « le » comme pronom COD et « te » comme pronom COI. Un autre inverse les deux. Qui a raison ?",
    'option_a':
        "Le premier a raison : « le » est COD (ce qu'on donne), « te » est COI (à qui on le donne), mais dans cette phrase, « à toi » est un COI emphatique redondant avec « te ».",
    'option_b': "Le second a raison : « te » est COD car il est plus proche du verbe.",
    'option_c':
        "Les deux ont tort : dans cette phrase, « le » et « te » sont tous deux des compléments d'attribution sans distinction COD/COI.",
    'option_d':
        "Le premier a raison sur « le » (COD) mais tort sur « te » : dans cette construction, « te » est un complément d'objet second, pas un COI au sens strict.",
    'bonne_reponse': 'A',
    'explication':
        "« le » = COD (donne quoi ?). « te » = COI (donne à qui ?). « à toi » est un COI tonique qui redouble « te » pour l'emphase.",
    'matiere': 'Français',
    'categorie': 'Grammaire',
  },

  // ─────────────────────────────────────────────────────────────
  // Q38
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q38',
    'numero': 38,
    'enonce':
        "Dans le champ lexical du temps, un candidat identifie « honoraire » comme l'intrus parmi : honoraire, horloge, chronologie, chronomètre. Quelle justification est la plus rigoureuse ?",
    'option_a':
        "« Honoraire » est l'intrus car il désigne une rémunération ou un titre sans exercice actif, sans rapport sémantique avec le temps — contrairement aux trois autres qui renvoient tous à la mesure ou à l'organisation du temps.",
    'option_b':
        "« Chronologie » est l'intrus car c'est une discipline historique, pas un instrument de mesure du temps comme les autres.",
    'option_c':
        "« Horloge » est l'intrus car c'est un objet concret, contrairement aux concepts abstraits que sont « chronologie » et « honoraire ».",
    'option_d': "« Chronomètre » est l'intrus car il mesure la durée, alors que les autres mesurent l'heure absolue.",
    'bonne_reponse': 'A',
    'explication':
        "Horloge, chronologie et chronomètre relèvent tous du champ lexical du temps. « Honoraire » désigne une rémunération ou un titre symbolique — sans lien avec le temps.",
    'matiere': 'Français',
    'categorie': 'Vocabulaire',
  },

  // ─────────────────────────────────────────────────────────────
  // Q39
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q39',
    'numero': 39,
    'enonce':
        "« Percepteur » et « précepteur » sont deux mots que beaucoup confondent. Un candidat les classe comme « homonymes ». Un autre dit « paronymes ». Lequel a raison, et quelle distinction lexicale les sépare ?",
    'option_a': "Le premier a raison : « percepteur » et « précepteur » sont des homonymes car ils se prononcent de façon identique à l'oral.",
    'option_b':
        "Le second a raison : ce sont des paronymes — mots de prononciation et d'orthographe proches mais de sens différents. Un percepteur est un fonctionnaire chargé de recouvrer les impôts ; un précepteur est un enseignant privé chargé de l'éducation d'un enfant à domicile.",
    'option_c': "Ce sont des synonymes : les deux termes désignent des agents de l'État chargés de collecter des ressources.",
    'option_d':
        "Ce sont des antonymes : percepteur désigne quelqu'un qui prend (impôts), précepteur quelqu'un qui donne (savoir) — opposition sémantique directe.",
    'bonne_reponse': 'B',
    'explication':
        "Ce sont des paronymes : mots proches phonétiquement et orthographiquement mais de sens différents. Percepteur = fisc ; Précepteur = éducateur privé.",
    'matiere': 'Français',
    'categorie': 'Vocabulaire',
  },

  // ─────────────────────────────────────────────────────────────
  // Q40
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q40',
    'numero': 40,
    'enonce':
        "L'étude scientifique des reins est désignée par un terme médical précis. Un manuel scolaire l'appelle « rhinologie ». Un étudiant en médecine conteste. Qui a raison, et quel terme désigne l'étude du nez ?",
    'option_a': "Le manuel a raison : la rhinologie étudie bien les reins, et la nephrologie étudie le nez.",
    'option_b':
        "L'étudiant a raison : la rhinologie étudie le nez (du grec « rhinos » = nez) ; l'étude des reins est la néphrologie (du grec « nephros » = rein). Le manuel contient une inversion grave.",
    'option_c': "L'étudiant a raison sur la rhinologie, mais l'étude des reins est l'urologie, pas la néphrologie.",
    'option_d':
        "Le manuel a raison car en français médical, rhinologie et néphrologie sont deux termes interchangeables selon les spécialités.",
    'bonne_reponse': 'B',
    'explication':
        "Rhinologie = nez (rhinos). Néphrologie = rein (nephros). Le manuel inverse les deux notions.",
    'matiere': 'SVT',
    'categorie': 'Vocabulaire médical',
  },

  // ─────────────────────────────────────────────────────────────
  // Q41
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q41',
    'numero': 41,
    'enonce':
        "La tragédie « La Tragédie du Roi Christophe » d'Aimé Césaire est souvent mal classifiée dans les genres littéraires. Un candidat dit que c'est un roman historique. Quelle classification est exacte, et sur quelle figure historique porte cette œuvre ?",
    'option_a': "C'est effectivement un roman historique centré sur Christophe Colomb et sa découverte des Amériques.",
    'option_b':
        "C'est une pièce de théâtre (drame historique) publiée en 1963, centrée sur Henri Christophe, ancien esclave devenu roi d'Haïti (1811-1820), symbole de la tension entre émancipation africaine et reproduction des structures oppressives.",
    'option_c': "C'est un recueil de poèmes épiques en hommage au roi du Congo Christophe I, allié des missionnaires portugais au XVIe siècle.",
    'option_d': "C'est un conte politique satirique classé dans la littérature de la négritude au même titre que le « Cahier d'un retour au pays natal ».",
    'bonne_reponse': 'B',
    'explication':
        "La Tragédie du Roi Christophe (1963) est une pièce de théâtre d'Aimé Césaire centrée sur Henri Christophe, ancien esclave haïtien devenu roi (1811-1820).",
    'matiere': 'Français',
    'categorie': 'Littérature',
  },

  // ─────────────────────────────────────────────────────────────
  // Q42
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q42',
    'numero': 42,
    'enonce':
        "Il existe plusieurs zones climatiques au Burkina Faso, souvent confondues entre elles. Un candidat cite 3 zones, un autre en cite 4. Quelle réponse est conforme à la classification officielle burkinabè ?",
    'option_a': "Le Burkina Faso compte 2 zones climatiques : la zone sahélienne au nord et la zone soudanienne au sud.",
    'option_b':
        "Le Burkina Faso compte 3 zones climatiques : la zone sahélienne (nord, moins de 600 mm/an), la zone nord-soudanienne (centre, 600-900 mm/an) et la zone sud-soudanienne (sud-ouest, plus de 900 mm/an).",
    'option_c': "Le Burkina Faso compte 4 zones climatiques : sahélienne, sahélo-soudanienne, soudanienne et guinéenne.",
    'option_d': "Le Burkina Faso compte 5 zones climatiques incluant une zone de transition équatoriale dans l'extrême sud-ouest.",
    'bonne_reponse': 'B',
    'explication':
        "Le Burkina Faso compte officiellement 3 zones climatiques : sahélienne (<600 mm/an), nord-soudanienne (600-900 mm/an) et sud-soudanienne (>900 mm/an).",
    'matiere': 'Burkina Faso',
    'categorie': 'Climat',
  },

  // ─────────────────────────────────────────────────────────────
  // Q43
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q43',
    'numero': 43,
    'enonce':
        "La notion de séparation des pouvoirs est attribuée à plusieurs penseurs selon les manuels. Un candidat cite John Locke comme « le premier à en avoir parlé ». Un autre conteste en faveur de Montesquieu. Comment trancher avec précision ?",
    'option_a': "Montesquieu a raison d'être cité : il est le seul théoricien de la séparation des pouvoirs, Locke n'ayant jamais abordé ce sujet.",
    'option_b':
        "Le candidat a raison : John Locke (1689, Traité du gouvernement civil) est le premier à proposer une distinction entre pouvoirs législatif et exécutif. Montesquieu (1748, De l'Esprit des lois) a ensuite théorisé la tripartition incluant le judiciaire — Locke est donc historiquement antérieur mais la formulation classique appartient à Montesquieu.",
    'option_c': "Jean-Jacques Rousseau est le vrai fondateur de la théorie de la séparation des pouvoirs dans Le Contrat Social (1762).",
    'option_d': "John Maynard Keynes est le premier à avoir formalisé la séparation des pouvoirs dans ses travaux sur la théorie de l'État.",
    'bonne_reponse': 'B',
    'explication':
        "John Locke (1689) propose le premier une bipartition (législatif/exécutif). Montesquieu (1748) formalise la tripartition classique (législatif, exécutif, judiciaire).",
    'matiere': 'Droit',
    'categorie': 'Philosophie politique',
  },

  // ─────────────────────────────────────────────────────────────
  // Q44
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q44',
    'numero': 44,
    'enonce':
        "L'expression grammaticale « beaucoup meilleur » est-elle correcte en français ? Un candidat dit qu'elle est incorrecte car « meilleur » est déjà un comparatif et ne peut être renforcé par « beaucoup ». Un autre la défend. Qui a raison ?",
    'option_a':
        "Le premier a raison : « meilleur » étant le comparatif de supériorité de « bon », le renforcer par « beaucoup » est un pléonasme inacceptable — il faut dire « bien meilleur » ou simplement « meilleur ».",
    'option_b': "Le second a raison : « beaucoup meilleur » est parfaitement correct en français courant et accepté par l'Académie française.",
    'option_c': "Les deux ont tort : la seule forme correcte est « le meilleur possible » — tout renforcement de « meilleur » est incorrect.",
    'option_d':
        "Le premier a raison pour l'oral mais tort pour l'écrit : « beaucoup meilleur » est toléré à l'écrit dans le registre journalistique.",
    'bonne_reponse': 'A',
    'explication':
        "« Meilleur » est déjà le comparatif de supériorité de « bon » — on dit « bien meilleur », pas « beaucoup meilleur ». L'Académie française déconseille cette dernière forme.",
    'matiere': 'Français',
    'categorie': 'Grammaire',
  },

  // ─────────────────────────────────────────────────────────────
  // Q45
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q45',
    'numero': 45,
    'enonce':
        "La conception judéo-chrétienne de la nature humaine est souvent décrite dans les concours de culture générale. Un candidat la qualifie d'« optimiste ». Un autre de « pessimiste ». Comment trancher philosophiquement ?",
    'option_a': "Optimiste : la tradition judéo-chrétienne considère l'homme comme fondamentalement bon, fait à l'image de Dieu, et capable de rédemption par le libre arbitre.",
    'option_b':
        "Pessimiste : la tradition judéo-chrétienne, notamment à travers le dogme du péché originel, considère l'homme comme fondamentalement marqué par la faute d'Adam, donc enclin au mal et ayant besoin de la grâce divine pour s'élever — c'est une vision pessimiste de la nature humaine, contrairement à la vision rousseauiste de la bonté naturelle.",
    'option_c': "Réaliste : la tradition judéo-chrétienne se positionne entre optimisme et pessimisme en reconnaissant à la fois la dignité et la fragilité de l'homme.",
    'option_d': "Matérialiste : la tradition judéo-chrétienne fonde sa conception de l'homme sur les besoins matériels et corporels avant les besoins spirituels.",
    'bonne_reponse': 'B',
    'explication':
        "Vision pessimiste : le dogme du péché originel implique que l'homme est enclin au mal depuis la chute. Seule la grâce divine permet l'élévation. S'oppose à la vision rousseauiste de la bonté naturelle.",
    'matiere': 'Culture Générale',
    'categorie': 'Philosophie',
  },

  // ─────────────────────────────────────────────────────────────
  // Q46
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q46',
    'numero': 46,
    'enonce':
        "Angela Merkel a reçu le prix Félix Houphouët-Boigny pour la recherche de la paix 2022. Un candidat indique qu'il lui a été remis à Abidjan. Une autre source mentionne Yamoussoukro. Quelle précision est correcte, et pour quelle raison cette distinction importe-t-elle ?",
    'option_a': "Abidjan a raison : le prix est toujours remis au siège de l'UNESCO à Paris, puis transféré symboliquement à Abidjan.",
    'option_b':
        "Yamoussoukro a raison : le prix Félix Houphouët-Boigny est remis à Yamoussoukro (capitale politique et administrative officielle de la Côte d'Ivoire), ville natale d'Houphouët-Boigny — la cérémonie a eu lieu le 8 février 2023. La distinction Abidjan/Yamoussoukro est un classique piège de concours.",
    'option_c': "Les deux villes sont équivalentes : Abidjan et Yamoussoukro sont toutes deux capitales de la Côte d'Ivoire, donc les deux réponses sont correctes.",
    'option_d': "Dakar a raison : le siège permanent du prix Houphouët-Boigny a été transféré à Dakar en 2015.",
    'bonne_reponse': 'B',
    'explication':
        "Le prix Houphouët-Boigny 2022 a été remis à Angela Merkel à Yamoussoukro le 8 février 2023. Yamoussoukro est la capitale politique officielle, ville natale d'Houphouët-Boigny.",
    'matiere': 'Actualité Internationale',
    'categorie': 'Diplomatie',
  },

  // ─────────────────────────────────────────────────────────────
  // Q47
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q47',
    'numero': 47,
    'enonce':
        "Dans l'histoire de la Haute-Volta coloniale, le 11 juillet 1960 correspond à un événement précis. Un candidat dit que c'est la « signature des accords de libération ». Quelle formulation historique est correcte ?",
    'option_a':
        "Le 11 juillet 1960 correspond à la signature des accords de coopération entre la Haute-Volta et la France (accords bilatéraux post-indépendance), souvent appelés « accords de transfert de compétences ».",
    'option_b': "Le 11 juillet 1960 correspond à la proclamation officielle de l'indépendance de la Haute-Volta, annoncée par Maurice Yaméogo depuis Ouagadougou.",
    'option_c': "Le 11 juillet 1960 est la date à laquelle la Haute-Volta a adhéré à l'ONU comme État indépendant.",
    'option_d': "Le 11 juillet 1960 est la date de la première élection présidentielle de la Haute-Volta, remportée par Maurice Yaméogo.",
    'bonne_reponse': 'A',
    'explication':
        "Le 11 juillet 1960 correspond à la signature des accords de coopération bilatéraux entre la Haute-Volta et la France. L'indépendance formelle a été proclamée le 5 août 1960.",
    'matiere': 'Burkina Faso',
    'categorie': 'Histoire',
  },

  // ─────────────────────────────────────────────────────────────
  // Q48
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q48',
    'numero': 48,
    'enonce':
        "La devise du Burkina Faso est souvent confondue avec celle d'autres pays francophones. Un candidat écrit : « La patrie ou la mort, nous vaincrons ». Un autre conteste. Quelle est la devise officielle exacte ?",
    'option_a': "« La patrie ou la mort, nous vaincrons » est bien la devise du Burkina Faso, adoptée lors de la révolution de 1983.",
    'option_b':
        "La devise officielle du Burkina Faso est « Unité – Progrès – Justice ». « La patrie ou la mort, nous vaincrons » était un slogan révolutionnaire de l'époque Sankara mais n'a jamais été constitutionnalisé comme devise nationale.",
    'option_c': "La devise officielle est « Liberté, Égalité, Fraternité » car le Burkina Faso a repris le modèle constitutionnel français.",
    'option_d': "La devise officielle est « Un peuple, un but, une foi », commune à plusieurs pays de la sous-région.",
    'bonne_reponse': 'B',
    'explication':
        "La devise officielle du Burkina Faso est « Unité – Progrès – Justice ». « La patrie ou la mort, nous vaincrons » était un slogan sankariste, jamais constitutionnalisé.",
    'matiere': 'Burkina Faso',
    'categorie': 'Symboles nationaux',
  },

  // ─────────────────────────────────────────────────────────────
  // Q49
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q49',
    'numero': 49,
    'enonce':
        "Les symboles nationaux du Burkina Faso sont définis par la Constitution. Un candidat affirme qu'ils comprennent uniquement « un emblème, un hymne et une devise ». Un autre ajoute le drapeau et le sceau. Qui est le plus précis ?",
    'option_a': "Le premier a raison : la Constitution burkinabè ne mentionne que trois symboles (emblème, hymne, devise).",
    'option_b':
        "Le second est plus complet : les symboles de la nation burkinabè incluent le drapeau, l'emblème (armoiries), l'hymne national (Ditanyè), la devise et le sceau de l'État — la Constitution en liste généralement cinq catégories.",
    'option_c': "Les deux ont tort : les symboles nationaux du Burkina Faso sont uniquement le drapeau et l'hymne national selon la Constitution de 1991.",
    'option_d': "Le premier a raison mais oublie le drapeau : emblème, hymne, devise et drapeau — soit quatre symboles, sans le sceau.",
    'bonne_reponse': 'B',
    'explication':
        "La Constitution burkinabè liste cinq symboles : drapeau, emblème (armoiries), hymne national (Ditanyè), devise (Unité-Progrès-Justice) et sceau de l'État.",
    'matiere': 'Burkina Faso',
    'categorie': 'Symboles nationaux',
  },

  // ─────────────────────────────────────────────────────────────
  // Q50
  // ─────────────────────────────────────────────────────────────
  {
    'id': 'demo_q50',
    'numero': 50,
    'enonce':
        "En logique psychotechnique, voici une série : 2 – 5 – 11 – 23 – 47 – ? Un candidat propose 94. Un autre propose 95. Lequel a raison et pourquoi ?",
    'option_a': "94 : la règle est de multiplier chaque terme par 2, donc 47 × 2 = 94.",
    'option_b':
        "95 : la règle est de multiplier chaque terme par 2 puis d'ajouter 1. Vérification : 2×2+1=5 ; 5×2+1=11 ; 11×2+1=23 ; 23×2+1=47 ; 47×2+1=95.",
    'option_c': "96 : la règle est d'ajouter successivement 3, 6, 12, 24, 48 — soit des puissances de 2.",
    'option_d': "93 : la règle est de soustraire 1 puis multiplier par 2 : (47−1)×2 = 92, ce qui donne 93 après ajustement.",
    'bonne_reponse': 'B',
    'explication':
        "Règle : chaque terme = (terme précédent × 2) + 1. Vérification : 2×2+1=5 ; 5×2+1=11 ; 11×2+1=23 ; 23×2+1=47 ; donc 47×2+1 = 95.",
    'matiere': 'Psychotechnique',
    'categorie': 'Suites logiques',
  },
];

/// Retourne une copie indépendante des 50 questions de la démo.
///
/// Cette copie est volontairement modifiable côté écran d'examen
/// (mélange éventuel, ajout de métadonnées de session, etc.) sans
/// impacter la liste constante.
List<Map<String, dynamic>> getDemoQuestions() {
  return demoQuestions
      .map((q) => Map<String, dynamic>.from(q))
      .toList(growable: true);
}
