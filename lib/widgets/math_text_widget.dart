import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

// ══════════════════════════════════════════════════════════════════════
// MathTextWidget — Rendu intelligent texte + formules mathématiques
// Supporte : texte brut, LaTeX inline $...$ et block $$...$$
// Compatible avec tous les QCM de EF-FORT.BF
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

    final segments = _parseText(text);
    if (segments.isEmpty) {
      return Text(text, style: defaultStyle);
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      runSpacing: 4,
      children: segments.map((seg) {
        if (seg.isMath) {
          return _buildMathWidget(seg.content, defaultStyle);
        } else {
          // Texte normal
          final trimmed = seg.content.trim();
          if (trimmed.isEmpty) return const SizedBox(width: 3);
          return Text(
            seg.content,
            style: defaultStyle,
          );
        }
      }).toList(),
    );
  }

  Widget _buildMathWidget(String latex, TextStyle baseStyle) {
    try {
      return Math.tex(
        latex,
        textStyle: TextStyle(
          fontSize: mathSize,
          color: mathColor ?? baseStyle.color ?? const Color(0xFF1A1A1A),
        ),
        onErrorFallback: (err) => Text(
          latex,
          style: baseStyle.copyWith(
            color: Colors.deepOrange,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    } catch (_) {
      return Text(
        latex,
        style: baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          color: Colors.deepOrange.shade700,
        ),
      );
    }
  }

  // ── Parser : détecte $...$ (inline LaTeX) dans le texte ────────────
  List<_TextSegment> _parseText(String input) {
    if (!input.contains('\$')) {
      return [_TextSegment(content: input, isMath: false)];
    }

    final List<_TextSegment> segments = [];
    int i = 0;

    while (i < input.length) {
      // Chercher \$\$ d'abord (block math)
      if (i < input.length - 1 && input[i] == '\$' && input[i + 1] == '\$') {
        final endIdx = input.indexOf('\$\$', i + 2);
        if (endIdx != -1) {
          segments.add(_TextSegment(
            content: input.substring(i + 2, endIdx),
            isMath: true,
          ));
          i = endIdx + 2;
          continue;
        }
      }
      // Chercher \$ (inline math)
      if (input[i] == '\$') {
        final endIdx = input.indexOf('\$', i + 1);
        if (endIdx != -1) {
          segments.add(_TextSegment(
            content: input.substring(i + 1, endIdx),
            isMath: true,
          ));
          i = endIdx + 1;
          continue;
        }
      }
      // Texte normal — chercher le prochain \$
      final nextDollar = input.indexOf('\$', i);
      if (nextDollar == -1) {
        segments.add(_TextSegment(content: input.substring(i), isMath: false));
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
