// ═══════════════════════════════════════════════════════════════════════
// PDF TEXT CLEANER — Nettoyage universel pour tous les PDF EF-FORT.BF
// Version 2.0 — Gère LaTeX, Markdown, cases à cocher, symboles parasites
// ═══════════════════════════════════════════════════════════════════════

class PdfTextCleaner {
  /// Nettoie complètement un texte pour l'impression PDF.
  /// - Supprime les cases à cocher (☐ ☒ ☑)
  /// - Convertit LaTeX → vrais symboles (√ × π etc.)
  /// - Convertit Markdown → texte brut (**gras** → texte)
  /// - Supprime les délimiteurs $, {}, commandes \cmd
  /// - Supprime les caractères parasites
  static String clean(String text) {
    if (text.isEmpty) return text;
    String s = text;

    // ── 1. Supprimer les cases à cocher et symboles checkbox ──────────────
    s = s
        .replaceAll('\u2612', '')  // ☒ ballot box with X
        .replaceAll('\u2611', '')  // ☑ ballot box with check
        .replaceAll('\u2610', '')  // ☐ ballot box vide
        .replaceAll('\u2713', '')  // ✓ check mark
        .replaceAll('\u2714', '')  // ✔ heavy check mark
        .replaceAll('\u2717', '')  // ✗ ballot X
        .replaceAll('\u2718', '')  // ✘ heavy ballot X
        .replaceAll('\u25A1', '')  // □ white square
        .replaceAll('\u25A0', '')  // ■ black square
        .replaceAll('\u2B1C', '')  // ⬜ large white square
        .replaceAll('\u2B1B', ''); // ⬛ large black square

    // ── 2. Convertir Markdown → texte brut ───────────────────────────────
    // **texte gras** → texte gras
    s = s.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1) ?? '');
    // *texte italique* → texte italique
    s = s.replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m.group(1) ?? '');
    // __texte__ → texte
    s = s.replaceAllMapped(RegExp(r'__(.+?)__'), (m) => m.group(1) ?? '');
    // _texte_ → texte
    s = s.replaceAllMapped(RegExp(r'_(.+?)_'), (m) => m.group(1) ?? '');
    // # Titre → Titre (supprimer les dièses de titre Markdown)
    s = s.replaceAllMapped(RegExp(r'^#{1,6}\s+', multiLine: true), (m) => '');
    // `code` → code
    s = s.replaceAllMapped(RegExp(r'`(.+?)`'), (m) => m.group(1) ?? '');

    // ── 3. Traiter les blocs LaTeX $$..$$ d'abord ─────────────────────────
    s = s.replaceAllMapped(
      RegExp(r'\$\$([^$]+)\$\$'),
      (m) => _convertLatex(m.group(1)?.trim() ?? ''),
    );

    // ── 4. Traiter les blocs LaTeX $..$  ──────────────────────────────────
    s = s.replaceAllMapped(
      RegExp(r'\$([^$\n]{1,200})\$'),
      (m) => _convertLatex(m.group(1)?.trim() ?? ''),
    );

    // ── 5. Supprimer les $ résiduels ─────────────────────────────────────
    s = s.replaceAll(r'$', '');

    // ── 6. Convertir le LaTeX non entouré de $ ────────────────────────────
    if (s.contains(r'\')) {
      s = _convertLatex(s);
    }

    // ── 7. Supprimer les accolades résiduelles ───────────────────────────
    s = s.replaceAll('{', '').replaceAll('}', '');

    // ── 8. Supprimer les commandes LaTeX inconnues résiduelles ───────────
    s = s.replaceAllMapped(
      RegExp(r'\\[a-zA-Z]+\s*'),
      (m) => '',
    );

    // ── 9. Supprimer les backslash seuls résiduels ───────────────────────
    s = s.replaceAll(RegExp(r'\\(?![a-zA-Z])'), '');

    // ── 10. Supprimer arobase et dièse parasites ─────────────────────────
    // Garder le # s'il est suivi d'un chiffre (numérotation) ou d'un espace
    s = s.replaceAllMapped(RegExp(r'@'), (m) => '');
    // Supprimer les # isolés (pas ceux dans des nombres comme "N°1")
    s = s.replaceAllMapped(RegExp(r'(?<![Nn°])\s*#\s*(?!\d)'), (m) => ' ');

    // ── 11. Nettoyer les espaces multiples ───────────────────────────────
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    return s.isEmpty ? text : s;
  }

  /// Convertit une expression LaTeX en texte Unicode lisible
  static String _convertLatex(String latex) {
    String s = latex;

    // ── Fonctions avec accolades ────────────────────────────────────────
    // \sqrt[n]{x} → ⁿ√(x)
    s = s.replaceAllMapped(
      RegExp(r'\\sqrt\[(\d+)\]\{([^}]*)\}'),
      (m) => '${_toSuperscript(m.group(1)!)}√(${m.group(2)})',
    );
    // \sqrt{x} → √(x)
    s = s.replaceAllMapped(
      RegExp(r'\\sqrt\{([^}]*)\}'),
      (m) => '√(${m.group(1)})',
    );
    // \sqrt x → √x
    s = s.replaceAllMapped(
      RegExp(r'\\sqrt\s+(\w)'),
      (m) => '√${m.group(1)}',
    );

    // \frac{a}{b} → (a)/(b)
    s = s.replaceAllMapped(
      RegExp(r'\\[dt]?frac\{([^}]*)\}\{([^}]*)\}'),
      (m) => '(${m.group(1)})/(${m.group(2)})',
    );

    // \text{...} → texte brut
    s = s.replaceAllMapped(
      RegExp(r'\\text\{([^}]*)\}'),
      (m) => m.group(1) ?? '',
    );
    s = s.replaceAllMapped(
      RegExp(r'\\mathrm\{([^}]*)\}'),
      (m) => m.group(1) ?? '',
    );
    s = s.replaceAllMapped(
      RegExp(r'\\mathbf\{([^}]*)\}'),
      (m) => m.group(1) ?? '',
    );
    s = s.replaceAllMapped(
      RegExp(r'\\mathit\{([^}]*)\}'),
      (m) => m.group(1) ?? '',
    );

    // \overline{x} → x̄
    s = s.replaceAllMapped(
      RegExp(r'\\overline\{([^}]*)\}'),
      (m) => '${m.group(1)}̄',
    );
    // \overrightarrow{x}, \vec{x} → x⃗
    s = s.replaceAllMapped(
      RegExp(r'\\(?:overrightarrow|vec)\{([^}]*)\}'),
      (m) => '${m.group(1)}⃗',
    );
    // \hat{x} → x̂
    s = s.replaceAllMapped(
      RegExp(r'\\hat\{([^}]*)\}'),
      (m) => '${m.group(1)}̂',
    );
    // \tilde{x} → x̃
    s = s.replaceAllMapped(
      RegExp(r'\\tilde\{([^}]*)\}'),
      (m) => '${m.group(1)}̃',
    );

    // ── Puissances et indices ─────────────────────────────────────────
    // x^{n} → xⁿ
    s = s.replaceAllMapped(
      RegExp(r'(\w|\))\^\{([^}]*)\}'),
      (m) => '${m.group(1)}${_toSuperscript(m.group(2)!)}',
    );
    // x^2 → x²
    s = s.replaceAllMapped(
      RegExp(r'(\w|\))\^(\d)'),
      (m) => '${m.group(1)}${_toSuperscript(m.group(2)!)}',
    );
    // x_{n} → xₙ
    s = s.replaceAllMapped(
      RegExp(r'(\w)\_{([^}]*)\}'),
      (m) => '${m.group(1)}${_toSubscript(m.group(2)!)}',
    );
    s = s.replaceAllMapped(
      RegExp(r'(\w)\_(\w)'),
      (m) => '${m.group(1)}${_toSubscript(m.group(2)!)}',
    );

    // ── Opérateurs de comparaison ────────────────────────────────────
    s = s.replaceAll(r'\geq', '≥');
    s = s.replaceAll(r'\leq', '≤');
    s = s.replaceAll(r'\neq', '≠');
    s = s.replaceAll(r'\approx', '≈');
    s = s.replaceAll(r'\equiv', '≡');
    s = s.replaceAll(r'\sim', '~');
    s = s.replaceAll(r'\gt', '>');
    s = s.replaceAll(r'\lt', '<');

    // ── Opérateurs mathématiques ─────────────────────────────────────
    s = s.replaceAll(r'\times', '×');
    s = s.replaceAll(r'\div', '÷');
    s = s.replaceAll(r'\pm', '±');
    s = s.replaceAll(r'\mp', '∓');
    s = s.replaceAll(r'\cdot', '·');
    s = s.replaceAll(r'\cdots', '···');
    s = s.replaceAll(r'\ldots', '...');
    s = s.replaceAll(r'\infty', '∞');
    s = s.replaceAll(r'\partial', '∂');
    s = s.replaceAll(r'\nabla', '∇');
    s = s.replaceAll(r'\forall', '∀');
    s = s.replaceAll(r'\exists', '∃');
    s = s.replaceAll(r'\emptyset', '∅');

    // ── Lettres grecques ─────────────────────────────────────────────
    s = s.replaceAll(r'\alpha', 'α');
    s = s.replaceAll(r'\beta', 'β');
    s = s.replaceAll(r'\gamma', 'γ');
    s = s.replaceAll(r'\delta', 'δ');
    s = s.replaceAll(r'\epsilon', 'ε');
    s = s.replaceAll(r'\varepsilon', 'ε');
    s = s.replaceAll(r'\zeta', 'ζ');
    s = s.replaceAll(r'\eta', 'η');
    s = s.replaceAll(r'\theta', 'θ');
    s = s.replaceAll(r'\vartheta', 'ϑ');
    s = s.replaceAll(r'\iota', 'ι');
    s = s.replaceAll(r'\kappa', 'κ');
    s = s.replaceAll(r'\lambda', 'λ');
    s = s.replaceAll(r'\mu', 'μ');
    s = s.replaceAll(r'\nu', 'ν');
    s = s.replaceAll(r'\xi', 'ξ');
    s = s.replaceAll(r'\pi', 'π');
    s = s.replaceAll(r'\varpi', 'ϖ');
    s = s.replaceAll(r'\rho', 'ρ');
    s = s.replaceAll(r'\sigma', 'σ');
    s = s.replaceAll(r'\varsigma', 'ς');
    s = s.replaceAll(r'\tau', 'τ');
    s = s.replaceAll(r'\upsilon', 'υ');
    s = s.replaceAll(r'\phi', 'φ');
    s = s.replaceAll(r'\varphi', 'φ');
    s = s.replaceAll(r'\chi', 'χ');
    s = s.replaceAll(r'\psi', 'ψ');
    s = s.replaceAll(r'\omega', 'ω');
    // Majuscules
    s = s.replaceAll(r'\Gamma', 'Γ');
    s = s.replaceAll(r'\Delta', 'Δ');
    s = s.replaceAll(r'\Theta', 'Θ');
    s = s.replaceAll(r'\Lambda', 'Λ');
    s = s.replaceAll(r'\Xi', 'Ξ');
    s = s.replaceAll(r'\Pi', 'Π');
    s = s.replaceAll(r'\Sigma', 'Σ');
    s = s.replaceAll(r'\Upsilon', 'Υ');
    s = s.replaceAll(r'\Phi', 'Φ');
    s = s.replaceAll(r'\Psi', 'Ψ');
    s = s.replaceAll(r'\Omega', 'Ω');

    // ── Fonctions mathématiques ───────────────────────────────────────
    s = s.replaceAll(r'\sin', 'sin');
    s = s.replaceAll(r'\cos', 'cos');
    s = s.replaceAll(r'\tan', 'tan');
    s = s.replaceAll(r'\cot', 'cot');
    s = s.replaceAll(r'\sec', 'sec');
    s = s.replaceAll(r'\csc', 'csc');
    s = s.replaceAll(r'\arcsin', 'arcsin');
    s = s.replaceAll(r'\arccos', 'arccos');
    s = s.replaceAll(r'\arctan', 'arctan');
    s = s.replaceAll(r'\ln', 'ln');
    s = s.replaceAll(r'\log', 'log');
    s = s.replaceAll(r'\exp', 'exp');
    s = s.replaceAll(r'\lim', 'lim');
    s = s.replaceAll(r'\max', 'max');
    s = s.replaceAll(r'\min', 'min');

    // ── Sommes, intégrales ────────────────────────────────────────────
    s = s.replaceAll(r'\sum', 'Σ');
    s = s.replaceAll(r'\prod', 'Π');
    s = s.replaceAll(r'\int', '∫');

    // ── Ensembles ─────────────────────────────────────────────────────
    s = s.replaceAll(r'\mathbb{R}', 'ℝ');
    s = s.replaceAll(r'\mathbb{N}', 'ℕ');
    s = s.replaceAll(r'\mathbb{Z}', 'ℤ');
    s = s.replaceAll(r'\mathbb{Q}', 'ℚ');
    s = s.replaceAll(r'\mathbb{C}', 'ℂ');
    s = s.replaceAll(r'\in', '∈');
    s = s.replaceAll(r'\notin', '∉');
    s = s.replaceAll(r'\subset', '⊂');
    s = s.replaceAll(r'\cup', '∪');
    s = s.replaceAll(r'\cap', '∩');

    // ── Flèches ───────────────────────────────────────────────────────
    s = s.replaceAll(r'\rightarrow', '→');
    s = s.replaceAll(r'\leftarrow', '←');
    s = s.replaceAll(r'\leftrightarrow', '↔');
    s = s.replaceAll(r'\Rightarrow', '⇒');
    s = s.replaceAll(r'\Leftarrow', '⇐');
    s = s.replaceAll(r'\Leftrightarrow', '⇔');
    s = s.replaceAll(r'\to', '→');
    s = s.replaceAll(r'\longrightarrow', '→');
    s = s.replaceAll(r'\rightleftharpoons', '⇌');

    // ── Symboles divers ───────────────────────────────────────────────
    s = s.replaceAll(r'\circ', '°');
    s = s.replaceAll(r'\degree', '°');
    s = s.replaceAll(r'\bullet', '•');
    s = s.replaceAll(r'\perp', '⊥');
    s = s.replaceAll(r'\parallel', '∥');
    s = s.replaceAll(r'\angle', '∠');
    s = s.replaceAll(r'\triangle', '△');

    // ── Parenthèses \left( \right) ────────────────────────────────────
    s = s.replaceAll(r'\left(', '(');
    s = s.replaceAll(r'\right)', ')');
    s = s.replaceAll(r'\left[', '[');
    s = s.replaceAll(r'\right]', ']');
    s = s.replaceAll(r'\left{', '{');
    s = s.replaceAll(r'\right}', '}');
    s = s.replaceAll(r'\left|', '|');
    s = s.replaceAll(r'\right|', '|');
    s = s.replaceAll(r'\left', '');
    s = s.replaceAll(r'\right', '');

    // ── Supprimer commandes inconnues résiduelles ─────────────────────
    s = s.replaceAllMapped(
      RegExp(r'\\[a-zA-Z]+\s*'),
      (m) => '',
    );

    // ── Supprimer backslash orphelins ──────────────────────────────────
    s = s.replaceAll(RegExp(r'\\(?![a-zA-Z])'), '');

    return s;
  }

  // ── Convertir chiffres en exposants Unicode ──────────────────────────
  static String _toSuperscript(String s) {
    const map = {
      '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
      '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹',
      '+': '⁺', '-': '⁻', 'n': 'ⁿ', 'i': 'ⁱ', 'x': 'ˣ',
    };
    return s.split('').map((c) => map[c] ?? c).join();
  }

  // ── Convertir chiffres en indices Unicode ────────────────────────────
  static String _toSubscript(String s) {
    const map = {
      '0': '₀', '1': '₁', '2': '₂', '3': '₃', '4': '₄',
      '5': '₅', '6': '₆', '7': '₇', '8': '₈', '9': '₉',
      'n': 'ₙ', 'i': 'ᵢ', 'x': 'ₓ', 'a': 'ₐ',
    };
    return s.split('').map((c) => map[c] ?? c).join();
  }
}
