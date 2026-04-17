// ═══════════════════════════════════════════════════════════════════════
// PDF SERVICE — Génération centralisée de PDF pour EF-FORT.BF
// Style : Copie d'examen corrigée par un professeur
// Inspiré de la capture d'écran fournie par le chef
// ═══════════════════════════════════════════════════════════════════════
//
// Caractéristiques :
//  • Logo + titre EF-FORT.BF alignés à gauche
//  • Score encerclé en ROUGE à droite (distressé, style tampon)
//  • Badge mention rouge arrondi ("INSUFFISANT", "PASSABLE", "BIEN", etc.)
//  • Infos candidat (Nom, Sujet, Date) sous l'en-tête
//  • Message d'appréciation en ITALIQUE
//  • Questions style "Question N | Titre : Énoncé .... X/Y"
//  • Réponse de l'élève / Correction / Explication (labels gras)
//  • Slogan centré en bas
//  • AUCUNE case à croix, AUCUN symbole LaTeX brut
//  • Taille de police normale (12-13px corps, 14-18px titres)
//
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../utils/pdf_text_cleaner.dart';

/// Type de PDF à générer
enum PdfKind {
  /// Matière (QCM) — note sur 20
  matiere,
  /// Examen (Simulation / Examen type / Blanc) — note sur 50
  examen,
}

/// Question préparée pour le PDF
class PdfQuestion {
  final int numero;
  final String categorie;      // ex: "Fonctions Domaine de définition"
  final String enonce;         // texte de la question
  final String reponseEleve;   // "A+B" ou "Aucune" ou texte libre
  final String bonneReponse;   // "A+B" ou "C"
  final String explication;    // texte explicatif (peut être vide)
  final int points;            // points obtenus pour cette question
  final int pointsMax;         // points maximum pour cette question
  final bool correct;          // réponse correcte ou non
  final bool nonRepondu;       // l'élève n'a pas répondu
  // Options détaillées (pour afficher la bonne option avec son texte)
  final Map<String, String> options; // {'A': 'texte option A', ...}

  PdfQuestion({
    required this.numero,
    this.categorie = '',
    required this.enonce,
    this.reponseEleve = '',
    this.bonneReponse = '',
    this.explication = '',
    this.points = 0,
    this.pointsMax = 1,
    this.correct = false,
    this.nonRepondu = false,
    this.options = const {},
  });
}

/// Service principal de génération de PDF
class PdfService {
  // ─── Couleurs (inspirées de la capture) ──────────────────────────
  static final PdfColor rouge       = PdfColor.fromHex('B71C1C');  // rouge tampon
  static final PdfColor rougeLight  = PdfColor.fromHex('D32F2F');
  static final PdfColor noir        = PdfColor.fromHex('1A1A1A');
  static final PdfColor greyDark    = PdfColor.fromHex('424242');
  static final PdfColor greyMed     = PdfColor.fromHex('9E9E9E');
  static final PdfColor greyLight   = PdfColor.fromHex('BDBDBD');
  static final PdfColor greyText    = PdfColor.fromHex('616161');
  static final PdfColor greyVeryLight = PdfColor.fromHex('E0E0E0');

  /// Nettoyer le texte pour PDF (élimine LaTeX, Markdown, cases, etc.)
  static String cleanText(String text) => PdfTextCleaner.clean(text);

  // ─── Cache des polices (Unicode complet) ────────────────────────
  static pw.Font? _fontRegular;
  static pw.Font? _fontBold;
  static pw.Font? _fontItalic;
  static pw.Font? _fontBoldItalic;
  static pw.Font? _fontSansBold;

