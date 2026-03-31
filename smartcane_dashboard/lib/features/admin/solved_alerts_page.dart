import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';

class SolvedAlertsPage extends StatefulWidget {
  const SolvedAlertsPage({super.key});

  @override
  State<SolvedAlertsPage> createState() => _SolvedAlertsPageState();
}

class _SolvedAlertsPageState extends State<SolvedAlertsPage> {
  Map<String, dynamic> performance = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final data = await ApiService.getPerformance();
    setState(() { performance = data; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final entries = performance.entries.toList();

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Performance du Staff", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text("Suivi des alertes résolues par membre", style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 32),

          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.8,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
              ),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final data = entry.value as Map<String, dynamic>;
                final resolved = data["alerts_resolved"] ?? 0;
                final isAdmin = data["role"] == "admin";

                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primary.withOpacity(0.1),
                            child: Text(
                              (data["staff_name"] ?? "?")[0].toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data["staff_name"] ?? "", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isAdmin ? AppTheme.primary : AppTheme.helpOrange).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  data["role"]?.toString().toUpperCase() ?? "",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                    color: isAdmin ? AppTheme.primary : AppTheme.helpOrange),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text("$resolved", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.normalGreen)),
                      Text("alertes résolues", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
