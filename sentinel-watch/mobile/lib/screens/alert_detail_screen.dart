import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/security_alert.dart';
import '../services/api_service.dart';

class AlertDetailScreen extends StatefulWidget {
  final SecurityAlert alert;

  const AlertDetailScreen({super.key, required this.alert});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFEF4444);
      case 'HIGH':
        return const Color(0xFFF97316);
      case 'MEDIUM':
        return const Color(0xFFFBBF24);
      default:
        return const Color(0xFF38BDF8);
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'IMPOSSIBLE_TRAVEL':
        return Icons.flight_takeoff_rounded;
      case 'BRUTE_FORCE':
        return Icons.vpn_key_rounded;
      case 'RECON_SCAN':
        return Icons.radar_rounded;
      case 'ML_ANOMALY':
        return Icons.psychology_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  Future<void> _handleBan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Confirmation d\'Urgence', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          'Bannir immédiatement l\'adresse IP ${widget.alert.sourceIp} et bloquer tout son trafic futur ?',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bannir l\'IP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final ok = await _apiService.banIp(widget.alert.id);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text('IP ${widget.alert.sourceIp} bannie avec succès !'),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFEF4444),
          content: Text('Échec de la communication avec le backend'),
        ),
      );
    }
  }

  Future<void> _handleResolve() async {
    setState(() => _isLoading = true);
    final ok = await _apiService.resolveAlert(widget.alert.id);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF10B981),
          content: Text('Incident acquitté et marqué résolu.'),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final sevColor = _getSeverityColor(alert.severity);
    final timeStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(alert.timestamp.toLocal());

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Dossier d\'Incident', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Severity Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: sevColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: sevColor.withOpacity(0.4), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: sevColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getAlertIcon(alert.alertType), color: sevColor, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert.alertType,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: sevColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      alert.severity,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Statut : ${alert.status}',
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description card
                  const Text('DÉTAILS DE L\'INCIDENT', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Text(
                      alert.description,
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14, height: 1.5),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Technical Breakdown
                  const Text('TÉLÉMÉTRIE TECHNIQUE', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Column(
                      children: [
                        _buildRow(Icons.laptop_chromebook_rounded, 'IP Source Attaquante', alert.sourceIp, isHighlighted: true),
                        const Divider(color: Color(0xFF1E293B), height: 24),
                        _buildRow(Icons.person_rounded, 'Compte Utilisateur Ciblé', alert.targetUser ?? 'Anonyme'),
                        const Divider(color: Color(0xFF1E293B), height: 24),
                        _buildRow(Icons.access_time_rounded, 'Horodatage Événement', timeStr),
                        if (alert.details != null && alert.details!.isNotEmpty) ...[
                          const Divider(color: Color(0xFF1E293B), height: 24),
                          _buildRow(Icons.analytics_outlined, 'Détails Calculés', alert.details!),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // EMERGENCY ACTIONS
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 6,
                        shadowColor: const Color(0xFFEF4444).withOpacity(0.5),
                      ),
                      onPressed: _handleBan,
                      icon: const Icon(Icons.block_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        'BANNIR CETTE IP IMMÉDIATEMENT',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF334155)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _handleResolve,
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF94A3B8), size: 18),
                      label: const Text(
                        'Acquitter / Marquer Résolu',
                        style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value, {bool isHighlighted = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: isHighlighted ? const Color(0xFF38BDF8) : Colors.white,
                  fontFamily: isHighlighted ? 'monospace' : null,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