  /// Charge les polices DejaVu (supporte √ π ∞ ≥ → ≈ — etc.)
  static Future<void> _loadFonts() async {
    if (_fontRegular != null) return;
    try {
      // DejaVu Serif — style "copie d'examen"
      final regular = await rootBundle.load('assets/fonts/DejaVuSerif.ttf');
      _fontRegular = pw.Font.ttf(regular);

      final bold = await rootBundle.load('assets/fonts/DejaVuSerif-Bold.ttf');
      _fontBold = pw.Font.ttf(bold);

      final italic = await rootBundle.load('assets/fonts/DejaVuSerif-Italic.ttf');
      _fontItalic = pw.Font.ttf(italic);

      final boldItalic = await rootBundle.load('assets/fonts/DejaVuSerif-BoldItalic.ttf');
      _fontBoldItalic = pw.Font.ttf(boldItalic);

      // DejaVu Sans Bold — pour le titre "EF-FORT.BF"
      final sansBold = await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf');
      _fontSansBold = pw.Font.ttf(sansBold);
    } catch (e) {
      // En cas d'échec, rester avec Times (sans support Unicode étendu)
      _fontRegular = pw.Font.times();
      _fontBold = pw.Font.timesBold();
      _fontItalic = pw.Font.timesItalic();
      _fontBoldItalic = pw.Font.timesBoldItalic();
      _fontSansBold = pw.Font.helveticaBold();
    }
  }

  /// Charger le logo EF-FORT.BF
  static Future<pw.MemoryImage?> _loadLogo() async {
    const paths = [
      'assets/images/logo_effort.png',
      'assets/icons/logo_effort.png',
      'assets/logo/aes_logo.png',
    ];
    for (final path in paths) {
      try {
        final ByteData data = await rootBundle.load(path);
        return pw.MemoryImage(data.buffer.asUint8List());
      } catch (_) {}
    }
    return null;
  }

  // ─── Mention selon pourcentage ──────────────────────────────────
  static String _mention(int pct) {
    if (pct >= 90) return 'EXCELLENT';
    if (pct >= 80) return 'TRES BIEN';
    if (pct >= 70) return 'BIEN';
    if (pct >= 60) return 'ASSEZ BIEN';
    if (pct >= 50) return 'PASSABLE';
    if (pct >= 30) return 'INSUFFISANT';
    return 'INSUFFISANT';
  }

  /// Message d'appréciation personnalisé (inspiré de la capture)
  static String _appreciation(int pct) {
    if (pct >= 90) {
      return 'Excellent travail ! Vous maîtrisez parfaitement le sujet. Continuez sur cette excellente lancée !';
    }
    if (pct >= 80) {
      return 'Très bon travail ! Vous avez une excellente maîtrise. Encore un petit effort pour atteindre la perfection.';
    }
    if (pct >= 70) {
      return 'Bon travail ! Vous avez bien compris l\'essentiel. Consolidez les quelques points manqués.';
    }
    if (pct >= 60) {
      return 'Travail correct. Les fondamentaux sont acquis. Approfondissez les notions pour progresser davantage.';
    }
    if (pct >= 50) {
      return 'Résultat passable. Il vous faut revoir certaines notions importantes. Persévérez, vous êtes sur la bonne voie !';
    }
    return 'Des efforts supplémentaires sont nécessaires. Revoyez attentivement le cours et recommencez. Vous pouvez y arriver !';
  }

