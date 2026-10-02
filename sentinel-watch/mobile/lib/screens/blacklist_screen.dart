import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BlacklistScreen extends StatefulWidget {
  const BlacklistScreen({super.key});

  @override
  State<BlacklistScreen> createState() => _BlacklistScreenState();
}

class _BlacklistScreenState extends State<BlacklistScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _blacklist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlacklist();
  }

  Future<void> _loadBlacklist() async {
    setState(() => _isLoading = true);
    final list = await _apiService.fetchBlacklist();
    setState(() {
      _blacklist = list;
      _isLoading = false;
    });
  }

  Future<void> _handleUnban(String ip) async {
    final ok = await _apiService.unbanIp(ip);
    if (ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text('IP $ip débloquée'),
          ),
        );
      }
      _loadBlacklist();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Liste Noire (IPs Bannies)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : _blacklist.isEmpty
              ? const Center(
                  child: Text(
                    'Aucune adresse IP bannie.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _blacklist.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _blacklist[index];
                    final ip = item['ip_address'] ?? '0.0.0.0';
                    final reason = item['reason'] ?? '';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.block_rounded, color: Color(0xFFEF4444), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ip,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  reason,
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.lock_open_rounded, color: Color(0xFF38BDF8), size: 20),
                            tooltip: 'Débloquer',
                            onPressed: () => _handleUnban(ip),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
