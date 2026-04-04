import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_math_fork/flutter_math.dart';

// ══════════════════════════════════════════════════════════════════════
// MathTextWidget v3.0 — Rendu intelligent texte + formules LaTeX
// Supporte : texte brut, LaTeX inline $...$ et block $$...$$
// Fallback intelligent : convertit LaTeX en symboles Unicode lisibles
// Compatible TOUS SUPPORTS : Mobile (Android/iOS) + Web Flutter
// Corrections : gestion robuste des erreurs flutter_math_fork sur Web
// Compatible avec tous les QCM de EF-FORT.BF (Maths, SP, SVT, Info...)
// ══════════════════════════════════════════════════════════════════════

class MathTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final double mathSize;
  final Color? mathColor;

  const MathTextWidget({
    super.key,
    required this.text,
    this.textStyle,
    this.mathSize = 15.0,
    this.mathColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = textStyle ??
        const TextStyle(
          fontSize: 14.5,
          color: Color(0xFF1A1A1A),
          fontFamily: 'Roboto',
          height: 1.5,
        );

    final cleanedText = removeCheckboxSymbols(text);
    final segments = _parseText(cleanedText);
    if (segments.isEmpty) {
      return Text(cleanedText, style: defaultStyle);
    }

    // Si un seul segment texte, afficher directement
    if (segments.length == 1 && !segments.first.isMath) {
      return Text(segments.first.content, style: defaultStyle);
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      runSpacing: 4,
      children: segments.map((seg) {
        if (seg.isMath) {
          return _buildMathWidget(seg.content, defaultStyle);
        } else {
          final content = seg.content;
          if (content.trim().isEmpty) return const SizedBox(width: 3);
          return Text(content, style: defaultStyle);
        }
      }).toList(),
    );
  }

  Widget _buildMathWidget(String latex, TextStyle baseStyle) {
    // Nettoyer le LaTeX avant de le soumettre
    final cleanedLatex = _normalizeLatex(latex);

    // Sur le Web, utiliser directement le fallback Unicode pour plus de fiabilité
    // flutter_math_fork peut avoir des problèmes de rendu sur certains navigateurs
    if (kIsWeb) {
      final readableText = _latexToReadable(cleanedLatex);
      return _buildStyledMathText(readableText, baseStyle);
    }

    try {
      return Math.tex(
        cleanedLatex,
        textStyle: TextStyle(
          fontSize: mathSize,
          color: mathColor ?? baseStyle.color ?? const Color(0xFF1A1A1A),
        ),
        onErrorFallback: (err) {
          // Fallback : convertir LaTeX en symboles Unicode lisibles
          final readableText = _latexToReadable(cleanedLatex);
          return _buildStyledMathText(readableText, baseStyle);
        },
      );
    } catch (_) {
      final readableText = _latexToReadable(cleanedLatex);
      return _buildStyledMathText(readableText, baseStyle);
    }
  }

  Widget _buildStyledMathText(String text, TextStyle baseStyle) {
    return Text(
      text,
      style: baseStyle.copyWith(
        fontFamily: 'Roboto',
        fontStyle: FontStyle.normal,
        color: mathColor ?? baseStyle.color,
        fontWeight: baseStyle.fontWeight ?? FontWeight.w500,
      ),
    );
  }

  // ── Normaliser le LaTeX avant rendu ────────────────────────────────
  String _normalizeLatex(String latex) {
    String s = latex.trim();
    // Normaliser les espaces multiples
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    // Supprimer les espaces en début/fin des commandes communes
    s = s.replaceAll(r'\sqrt {', r'\sqrt{');
    s = s.replaceAll(r'\frac {', r'\frac{');
    s = s.replaceAll(r'\left (', r'\left(');
    s = s.replaceAll(r'\right )', r'\right)');
    return s;
  }

  // ── Convertir LaTeX en texte Unicode lisible (fallback) ────────────
  // Méthode publique pour usage externe (ex: génération PDF)
  static String latexToReadablePublic(String latex) => _latexToReadable(latex);

  // ── Supprimer les cases à croix et symboles checkbox Unicode ─────────
  // Élimine ☒ (U+2612), ☑ (U+2611), ☐ (U+2610) et caractères similaires
  static String removeCheckboxSymbols(String text) {
    return text
        .replaceAll('\u2612', '')  // ☒ checked box
        .replaceAll('\u2611', '')  // ☑ checked box
        .replaceAll('\u2610', '')  // ☐ empty box
        .replaceAll('\u2713', '')  // ✓ checkmark
        .replaceAll('\u2714', '')  // ✔ heavy checkmark
        .replaceAll('\u2717', '')  // ✗ ballot X
        .replaceAll('\u2718', '')  // ✘ heavy ballot X
        .replaceAllMapped(RegExp(r'\s{2,}'), (m) => ' ')
        .trim();
  }

  // ── Convertir LaTeX en texte Unicode lisible (fallback) ────────────
  static String _latexToReadable(String latex) {
    String s = latex.trim();
    // Supprimer les cases à croix avant tout traitement
    s = removeCheckboxSymbols(s);

    // ── Fonctions spéciales ────────────────────────────────────────
    // \sqrt{x} → √x   /   \sqrt[n]{x} → ⁿ√x
    s = s.replaceAllMapped(
      RegExp(r'\\sqrt\[(\d+)\]\{([^}]*)\}'),
      (m) => '${_toSuperscript(m.group(1)!)}√(${m.group(2)})',
    );
    s = s.replaceAllMapped(
      RegExp(r'\\sqrt\{([^}]*)\}'),
      (m) => '√(${m.group(1)})',
    );
    s = s.replaceAllMapped(
      RegExp(r'\\sqrt\s+(\w)'),
      (m) => '√${m.group(1)}',
    );

    // ── Fractions ─────────────────────────────────────────────────
    // \frac{a}{b} → a/b
    s = s.replaceAllMapped(
      RegExp(r'\\frac\{([^}]*)\}\{([^}]*)\}'),
      (m) => '(${m.group(1)})/(${m.group(2)})',
    );
    // \dfrac, \tfrac
    s = s.replaceAllMapped(
      RegExp(r'\\[dt]?frac\{([^}]*)\}\{([^}]*)\}'),
      (m) => '(${m.group(1)})/(${m.group(2)})',
    );

    // ── Puissances et indices ──────────────────────────────────────
    // x^{n} → xⁿ  /  x^2 → x²
    s = s.replaceAllMapped(
      RegExp(r'(\w|\))\^\{([^}]*)\}'),
      (m) => '${m.group(1)}${_toSuperscript(m.group(2)!)}',
    );
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

    // ── Opérateurs de comparaison ──────────────────────────────────
    s = s.replaceAll(r'\geq', '≥');
    s = s.replaceAll(r'\leq', '≤');
    s = s.replaceAll(r'\neq', '≠');
    s = s.replaceAll(r'\approx', '≈');
    s = s.replaceAll(r'\equiv', '≡');
    s = s.replaceAll(r'\sim', '~');
    s = s.replaceAll(r'\gt', '>');
    s = s.replaceAll(r'\lt', '<');
    s = s.replaceAll(r'\gg', '>>');
    s = s.replaceAll(r'\ll', '<<');

    // ── Opérateurs mathématiques ───────────────────────────────────
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

    // ── Lettres grecques minuscules ────────────────────────────────
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

    // ── Lettres grecques majuscules ────────────────────────────────
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

    // ── Fonctions mathématiques ────────────────────────────────────
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
    s = s.replaceAll(r'\sup', 'sup');
    s = s.replaceAll(r'\inf', 'inf');
    s = s.replaceAll(r'\gcd', 'pgcd');
    s = s.replaceAll(r'\deg', 'deg');
    s = s.replaceAll(r'\det', 'det');

    // ── Sommes, produits, intégrales ───────────────────────────────
    s = s.replaceAll(r'\sum', 'Σ');
    s = s.replaceAll(r'\prod', 'Π');
    s = s.replaceAll(r'\int', '∫');
    s = s.replaceAll(r'\oint', '∮');
    s = s.replaceAll(r'\iint', '∬');
    s = s.replaceAll(r'\iiint', '∭');

    // ── Ensembles ──────────────────────────────────────────────────
    s = s.replaceAll(r'\mathbb{R}', 'ℝ');
    s = s.replaceAll(r'\mathbb{N}', 'ℕ');
    s = s.replaceAll(r'\mathbb{Z}', 'ℤ');
    s = s.replaceAll(r'\mathbb{Q}', 'ℚ');
    s = s.replaceAll(r'\mathbb{C}', 'ℂ');
    s = s.replaceAll(r'\in', '∈');
    s = s.replaceAll(r'\notin', '∉');
    s = s.replaceAll(r'\subset', '⊂');
    s = s.replaceAll(r'\subseteq', '⊆');
    s = s.replaceAll(r'\supset', '⊃');
    s = s.replaceAll(r'\supseteq', '⊇');
    s = s.replaceAll(r'\cup', '∪');
    s = s.replaceAll(r'\cap', '∩');
    s = s.replaceAll(r'\setminus', '∖');
    s = s.replaceAll(r'\complement', 'ᶜ');

    // ── Flèches ────────────────────────────────────────────────────
    s = s.replaceAll(r'\rightarrow', '→');
    s = s.replaceAll(r'\leftarrow', '←');
    s = s.replaceAll(r'\leftrightarrow', '↔');
    s = s.replaceAll(r'\Rightarrow', '⇒');
    s = s.replaceAll(r'\Leftarrow', '⇐');
    s = s.replaceAll(r'\Leftrightarrow', '⇔');
    s = s.replaceAll(r'\to', '→');
    s = s.replaceAll(r'\gets', '←');

    // ── Symboles divers ────────────────────────────────────────────
    s = s.replaceAll(r'\circ', '∘');
    s = s.replaceAll(r'\bullet', '•');
    s = s.replaceAll(r'\star', '★');
    s = s.replaceAll(r'\dagger', '†');
    s = s.replaceAll(r'\ddagger', '‡');
    s = s.replaceAll(r'\|', '‖');
    s = s.replaceAll(r'\perp', '⊥');
    s = s.replaceAll(r'\parallel', '∥');
    s = s.replaceAll(r'\angle', '∠');
    s = s.replaceAll(r'\triangle', '△');

    // ── Chimie / Physique ──────────────────────────────────────────
    s = s.replaceAll(r'\rightleftharpoons', '⇌');
    s = s.replaceAll(r'\longrightarrow', '→');
    s = s.replaceAll(r'\degree', '°');
    s = s.replaceAll(r'^\circ', '°');

    // ── Supprimer les commandes \text{...} en gardant le texte ────
    s = s.replaceAllMapped(
      RegExp(r'\\text\{([^}]*)\}'),
      (m) => m.group(1)!,
    );
    s = s.replaceAllMapped(
      RegExp(r'\\mathrm\{([^}]*)\}'),
      (m) => m.group(1)!,
    );
    s = s.replaceAllMapped(
      RegExp(r'\\mathbf\{([^}]*)\}'),
      (m) => m.group(1)!,
    );
    s = s.replaceAllMapped(
      RegExp(r'\\mathit\{([^}]*)\}'),
      (m) => m.group(1)!,
    );
    s = s.replaceAllMapped(
      RegExp(r'\\overline\{([^}]*)\}'),
      (m) => '${m.group(1)}̄',
    );
    s = s.replaceAllMapped(
      RegExp(r'\\overrightarrow\{([^}]*)\}'),
      (m) => '${m.group(1)}⃗',
    );
    s = s.replaceAllMapped(
      RegExp(r'\\vec\{([^}]*)\}'),
      (m) => '${m.group(1)}⃗',
    );
    s = s.replaceAllMapped(
      RegExp(r'\\hat\{([^}]*)\}'),
      (m) => '${m.group(1)}̂',
    );
    s = s.replaceAllMapped(
      RegExp(r'\\tilde\{([^}]*)\}'),
      (m) => '${m.group(1)}̃',
    );
    s = s.replaceAllMapped(
      RegExp(r'\\bar\{([^}]*)\}'),
      (m) => '${m.group(1)}̄',
    );

    // ── Parenthèses \left( \right) ─────────────────────────────────
    s = s.replaceAll(r'\left(', '(');
    s = s.replaceAll(r'\right)', ')');
    s = s.replaceAll(r'\left[', '[');
    s = s.replaceAll(r'\right]', ']');
    s = s.replaceAll(r'\left{', '{');
    s = s.replaceAll(r'\right}', '}');
    s = s.replaceAll(r'\left|', '|');
    s = s.replaceAll(r'\right|', '|');
    s = s.replaceAll(r'\left\|', '‖');
    s = s.replaceAll(r'\right\|', '‖');

    // ── Supprimer les accolades restantes ──────────────────────────
    s = s.replaceAll('{', '').replaceAll('}', '');

    // ── Supprimer les commandes LaTeX inconnues restantes ──────────
    s = s.replaceAllMapped(
      RegExp(r'\\[a-zA-Z]+'),
      (m) => '',
    );

    // ── Nettoyer les espaces multiples ─────────────────────────────
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    return s.isEmpty ? latex : s;
  }

  // ── Convertir en exposant Unicode ─────────────────────────────────
  static String _toSuperscript(String s) {
    const Map<String, String> supMap = {
      '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
      '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹',
      '+': '⁺', '-': '⁻', '=': '⁼', '(': '⁽', ')': '⁾',
      'n': 'ⁿ', 'i': 'ⁱ', 'a': 'ᵃ', 'b': 'ᵇ', 'c': 'ᶜ',
      'd': 'ᵈ', 'e': 'ᵉ', 'f': 'ᶠ', 'g': 'ᵍ', 'h': 'ʰ',
      'j': 'ʲ', 'k': 'ᵏ', 'l': 'ˡ', 'm': 'ᵐ', 'o': 'ᵒ',
      'p': 'ᵖ', 'r': 'ʳ', 's': 'ˢ', 't': 'ᵗ', 'u': 'ᵘ',
      'v': 'ᵛ', 'w': 'ʷ', 'x': 'ˣ', 'y': 'ʸ', 'z': 'ᶻ',
    };
    return s.split('').map((c) => supMap[c] ?? c).join();
  }

  // ── Convertir en indice Unicode ───────────────────────────────────
  static String _toSubscript(String s) {
    const Map<String, String> subMap = {
      '0': '₀', '1': '₁', '2': '₂', '3': '₃', '4': '₄',
      '5': '₅', '6': '₆', '7': '₇', '8': '₈', '9': '₉',
      '+': '₊', '-': '₋', '=': '₌', '(': '₍', ')': '₎',
      'a': 'ₐ', 'e': 'ₑ', 'o': 'ₒ', 'x': 'ₓ', 'h': 'ₕ',
      'k': 'ₖ', 'l': 'ₗ', 'm': 'ₘ', 'n': 'ₙ', 'p': 'ₚ',
      's': 'ₛ', 't': 'ₜ',
    };
    return s.split('').map((c) => subMap[c] ?? c).join();
  }

  // ── Parser : détecte $...$ et $$...$$ dans le texte ───────────────
  // Détecte aussi les commandes LaTeX sans $ (ex: \times, \frac, \sqrt)
  List<_TextSegment> _parseText(String input) {
    // Si contient des commandes LaTeX communes sans $, traiter tout le texte
    final hasLatexCommands = RegExp(
      r'\\(times|frac|sqrt|div|pm|alpha|beta|gamma|delta|pi|sigma|theta|'
      r'mu|lambda|omega|epsilon|infty|sum|int|prod|leq|geq|neq|approx|'
      r'rightarrow|leftarrow|Rightarrow|Leftarrow|cdot|ldots|cdots|'
      r'overline|vec|hat|tilde|bar|text|mathrm|mathbf|sin|cos|tan|log|ln|'
      r'left|right|subset|supset|cup|cap|in|notin|forall|exists)'
    ).hasMatch(input);

    if (hasLatexCommands && !input.contains(r'$')) {
      // Convertir directement les commandes LaTeX du texte entier
      final converted = _latexToReadable(input);
      return [_TextSegment(content: converted, isMath: false)];
    }

    if (!input.contains(r'$')) {
      return [_TextSegment(content: input, isMath: false)];
    }

    final List<_TextSegment> segments = [];
    int i = 0;

    while (i < input.length) {
      // Chercher $$ d'abord (block math)
      if (i < input.length - 1 &&
          input[i] == r'$' &&
          input[i + 1] == r'$') {
        final endIdx = input.indexOf(r'$$', i + 2);
        if (endIdx != -1) {
          final content = input.substring(i + 2, endIdx).trim();
          if (content.isNotEmpty) {
            segments.add(_TextSegment(content: content, isMath: true));
          }
          i = endIdx + 2;
          continue;
        }
      }
      // Chercher $ (inline math)
      if (input[i] == r'$') {
        final endIdx = input.indexOf(r'$', i + 1);
        if (endIdx != -1) {
          final content = input.substring(i + 1, endIdx).trim();
          if (content.isNotEmpty) {
            segments.add(_TextSegment(content: content, isMath: true));
          }
          i = endIdx + 1;
          continue;
        }
      }
      // Texte normal — chercher le prochain $
      final nextDollar = input.indexOf(r'$', i);
      if (nextDollar == -1) {
        final remaining = input.substring(i);
        if (remaining.isNotEmpty) {
          segments.add(_TextSegment(content: remaining, isMath: false));
        }
        break;
      } else {
        if (nextDollar > i) {
          segments.add(_TextSegment(
            content: input.substring(i, nextDollar),
            isMath: false,
          ));
        }
        i = nextDollar;
      }
    }

    return segments.where((s) => s.content.isNotEmpty).toList();
  }
}

class _TextSegment {
  final String content;
  final bool isMath;
  const _TextSegment({required this.content, required this.isMath});
}

// ── Widget simplifié pour une ligne complète de formule ────────────
class MathLine extends StatelessWidget {
  final String latex;
  final double fontSize;
  final Color? color;
  final TextAlign textAlign;

  const MathLine({
    super.key,
    required this.latex,
    this.fontSize = 14.0,
    this.color,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return MathTextWidget(
      text: latex,
      textStyle: TextStyle(
        fontSize: fontSize,
        color: color ?? const Color(0xFF1A1A1A),
        height: 1.4,
      ),
      mathSize: fontSize + 1,
      mathColor: color,
    );
  }
}
