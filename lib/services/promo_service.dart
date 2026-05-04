// ══════════════════════════════════════════════════════════════
// PROMO SERVICE — Gestion centralisée des prix et de la promo
// ══════════════════════════════════════════════════════════════
//
// Objectif : centraliser la logique d'affichage des prix dans
// toute l'application. Permet de mettre à jour les prix et la
// promo en un seul endroit.
//
// Logique :
//   • Prix promo  : 5 000 FCFA
//   • Prix barré  : 25 000 FCFA
//   • Date de fin : 15 mai 2026
//   • Avant la date de fin → afficher la promo (texte barré + nouveau prix)
//   • Après la date de fin → la promo se renouvelle automatiquement
//     pour 15 jours supplémentaires (rolling window).
//
// Utilisation dans le code :
//   final prix = PromoService.prixActuel;          // "5 000 FCFA"
//   final ancien = PromoService.ancienPrix;         // "25 000 FCFA"
//   final estPromo = PromoService.promoActive;      // true / false
//   final fin = PromoService.dateFinPromoLisible;   // "15 mai 2026"
//
// ══════════════════════════════════════════════════════════════

class PromoService {
  // Prix officiels (actuels)
  static const String prixActuel = '5 000 FCFA';
  static const int prixActuelInt = 5000;

  // Prix barré (avant promo)
  static const String ancienPrix = '25 000 FCFA';
  static const int ancienPrixInt = 25000;

  // Date initiale de fin de promo (15 mai 2026)
  static final DateTime _dateFinInitiale = DateTime(2026, 5, 15);

  // Durée de prolongation automatique (en jours) une fois la promo expirée.
  static const int _prolongationJours = 15;

  /// Retourne la date de fin de promo *effective* :
  /// • Si la date initiale n'est pas encore atteinte → on retourne la date initiale.
  /// • Sinon → on prolonge automatiquement par tranches de 15 jours
  ///   jusqu'à dépasser la date du jour.
  static DateTime get dateFinPromo {
    final now = DateTime.now();
    if (now.isBefore(_dateFinInitiale)) return _dateFinInitiale;

    // Promo expirée → on calcule combien de tranches de 15 jours
    // ont été dépassées et on en ajoute une de plus pour rester actif.
    final ecart = now.difference(_dateFinInitiale).inDays;
    final tranches = (ecart ~/ _prolongationJours) + 1;
    return _dateFinInitiale.add(Duration(days: tranches * _prolongationJours));
  }

  /// Indique si la promo est actuellement active.
  /// Étant donné le système de prolongation automatique, cette valeur
  /// reste en pratique toujours `true` — mais on garde la mécanique
  /// pour pouvoir, si besoin, désactiver la promo en mettant
  /// [_prolongationJours] à 0.
  static bool get promoActive => DateTime.now().isBefore(dateFinPromo);

  /// Date de fin de promo formatée en français lisible.
  /// Ex : "15 mai 2026"
  static String get dateFinPromoLisible {
    final d = dateFinPromo;
    const mois = [
      '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${d.day} ${mois[d.month]} ${d.year}';
  }

  /// Mention promo complète à afficher à l'utilisateur.
  /// Ex : "Promo 5 000 FCFA au lieu de 25 000 FCFA – valable jusqu'au 15 mai 2026"
  static String get mentionPromo {
    if (!promoActive) return '';
    return 'Promo $prixActuel au lieu de $ancienPrix – valable jusqu\'au $dateFinPromoLisible';
  }

  /// Mention promo courte (pour cartes / popups).
  /// Ex : "🔥 5 000 FCFA au lieu de 25 000 FCFA — Économisez 20 000 FCFA !"
  static String get mentionPromoCourte {
    if (!promoActive) return '';
    return '🔥 $prixActuel au lieu de $ancienPrix — Économisez 20 000 FCFA !';
  }

  /// Économies réalisées (texte).
  static String get economies => '20 000 FCFA';

  /// Code USSD à composer pour le paiement (montant 5000).
  static const String codeUssd = '*144*10*65467070*5000#';

  /// Code USSD encodé pour Uri.parse (le # devient %23).
  static const String codeUssdUri = '*144*10*65467070*5000%23';
}
