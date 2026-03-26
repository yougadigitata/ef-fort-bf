import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _stats = {};
  List<dynamic> _demandes = [];
  bool _loadingStats = true;
  bool _loadingDemandes = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    // Forcer le rechargement à chaque ouverture (pas de cache)
    setState(() {
      _loadingStats = true;
      _loadingDemandes = true;
    });
    
    final statsResult = await ApiService.getAdminStats();
    final demandes = await ApiService.getDemandesAbonnement();
    
    if (mounted) {
      setState(() {
        // Extraire les stats de la réponse API (peut être dans stats.stats ou stats directement)
        if (statsResult['stats'] != null) {
          _stats = statsResult['stats'] as Map<String, dynamic>;
        } else {
          _stats = statsResult;
        }
        _demandes = demandes;
        _loadingStats = false;
        _loadingDemandes = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Administration'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.red, Color(0xFF8B0000)]),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.6),
          tabs: const [
            Tab(text: 'Stats', icon: Icon(Icons.bar_chart_rounded, size: 20)),
            Tab(text: 'Demandes', icon: Icon(Icons.pending_actions_rounded, size: 20)),
            Tab(text: 'Ajouter', icon: Icon(Icons.add_circle_outline_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildDemandesTab(),
          _buildAddTab(),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    if (_loadingStats) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tableau de bord', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  'Utilisateurs',
                  '${_stats['totalUsers'] ?? _stats['total_users'] ?? 0}',
                  Icons.people_rounded,
                  AppColors.primary,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Abonnes',
                  '${_stats['abonnes'] ?? _stats['total_abonnes'] ?? 0}',
                  Icons.workspace_premium_rounded,
                  AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard(
                  'Questions',
                  '${_stats['totalQuestions'] ?? _stats['total_questions'] ?? 0}',
                  Icons.quiz_rounded,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Simulations',
                  '${_stats['totalSimulations'] ?? _stats['total_sessions'] ?? 0}',
                  Icons.timer_rounded,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard(
                  'Demandes',
                  '${_stats['demandesEnAttente'] ?? _stats['demandes_en_attente'] ?? 0}',
                  Icons.pending_rounded,
                  AppColors.red,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Actualites',
                  '${_stats['totalActualites'] ?? _stats['total_actualites'] ?? 0}',
                  Icons.newspaper_rounded,
                  Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard(
                  'Entraide',
                  '${_stats['messagesEntraide'] ?? 0}',
                  Icons.forum_rounded,
                  Colors.purple,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Taux abonnement',
                  '${(_stats['totalUsers'] ?? _stats['total_users'] ?? 1) > 0 ? (((_stats['abonnes'] ?? _stats['total_abonnes'] ?? 0) / ((_stats['totalUsers'] ?? _stats['total_users'] ?? 1) as num)) * 100).toStringAsFixed(0) : '0'}%',
                  Icons.bar_chart_rounded,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildDemandesTab() {
    if (_loadingDemandes) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_demandes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: AppColors.textLight.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('Aucune demande en attente', style: TextStyle(color: AppColors.textLight, fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _demandes.length,
        itemBuilder: (context, index) {
          final d = _demandes[index] as Map<String, dynamic>;
          final statut = (d['statut'] ?? 'EN_ATTENTE').toString();
          final isEnAttente = statut == 'EN_ATTENTE';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: isEnAttente ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                child: Icon(
                  isEnAttente ? Icons.pending_rounded : Icons.check_circle_rounded,
                  color: isEnAttente ? AppColors.secondary : AppColors.success,
                ),
              ),
              title: Text(d['nom_complet'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d['telephone'] ?? '', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                  Text('Paiement: ${d['moyen_paiement'] ?? ''}', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                  Text('Statut: $statut', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isEnAttente ? AppColors.secondary : AppColors.success)),
                ],
              ),
              trailing: isEnAttente
                  ? IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 32),
                      onPressed: () async {
                        final id = d['id']?.toString();
                        if (id == null) return;
                        final result = await ApiService.validerAbonnement(id);
                        if (result['success'] == true) {
                          _loadData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Abonnement valide !'), backgroundColor: AppColors.success),
                            );
                          }
                        }
                      },
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildAddCard(
            'Ajouter une question',
            Icons.quiz_rounded,
            AppColors.primary,
            () => _showAddQuestionDialog(),
          ),
          const SizedBox(height: 12),
          _buildAddCard(
            'Publier une actualite',
            Icons.newspaper_rounded,
            AppColors.secondary,
            () => _showAddActualiteDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark))),
            Icon(Icons.add_circle_rounded, color: color, size: 28),
          ],
        ),
      ),
    );
  }

  void _showAddQuestionDialog() {
    final matiereCtrl = TextEditingController(text: 'culture_generale');
    final questionCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    final bCtrl = TextEditingController();
    final cCtrl = TextEditingController();
    final dCtrl = TextEditingController();
    String bonneReponse = 'A';
    final expCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ajouter une question', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(controller: matiereCtrl, decoration: const InputDecoration(labelText: 'Matiere (ex: culture_generale)')),
              const SizedBox(height: 10),
              TextField(controller: questionCtrl, decoration: const InputDecoration(labelText: 'Question'), maxLines: 2),
              const SizedBox(height: 10),
              TextField(controller: aCtrl, decoration: const InputDecoration(labelText: 'Option A')),
              const SizedBox(height: 8),
              TextField(controller: bCtrl, decoration: const InputDecoration(labelText: 'Option B')),
              const SizedBox(height: 8),
              TextField(controller: cCtrl, decoration: const InputDecoration(labelText: 'Option C')),
              const SizedBox(height: 8),
              TextField(controller: dCtrl, decoration: const InputDecoration(labelText: 'Option D')),
              const SizedBox(height: 10),
              StatefulBuilder(
                builder: (ctx2, setInnerState) => DropdownButtonFormField<String>(
                  initialValue: bonneReponse,
                  decoration: const InputDecoration(labelText: 'Bonne reponse'),
                  items: ['A', 'B', 'C', 'D'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setInnerState(() => bonneReponse = v!),
                ),
              ),
              const SizedBox(height: 10),
              TextField(controller: expCtrl, decoration: const InputDecoration(labelText: 'Explication'), maxLines: 2),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await ApiService.addQuestion({
                      'matiere': matiereCtrl.text,
                      'question': questionCtrl.text,
                      'option_a': aCtrl.text,
                      'option_b': bCtrl.text,
                      'option_c': cCtrl.text,
                      'option_d': dCtrl.text,
                      'bonne_reponse': bonneReponse,
                      'explication': expCtrl.text,
                    });
                    Navigator.pop(ctx);
                    if (result['success'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Question ajoutee !'), backgroundColor: AppColors.success),
                      );
                    }
                  },
                  child: const Text('Ajouter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddActualiteDialog() {
    final titreCtrl = TextEditingController();
    final contenuCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Publier une actualite', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: titreCtrl, decoration: const InputDecoration(labelText: 'Titre')),
            const SizedBox(height: 10),
            TextField(controller: contenuCtrl, decoration: const InputDecoration(labelText: 'Contenu'), maxLines: 4),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await ApiService.addActualite({
                    'titre': titreCtrl.text,
                    'contenu': contenuCtrl.text,
                  });
                  Navigator.pop(ctx);
                  if (result['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Actualite publiee !'), backgroundColor: AppColors.success),
                    );
                  }
                },
                child: const Text('Publier'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