  // ═══════════════════════════════════════════════════════════════════
  // GÉNÉRATION DU PDF "COPIE D'EXAMEN CORRIGÉE"
  // ═══════════════════════════════════════════════════════════════════
  static Future<Uint8List> genererCopieCorrigee({
    required PdfKind kind,
    required String nomCandidat,
    required String sujet,           // ex: "Psychotechnique - Série 1"
    required List<PdfQuestion> questions,
    required int scoreObtenu,        // nombre de bonnes réponses
    required int scoreTotal,         // nombre total de questions
    DateTime? date,
  }) async {
    await _loadFonts();
    final pdf = pw.Document(
      title: 'EF-FORT.BF - Copie corrigée',
      author: 'EF-FORT.BF',
    );
    final logo = await _loadLogo();
    final now = date ?? DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';

    // Calcul de la note (sur 20 pour matières, sur 50 pour examens)
    final maxNote = kind == PdfKind.matiere ? 20.0 : 50.0;
    final noteSur = scoreTotal > 0 ? (scoreObtenu / scoreTotal) * maxNote : 0.0;
    final noteStr = noteSur.toStringAsFixed(1);
    final pct = scoreTotal > 0 ? (scoreObtenu / scoreTotal * 100).round() : 0;

    // Nettoyer toutes les entrées
    final sujetClean = cleanText(sujet);
    final nomClean = nomCandidat.trim().isEmpty ? 'Candidat' : nomCandidat.trim();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 40, 42, 40),
        theme: pw.ThemeData.withFont(
          // DejaVu Serif pour le support complet Unicode (√, π, ∞, ≥, →, etc.)
          base: _fontRegular!,
          bold: _fontBold!,
          italic: _fontItalic!,
          boldItalic: _fontBoldItalic!,
        ),
        build: (ctx) => [
          _buildHeader(logo, noteStr, maxNote.toInt(), _mention(pct)),
          pw.SizedBox(height: 14),
          _buildInfoCandidat(nomClean, sujetClean, dateStr),
          pw.SizedBox(height: 10),
          _buildDashedLine(),
          pw.SizedBox(height: 10),
          _buildAppreciation(_appreciation(pct)),
          pw.SizedBox(height: 18),
          ..._buildQuestionsBlocks(questions),
          pw.SizedBox(height: 10),
          _buildCorrectionFooter(),
        ],
        footer: (ctx) => _buildPageFooter(ctx),
      ),
    );

    return pdf.save();
  }

  // ─── EN-TÊTE : Logo + titre (gauche) + score circle rouge (droite) ──
  static pw.Widget _buildHeader(
    pw.MemoryImage? logo,
    String noteStr,
    int noteMax,
    String mention,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ── Logo + Titre à gauche ──
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logo != null)
                pw.Container(
                  width: 44,
                  height: 44,
                  decoration: pw.BoxDecoration(
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: greyVeryLight, width: 0.8),
                  ),
                  padding: const pw.EdgeInsets.all(3),
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
              if (logo != null) pw.SizedBox(width: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'EF-FORT.BF',
                    style: pw.TextStyle(
                      font: _fontSansBold!,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: noir,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Concours Nationaux — Burkina Faso',
                    style: pw.TextStyle(
                      fontSize: 10.5,
                      color: greyText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // ── Score encerclé rouge + badge mention à droite ──
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Cercle rouge avec note / maxNote
            pw.Container(
              width: 78,
              height: 78,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: rouge, width: 2.2),
              ),
              child: pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      noteStr,
                      style: pw.TextStyle(
                        font: _fontSansBold!,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: rouge,
                      ),
                    ),
                    pw.Container(
                      width: 28,
                      height: 1.2,
                      color: rouge,
                      margin: const pw.EdgeInsets.symmetric(vertical: 2),
                    ),
                    pw.Text(
                      '$noteMax',
                      style: pw.TextStyle(
                        fontSize: 13,
                        color: rouge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            // Badge mention rouge arrondi
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: pw.BoxDecoration(
                color: rouge,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                mention,
                style: pw.TextStyle(
                  font: _fontSansBold!,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Infos candidat (Nom, Sujet, Date) ──────────────────────────
  static pw.Widget _buildInfoCandidat(String nom, String sujet, String date) {
    pw.Widget line(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: '$label : ',
                style: pw.TextStyle(
                  fontSize: 11.5,
                  fontWeight: pw.FontWeight.bold,
                  color: greyDark,
                ),
              ),
              pw.TextSpan(
                text: value,
                style: pw.TextStyle(
                  fontSize: 11.5,
                  color: greyDark,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        line('Nom et Prénom', nom),
        line('Sujet', sujet),
        line('Date', date),
      ],
    );
  }

  // ─── Ligne pointillée (séparateur) ─────────────────────────────
  static pw.Widget _buildDashedLine() {
    return pw.Container(
      height: 1,
      child: pw.CustomPaint(
        size: const PdfPoint(800, 1),
        painter: (canvas, size) {
          canvas
            ..setStrokeColor(greyLight)
            ..setLineWidth(0.5)
            ..setLineDashPattern([2, 3]);
          canvas.drawLine(0, 0, size.x, 0);
          canvas.strokePath();
        },
      ),
    );
  }

  // ─── Message d'appréciation (italique) ─────────────────────────
  static pw.Widget _buildAppreciation(String message) {
    return pw.Text(
      message,
      style: pw.TextStyle(
        fontSize: 11.5,
        fontStyle: pw.FontStyle.italic,
        color: greyDark,
        lineSpacing: 3,
      ),
    );
  }

  // ─── Blocs de questions (style copie corrigée) ─────────────────
  static List<pw.Widget> _buildQuestionsBlocks(List<PdfQuestion> questions) {
    final widgets = <pw.Widget>[];
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      widgets.add(_buildQuestionBlock(q));
      if (i < questions.length - 1) {
        widgets.add(pw.SizedBox(height: 10));
        widgets.add(pw.Divider(color: greyVeryLight, thickness: 0.4, height: 1));
        widgets.add(pw.SizedBox(height: 10));
      }
    }
    return widgets;
  }

  static pw.Widget _buildQuestionBlock(PdfQuestion q) {
    final scoreText = '${q.points}/${q.pointsMax}';
    final scoreColor = q.correct ? greyDark : rouge;

    // Trouver la lettre gagnante pour la correction
    String correctionTexte = q.bonneReponse;
    if (q.options.isNotEmpty && q.bonneReponse.isNotEmpty) {
      // Si la bonne réponse est une lettre, afficher "A. texte de A"
      final letters = q.bonneReponse.split(RegExp(r'[+/,;\s]'))
          .map((e) => e.trim().toUpperCase())
          .where((e) => e.isNotEmpty && q.options.containsKey(e))
          .toList();
      if (letters.isNotEmpty) {
        correctionTexte = letters
            .map((l) => '$l. ${cleanText(q.options[l] ?? '')}')
            .join('  ;  ');
      }
    }

    // Traitement de la réponse de l'élève (pour afficher proprement)
    String reponseEleveTexte = q.reponseEleve.trim();
    if (reponseEleveTexte.isEmpty) {
      reponseEleveTexte = 'Aucune réponse fournie.';
    } else if (q.options.isNotEmpty) {
      final letters = reponseEleveTexte.split(RegExp(r'[+/,;\s]'))
          .map((e) => e.trim().toUpperCase())
          .where((e) => e.isNotEmpty && q.options.containsKey(e))
          .toList();
      if (letters.isNotEmpty) {
        reponseEleveTexte = letters
            .map((l) => '$l. ${cleanText(q.options[l] ?? '')}')
            .join('  ;  ');
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ── Ligne titre de question : "Question N | Catégorie : Énoncé ... score" ──
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Numéro "Question N"
            pw.Container(
              width: 80,
              padding: const pw.EdgeInsets.only(right: 8),
              child: pw.Text(
                'Question ${q.numero}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: greyDark,
                ),
              ),
            ),
            // Séparateur vertical
            pw.Container(
              width: 1,
              height: 28,
              color: greyLight,
              margin: const pw.EdgeInsets.only(right: 10),
            ),
            // Catégorie + Énoncé
            pw.Expanded(
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    if (q.categorie.isNotEmpty)
                      pw.TextSpan(
                        text: '${cleanText(q.categorie)} : ',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: greyDark,
                        ),
                      ),
                    pw.TextSpan(
                      text: cleanText(q.enonce),
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: greyDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Score à droite
            pw.SizedBox(width: 8),
            pw.Text(
              scoreText,
              style: pw.TextStyle(
                font: _fontSansBold!,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),

        // ── Réponse de l'élève ──
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          color: greyVeryLight,
          width: double.infinity,
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: 'Réponse de l\'élève : ',
                  style: pw.TextStyle(
                    fontSize: 11.5,
                    fontWeight: pw.FontWeight.bold,
                    fontStyle: pw.FontStyle.italic,
                    color: greyDark,
                  ),
                ),
                pw.TextSpan(
                  text: cleanText(reponseEleveTexte),
                  style: pw.TextStyle(
                    fontSize: 11.5,
                    color: greyDark,
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 6),

        // ── Correction (bonne réponse) ──
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 4),
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: 'Correction : ',
                  style: pw.TextStyle(
                    fontSize: 11.5,
                    fontWeight: pw.FontWeight.bold,
                    color: greyDark,
                  ),
                ),
                pw.TextSpan(
                  text: cleanText(correctionTexte.isEmpty ? 'Non disponible' : correctionTexte),
                  style: pw.TextStyle(
                    fontSize: 11.5,
                    color: greyDark,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Explication (si présente) ──
        if (q.explication.trim().isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 4),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: 'Explication : ',
                    style: pw.TextStyle(
                      fontSize: 11.5,
                      fontWeight: pw.FontWeight.bold,
                      color: greyDark,
                    ),
                  ),
                  pw.TextSpan(
                    text: cleanText(q.explication),
                    style: pw.TextStyle(
                      fontSize: 11.5,
                      color: greyDark,
                      lineSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Ligne finale "Correction : ................." ─────────────
  static pw.Widget _buildCorrectionFooter() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          'Correction : ',
          style: pw.TextStyle(
            fontSize: 11.5,
            fontWeight: pw.FontWeight.bold,
            color: greyDark,
          ),
        ),
        pw.Expanded(
          child: pw.Container(
            height: 1,
            margin: const pw.EdgeInsets.only(bottom: 3),
            child: pw.CustomPaint(
              size: const PdfPoint(800, 1),
              painter: (canvas, size) {
                canvas
                  ..setStrokeColor(greyLight)
                  ..setLineWidth(0.6)
                  ..setLineDashPattern([2, 3]);
                canvas.drawLine(0, 0, size.x, 0);
                canvas.strokePath();
              },
            ),
          ),
        ),
      ],
    );
  }

  // ─── Pied de page : slogan centré + numéro de page ─────────────
  static pw.Widget _buildPageFooter(pw.Context ctx) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        children: [
          pw.Divider(color: greyVeryLight, thickness: 0.4, height: 1),
          pw.SizedBox(height: 5),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(width: 60),
              pw.Expanded(
                child: pw.Text(
                  'Chaque effort te rapproche de ton admission',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: greyText,
                  ),
                ),
              ),
              pw.SizedBox(
                width: 60,
                child: pw.Text(
                  'Page ${ctx.pageNumber}/${ctx.pagesCount}',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: greyMed,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PDF SUJET VIERGE (sans réponses, pour s'entraîner)
  // ═══════════════════════════════════════════════════════════════════
  static Future<Uint8List> genererSujetVierge({
    required String nomCandidat,
    required String sujet,
    required List<PdfQuestion> questions,
    String duree = '2h00',
    DateTime? date,
  }) async {
    await _loadFonts();
    final pdf = pw.Document(
      title: 'EF-FORT.BF - Sujet d\'examen',
      author: 'EF-FORT.BF',
    );
    final logo = await _loadLogo();
    final now = date ?? DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';

    final sujetClean = cleanText(sujet);
    final nomClean = nomCandidat.trim().isEmpty ? 'Candidat' : nomCandidat.trim();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 40, 42, 40),
        theme: pw.ThemeData.withFont(
          base: _fontRegular!,
          bold: _fontBold!,
          italic: _fontItalic!,
          boldItalic: _fontBoldItalic!,
        ),
        build: (ctx) => [
          // En-tête simple (sans score)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logo != null) ...[
                pw.Container(
                  width: 44,
                  height: 44,
                  decoration: pw.BoxDecoration(
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: greyVeryLight, width: 0.8),
                  ),
                  padding: const pw.EdgeInsets.all(3),
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 12),
              ],
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'EF-FORT.BF',
                    style: pw.TextStyle(
                      font: _fontSansBold!,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: noir,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Concours Nationaux — Burkina Faso',
                    style: pw.TextStyle(fontSize: 10.5, color: greyText),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          _buildInfoCandidat(nomClean, sujetClean, dateStr),
          pw.SizedBox(height: 4),
          pw.Text(
            'Durée : $duree   |   ${questions.length} questions',
            style: pw.TextStyle(fontSize: 11, color: greyText),
          ),
          pw.SizedBox(height: 10),
          _buildDashedLine(),
          pw.SizedBox(height: 10),
          pw.Text(
            'Consignes : Répondez aux questions suivantes. Chaque question vaut 1 point sauf indication contraire. Aucun document ni appareil électronique autorisé.',
            style: pw.TextStyle(
              fontSize: 11,
              fontStyle: pw.FontStyle.italic,
              color: greyDark,
              lineSpacing: 3,
            ),
          ),
          pw.SizedBox(height: 18),
          ..._buildSujetViergeBlocks(questions),
        ],
        footer: (ctx) => _buildPageFooter(ctx),
      ),
    );

    return pdf.save();
  }

  static List<pw.Widget> _buildSujetViergeBlocks(List<PdfQuestion> questions) {
    final widgets = <pw.Widget>[];
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      widgets.add(_buildSujetViergeBlock(q));
      if (i < questions.length - 1) {
        widgets.add(pw.SizedBox(height: 10));
        widgets.add(pw.Divider(color: greyVeryLight, thickness: 0.4, height: 1));
        widgets.add(pw.SizedBox(height: 10));
      }
    }
    return widgets;
  }

  static pw.Widget _buildSujetViergeBlock(PdfQuestion q) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Titre question
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 80,
              padding: const pw.EdgeInsets.only(right: 8),
              child: pw.Text(
                'Question ${q.numero}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: greyDark,
                ),
              ),
            ),
            pw.Container(
              width: 1,
              height: 28,
              color: greyLight,
              margin: const pw.EdgeInsets.only(right: 10),
            ),
            pw.Expanded(
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    if (q.categorie.isNotEmpty)
                      pw.TextSpan(
                        text: '${cleanText(q.categorie)} : ',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: greyDark,
                        ),
                      ),
                    pw.TextSpan(
                      text: cleanText(q.enonce),
                      style: pw.TextStyle(fontSize: 12, color: greyDark),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              '${q.pointsMax} pt${q.pointsMax > 1 ? "s" : ""}',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: rouge,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        // Options (si présentes), sans cases à cocher
        if (q.options.isNotEmpty) ...q.options.entries.where((e) => e.value.trim().isNotEmpty).map(
          (e) => pw.Padding(
            padding: const pw.EdgeInsets.only(left: 98, top: 2, bottom: 2),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: '${e.key}. ',
                    style: pw.TextStyle(
                      fontSize: 11.5,
                      fontWeight: pw.FontWeight.bold,
                      color: greyDark,
                    ),
                  ),
                  pw.TextSpan(
                    text: cleanText(e.value),
                    style: pw.TextStyle(fontSize: 11.5, color: greyDark),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Espace pour la réponse
        pw.SizedBox(height: 8),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 98),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Réponse : ',
                style: pw.TextStyle(
                  fontSize: 11.5,
                  fontStyle: pw.FontStyle.italic,
                  color: greyDark,
                ),
              ),
              pw.Expanded(
                child: pw.Container(
                  height: 1,
                  margin: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.CustomPaint(
                    size: const PdfPoint(800, 1),
                    painter: (canvas, size) {
                      canvas
                        ..setStrokeColor(greyLight)
                        ..setLineWidth(0.6)
                        ..setLineDashPattern([2, 3]);
                      canvas.drawLine(0, 0, size.x, 0);
                      canvas.strokePath();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
