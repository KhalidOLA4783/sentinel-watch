import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/security_alert.dart';
import '../models/system_stats.dart';
import '../services/api_service.dart';
import 'alert_detail_screen.dart';
import 'blacklist_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  Timer? _timer;

  SystemStats _stats = SystemStats.empty();
  List<SecurityAlert> _alerts = [];
  bool _isLoading = true;
  String _selectedFilter = 'PENDING'; // 'PENDING', 'CRITICAL', 'ALL'

  @override
  void initState() {
    super.initState();
    _fetchData();
    // Rafraîchissement automatique toutes les 3 secondes (simulation push)
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchData(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    final newStats = await _apiService.fetchStats();
    final newAlerts = await _apiService.fetchAlerts();

    if (mounted) {
      setState(() {
        _stats = newStats;
        _alerts = newAlerts;
        _isLoading = false;
      });
    }
  }

  void _showSettingsDialog() {
    final controller = TextEditingController(text: _apiService.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Configuration API Backend', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Indiquez l\'adresse de votre API SentinelWatch :\n• 10.0.2.2:8000 pour émulateur Android\n• 127.0.0.1:8000 pour Windows/Desktop\n• 192.168.X.X:8000 pour smartphone en Wi-Fi',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFF1E293B),
                border: OutlineInputBorder(),
                hintText: 'http://10.0.2.2:8000/api/v1',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
            onPressed: () {
              _apiService.setBaseUrl(controller.text.trim());
              Navigator.pop(ctx);
              _fetchData();
            },
            child: const Text('Enregistrer', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Déconnexion', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter de la console SentinelWatch ?',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              Navigator.pop(ctx);
              _apiService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Déconnexion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeAutonomousRemediation(SecurityAlert alert) async {
    setState(() => _isLoading = true);
    final success = await _apiService.banIp(alert.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          content: Text(
            success
                ? 'Remédiation autonome : IP ${alert.sourceIp} bannie au pare-feu !'
                : 'Échec de la remédiation au pare-feu.',
          ),
        ),
      );
      _fetchData();
    }
  }

  Widget _buildAutonomousPilotCard(SecurityAlert alert) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF818CF8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'PILOTE AUTONOME DE SÉCURITÉ',
                  style: TextStyle(
                    color: Color(0xFFA5B4FC),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444)),
                ),
                child: const Text(
                  'ACTION REQUISE',
                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Menace critique active sur IP ${alert.sourceIp} (${alert.alertType}). Le pilote autonome préconise un bannissement immédiat au pare-feu Windows.',
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.gavel_rounded, size: 18),
              label: const Text(
                'VALIDER LE BANNISSEMENT IP IMMÉDIAT',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              onPressed: () => _executeAutonomousRemediation(alert),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL': return const Color(0xFFEF4444);
      case 'HIGH': return const Color(0xFFF97316);
      case 'MEDIUM': return const Color(0xFFFBBF24);
      default: return const Color(0xFF38BDF8);
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'IMPOSSIBLE_TRAVEL': return Icons.flight_takeoff_rounded;
      case 'BRUTE_FORCE': return Icons.vpn_key_rounded;
      case 'RECON_SCAN': return Icons.radar_rounded;
      case 'ML_ANOMALY': return Icons.psychology_rounded;
      default: return Icons.warning_amber_rounded;
    }
  }

  List<SecurityAlert> get _filteredAlerts {
    if (_selectedFilter == 'CRITICAL') {
      return _alerts.where((a) => a.isCritical && a.isPending).toList();
    } else if (_selectedFilter == 'PENDING') {
      return _alerts.where((a) => a.isPending).toList();
    }
    return _alerts;
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _alerts.where((a) => a.isPending).length;
    final criticalCount = _alerts.where((a) => a.isCritical && a.isPending).length;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF2563EB)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                text: 'Sentinel',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                children: [
                  TextSpan(text: 'Watch', style: TextStyle(color: Color(0xFF38BDF8))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: Color(0xFFA855F7), size: 22),
            tooltip: 'Liste Noire',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BlacklistScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF94A3B8), size: 22),
            tooltip: 'Configuration API',
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
            tooltip: 'Déconnexion',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF38BDF8),
        backgroundColor: const Color(0xFF0F172A),
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pulse Monitoring Status & Current User
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('SOC TEMPS RÉEL', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_circle_rounded, color: Color(0xFF38BDF8), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _apiService.currentUser?.username ?? 'admin',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        if (_apiService.currentUser?.organization != null && _apiService.currentUser!.organization!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• ${_apiService.currentUser!.organization}',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // KPI ROW
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Incidents Actifs',
                      '$pendingCount',
                      criticalCount > 0 ? '$criticalCount CRITIQUES' : 'Aucun critique',
                      Icons.warning_rounded,
                      const Color(0xFFEF4444),
                      isFlashing: criticalCount > 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Événements Logs',
                      '${_stats.totalLogs}',
                      '${_stats.recentActivityCount} récents',
                      Icons.storage_rounded,
                      const Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),

              // PILOTE AUTONOME DE REMÉDIATION IMMÉDIATE (Human-in-the-loop)
              if (criticalCount > 0) ...[
                const SizedBox(height: 16),
                _buildAutonomousPilotCard(_alerts.firstWhere((a) => a.isCritical && a.isPending)),
              ],

              const SizedBox(height: 20),

              // Filter Chips
              Row(
                children: [
                  _buildFilterChip('En Attente', 'PENDING'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Critiques', 'CRITICAL'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Tous', 'ALL'),
                ],
              ),

              const SizedBox(height: 16),

              // ALERTS LIST
              _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFF38BDF8))))
                  : _filteredAlerts.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(36),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF1E293B)),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 48),
                              SizedBox(height: 12),
                              Text('Tous les systèmes sont sécurisés', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              SizedBox(height: 4),
                              Text('Aucune anomalie non traitée.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredAlerts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final alert = _filteredAlerts[index];
                            final sevColor = _getSeverityColor(alert.severity);
                            final timeStr = DateFormat('HH:mm:ss').format(alert.timestamp.toLocal());

                            return GestureDetector(
                              onTap: () async {
                                final refresh = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(builder: (_) => AlertDetailScreen(alert: alert)),
                                );
                                if (refresh == true) _fetchData(silent: true);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: alert.isCritical ? sevColor.withOpacity(0.6) : const Color(0xFF1E293B),
                                    width: alert.isCritical ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(_getAlertIcon(alert.alertType), color: sevColor, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          alert.alertType,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: sevColor.withOpacity(0.18),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: sevColor.withOpacity(0.5)),
                                          ),
                                          child: Text(
                                            alert.severity,
                                            style: TextStyle(color: sevColor, fontSize: 10, fontWeight: FontWeight.w900),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      alert.description,
                                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Text('IP : ', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                                        Text(alert.sourceIp, style: const TextStyle(color: Color(0xFF38BDF8), fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11)),
                                        const Spacer(),
                                        Text(timeStr, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontFamily: 'monospace')),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF64748B), size: 12),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF1E293B)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color, {bool isFlashing = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFlashing ? color.withOpacity(0.8) : const Color(0xFF1E293B),
          width: isFlashing ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
