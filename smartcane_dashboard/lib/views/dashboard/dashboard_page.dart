import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'dart:async';

import 'dart:convert';

import '../theme.dart';
import '../../services/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  final Function(String) onNavigate;

  const DashboardPage({super.key, required this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> users = [];

  List<Map<String, dynamic>> activeRentals = [];

  List<Map<String, dynamic>> activeAlerts = [];

  List<Map<String, dynamic>> historyAlerts = [];

  List<Map<String, dynamic>> staffList = [];
  List<Map<String, dynamic>> recentActivities = [];
  Map<String, int> inventoryStatus = {
    "Smart Lite": 15,
    "Smart Pro v2": 8,
    "Smart Pro v3": 5,
  };
  bool _isLoading = true;
  late AnimationController _pulseCtrl;

  // Cached data for performance
  List<FlSpot> _sosSpots = [];
  List<FlSpot> _helpSpots = [];
  List<Map<String, dynamic>> _leaderboardData = [];
  List<Map<String, dynamic>> _buyers = [];
  List<Map<String, dynamic>> _renters = [];
  int _sosCount = 0;
  int _helpCount = 0;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,

      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _loadData();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();

    super.dispose();
  }

  Future<void> _loadData() async {
    final u = await UserService.getUsers();

    final r = await RentalService.getActiveRentals();

    final a = await AlertService.getActiveAlerts();

    final h = await AlertService.getAlertsHistory();

    final s = await StaffService.getStaffMembers();

    // Pre-calculate statistics
    final clientUsers = u.where((user) => user["role"] == "client").toList();
    final renterIds = r.map((reg) => reg["cin_utilisateur"]?.toString() ?? "").toSet();
    
    final buyers = clientUsers.where((u) => !renterIds.contains(u["cin"]?.toString() ?? "")).toList();
    final renters = clientUsers.where((u) => renterIds.contains(u["cin"]?.toString() ?? "")).toList();

    // Pre-calculate charts and leaderboard
    final sosSpots = _getChartDataForList(h, "SOS");
    final helpSpots = _getChartDataForList(h, "HELP");
    final leaderboard = _calculateLeaderboard(h, s);

    setState(() {
      users = clientUsers;
      activeRentals = r;
      activeAlerts = a;
      historyAlerts = h;
      staffList = s;
      _buyers = buyers;
      _renters = renters;
      
      _sosSpots = sosSpots;
      _helpSpots = helpSpots;
      _leaderboardData = leaderboard;
      
      _sosCount = a.where((al) => al["type"] == "SOS").length;
      _helpCount = a.where((al) => al["type"] == "HELP").length;
      
      recentActivities = h.take(15).map((alert) {
        return {
          "title": "Alerte ${alert['type']} résolue",
          "subtitle": "Par ${alert['resolved_by']} pour ${alert['user_name'] ?? alert['user_id']}",
          "time": alert['timestamp'],
          "icon": alert['type'] == 'SOS' ? Icons.notification_important_rounded : Icons.help_outline_rounded,
          "color": alert['type'] == 'SOS' ? AppTheme.sosRed : AppTheme.accent,
        };
      }).toList();

      _isLoading = false;
    });
  }

  List<FlSpot> _getChartDataForList(List<Map<String, dynamic>> data, String type) {
    final now = DateTime.now();
    final Map<int, int> countsByDay = {};
    for (int i = 0; i < 7; i++) countsByDay[i] = 0;

    for (var alert in data) {
      if (alert['type'] != type) continue;
      try {
        final date = DateTime.parse(alert['timestamp']);
        final diff = now.difference(date).inDays;
        if (diff >= 0 && diff < 7) {
          countsByDay[6 - diff] = (countsByDay[6 - diff] ?? 0) + 1;
        }
      } catch (_) {}
    }
    return countsByDay.entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
  }

  List<Map<String, dynamic>> _calculateLeaderboard(List<Map<String, dynamic>> alerts, List<Map<String, dynamic>> staff) {
    final Map<String, int> scores = {};
    for (var alert in alerts) {
      final sName = alert['resolved_by']?.toString() ?? "Inconnu";
      scores[sName] = (scores[sName] ?? 0) + 1;
    }
    final sorted = staff.map((s) => {
      "nom": s['nom'].toString(),
      "score": scores[s['nom'].toString()] ?? 0,
      "role": s['role'] ?? "Staff",
    }).toList();
    sorted.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    return sorted;
  }

  // Methods updated to use cached data
  List<FlSpot> _getChartData(String type) => type == "SOS" ? _sosSpots : _helpSpots;
  List<Map<String, dynamic>> _getLeaderboard() => _leaderboardData;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            SizedBox(
              width: 40,

              height: 40,

              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 3,
              ),
            ),

            SizedBox(height: 24),

            Text(
              "Initialisation des systèmes...",
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(40),
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            const SizedBox(height: 40),
            _buildStatCards(),
            const SizedBox(height: 40),
            RepaintBoundary(child: _buildActivitySection()),
            const SizedBox(height: 40),
            _buildInventoryAndTeamSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildChartCard()),
        const SizedBox(width: 32),
        Expanded(flex: 2, child: _buildActivityFeed()),
      ],
    );
  }

  Widget _buildChartCard() {
    return Container(
      height: 450,
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ACTIVITÉ HEBDOMADAIRE", style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          const Text("Tendances des Alertes", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 40),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.05), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        const days = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"];
                        if (v.toInt() >= 0 && v.toInt() < days.length) {
                          return Padding(padding: const EdgeInsets.only(top: 12), child: Text(days[v.toInt()], style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 11)));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _getChartData("SOS"),
                    isCurved: true,
                    color: AppTheme.sosRed,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: AppTheme.sosRed.withOpacity(0.05)),
                  ),
                  LineChartBarData(
                    spots: _getChartData("HELP"),
                    isCurved: true,
                    color: AppTheme.accent,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: AppTheme.accent.withOpacity(0.05)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chartLegend(AppTheme.sosRed, "SOS"),
              const SizedBox(width: 32),
              _chartLegend(AppTheme.accent, "HELP"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(Color color, String label) => Row(
    children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12)),
    ],
  );

  Widget _buildActivityFeed() {
    return Container(
      height: 450,
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("FLUX D'ACTIVITÉ", style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          const Text("Dernières Actions", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 32),
          Expanded(
            child: recentActivities.isEmpty 
              ? Center(child: Text("Aucune activité récente", style: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic)))
              : ListView.separated(
                  itemCount: recentActivities.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.grey.withOpacity(0.05), height: 32),
                  itemBuilder: (context, index) {
                    final act = recentActivities[index];
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: (act['color'] as Color).withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(act['icon'] as IconData, size: 16, color: act['color'] as Color),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(act['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
                              Text(act['subtitle'], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(
                          act['time'] != null ? DateFormat('HH:mm').format(DateTime.parse(act['time'])) : "--:--",
                          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryAndTeamSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildInventoryCard()),
        if (BaseService.isAdmin) ...[
          const SizedBox(width: 32),
          Expanded(child: _buildLeaderboardCard()),
        ],
      ],
    );
  }

  Widget _buildInventoryCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("STOCK ÉQUIPEMENTS", style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          const Text("Disponibilité des Cannes", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 32),
          ...inventoryStatus.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary)),
                    Text("${e.value} unités", style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: e.value / 20,
                  backgroundColor: AppTheme.primary.withOpacity(0.05),
                  color: e.value > 5 ? AppTheme.neonGreen : AppTheme.sosRed,
                  minHeight: 6,
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard() {
    final leaderboard = _getLeaderboard();
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("PERFORMANCE ÉQUIPE", style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          const Text("Agents les plus réactifs", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 32),
          ...leaderboard.take(5).map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: AppTheme.primary.withOpacity(0.1), child: Text(s['nom'][0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['nom'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      Text("${s['score']} interventions", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (s['score'] > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.neonGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(s['score'] > 10 ? "ÉLITE" : "ACTIF", style: const TextStyle(color: AppTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }


  Widget _buildPageHeader() {
    final name = BaseService.staffName ?? 'Staff';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                "Bienvenue $name — Toutes les cannes sont sous surveillance",

                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),

        _buildRefreshBtn(),
      ],
    );
  }

  Widget _buildRefreshBtn() {
    return _HoverGlowButton(
      onTap: () {
        setState(() => _isLoading = true);

        _loadData();
      },

      child: const Row(
        children: [
          Icon(Icons.refresh_rounded, color: AppTheme.primary, size: 18),

          SizedBox(width: 10),

          Text(
            "ACTUALISER LES DONNÉES",
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    final sosCnt = _sosCount;
    final helpCnt = _helpCount;
    final hasAlert = activeAlerts.isNotEmpty;

    return Row(
      children: [
        _statCard(
          icon: Icons.person_search_rounded,

          label: "Ventes Globales",

          value: _buyers.length,

          sub: "Utilisateurs propriétaires",

          color: AppTheme.primary,

          onTap: () => _showUserListModal(
            "Clients Acheteurs",
            _buyers,
            AppTheme.primary,
          ),
        ),

        const SizedBox(width: 24),

        _statCard(
          icon: Icons.key_rounded,

          label: "Locations Actives",

          value: _renters.length,

          sub: "Équipements en circulation",

          color: const Color(0xFF0EA5E9),

          onTap: () => _showUserListModal(
            "Clients Locataires",
            _renters,
            const Color(0xFF0EA5E9),
          ),
        ),

        const SizedBox(width: 24),

        _alertStatCard(sosCnt, helpCnt, hasAlert),

        const SizedBox(width: 24),

        _statCard(
          icon: Icons.supervised_user_circle_rounded,

          label: "Staff de Sécurité",

          value: staffList.length,

          sub: "Membres opérationnels",

          color: AppTheme.accent,

          onTap: () => widget.onNavigate("/staff"),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required int value,
    required String sub,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: _HoverStatCard(
        icon: icon,
        label: label,
        value: value,
        sub: sub,
        color: color,
        onTap: onTap,
      ),
    );
  }

  void _showUserListModal(
    String title,
    List<Map<String, dynamic>> userList,
    Color color,
  ) {
    showDialog(
      context: context,

      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,

        child: Container(
          width: 800,

          constraints: const BoxConstraints(maxHeight: 750),

          decoration: BoxDecoration(
            color: AppTheme.bgCard,

            borderRadius: BorderRadius.circular(28),

            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40),
            ],
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Container(
                padding: const EdgeInsets.all(32),

                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
                  ),
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),

                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: Icon(
                            Icons.group_rounded,
                            color: color,
                            size: 24,
                          ),
                        ),

                        const SizedBox(width: 20),

                        Text(
                          title.toUpperCase(),

                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    IconButton(
                      onPressed: () => Navigator.pop(ctx),

                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: userList.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(64),

                        child: Text(
                          "Aucun client enregistré dans cette catégorie.",
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,

                        padding: const EdgeInsets.all(32),

                        itemCount: userList.length,

                        separatorBuilder: (_, __) => const SizedBox(height: 16),

                        itemBuilder: (context, index) {
                          final user = userList[index];

                          return Container(
                            padding: const EdgeInsets.all(20),

                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),

                              borderRadius: BorderRadius.circular(16),

                              border: Border.all(
                                color: Colors.grey.withOpacity(0.1),
                              ),
                            ),

                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,

                                  backgroundColor: color.withOpacity(0.15),

                                  child: Text(
                                    (user["nom"]?.toString() ?? "?")[0]
                                        .toUpperCase(),

                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 20),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Text(
                                        user["nom"]?.toString() ?? "Sans nom",

                                        style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),

                                      const SizedBox(height: 2),

                                      Text(
                                        user["email"]?.toString() ??
                                            "Pas d'adresse email",

                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                AppGradientButton(
                                  onTap: () {
                                    Navigator.pop(ctx);

                                    _showUserDetails(user);
                                  },

                                  icon: Icons.arrow_forward_rounded,

                                  label: "VOIR PROFIL",

                                  color: AppTheme.primary,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    final nameCtrl = TextEditingController(text: user["nom"]?.toString() ?? "");

    final emailCtrl = TextEditingController(
      text: user["email"]?.toString() ?? "",
    );

    final phoneCtrl = TextEditingController(
      text: _normalizePhoneDigits(
        user["numero_de_telephone"]?.toString() ?? "",
      ),
    );

    final familyCtrl = TextEditingController(
      text: _normalizePhoneDigits(user["contact_familial"]?.toString() ?? ""),
    );

    final addressCtrl = TextEditingController(
      text: user["adresse"]?.toString() ?? "",
    );

    final simCtrl = TextEditingController(
      text: _normalizePhoneDigits(user["sim_de_la_canne"]?.toString() ?? ""),
    );

    Map<String, dynamic> medicalData = {};

    try {
      String rawHealth = user["etat_de_sante"]?.toString() ?? "";

      if (rawHealth.startsWith('{')) {
        medicalData = jsonDecode(rawHealth);
      } else {
        medicalData = {"observations": rawHealth};
      }
    } catch (e) {
      medicalData = {"observations": user["etat_de_sante"]?.toString() ?? ""};
    }

    final List<String> availablePathologies = [
      "Diabète",
      "Hypertension",
      "Maladie cardiaque",
      "Épilepsie",

      "Troubles de l’équilibre / Vertiges",
      "Difficulté de mobilité",

      "Baisse auditive",
      "Allergies médicamenteuses",

      "Aucune pathologie connue",
      "Autre",
    ];

    Map<String, bool> pathologies = {
      for (var p in availablePathologies)
        p: (medicalData["pathologies"] as List?)?.contains(p) ?? false,
    };

    final allergyCtrl = TextEditingController(
      text: medicalData["allergie_detail"]?.toString() ?? "",
    );

    final otherCtrl = TextEditingController(
      text: medicalData["autre_detail"]?.toString() ?? "",
    );

    final obsCtrl = TextEditingController(
      text: medicalData["observations"]?.toString() ?? "",
    );

    String bloodGroup = medicalData["groupe_sanguin"]?.toString() ?? "Inconnu";

    final List<String> bloodGroups = [
      "A+",
      "A-",
      "B+",
      "B-",
      "AB+",
      "AB-",
      "O+",
      "O-",
      "Inconnu",
    ];

    bool isEditing = false;

    showDialog(
      context: context,

      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,

          child: Container(
            width: 800,

            constraints: const BoxConstraints(maxHeight: 850),

            decoration: BoxDecoration(
              color: AppTheme.bgCard,

              borderRadius: BorderRadius.circular(32),

              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 50),
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                Container(
                  padding: const EdgeInsets.all(32),

                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),

                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),

                    border: Border(
                      bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
                    ),
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),

                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),

                            child: Icon(
                              isEditing
                                  ? Icons.edit_rounded
                                  : Icons.person_rounded,
                              color: AppTheme.primary,
                            ),
                          ),

                          const SizedBox(width: 20),

                          Text(
                            isEditing
                                ? "ÉDITION DU PROFIL"
                                : (user["nom"]?.toString() ?? "CLIENT")
                                      .toUpperCase(),

                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: AppTheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                setDialogState(() => isEditing = !isEditing),

                            icon: Icon(
                              isEditing
                                  ? Icons.close_rounded
                                  : Icons.edit_rounded,
                              color: isEditing
                                  ? AppTheme.sosRed
                                  : AppTheme.primary,
                            ),
                          ),

                          const SizedBox(width: 8),

                          IconButton(
                            onPressed: () => Navigator.pop(ctx),

                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        _fieldOrText(
                          "CIN / Identifiant",
                          user["cin"]?.toString() ?? "Non renseign",
                          null,
                          false,
                        ),

                        _fieldOrText(
                          "Nom Complet",
                          user["nom"]?.toString() ?? "Non renseign",
                          nameCtrl,
                          isEditing,
                        ),

                        _fieldOrText(
                          "Adresse Email",
                          user["email"]?.toString() ?? "Non renseign",
                          emailCtrl,
                          isEditing,
                        ),

                        _fieldOrText(
                          "Téléphone",
                          user["numero_de_telephone"]?.toString() ??
                              "Non renseign",
                          phoneCtrl,
                          isEditing,
                          isPhone: true,
                        ),

                        _fieldOrText(
                          "Contact d'urgence",
                          user["contact_familial"]?.toString() ??
                              "Non renseign",
                          familyCtrl,
                          isEditing,
                          isPhone: true,
                        ),

                        _fieldOrText(
                          "Adresse Physique",
                          user["adresse"]?.toString() ?? "Non renseign",
                          addressCtrl,
                          isEditing,
                        ),

                        _fieldOrText(
                          "Numéro SIM Canne",
                          user["sim_de_la_canne"]?.toString() ?? "Non renseign",
                          simCtrl,
                          isEditing,
                          isPhone: true,
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Divider(),
                        ),

                        const Text(
                          "DOSSIER MÉDICAL",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: AppTheme.accent,
                            letterSpacing: 1,
                          ),
                        ),

                        const SizedBox(height: 24),

                        if (!isEditing) ...[
                          _buildMedicalSummary(
                            pathologies,
                            allergyCtrl.text,
                            otherCtrl.text,
                            bloodGroup,
                            obsCtrl.text,
                          ),
                        ] else ...[
                          const Text(
                            "Pathologies diagnostiquées :",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.primary,
                            ),
                          ),

                          const SizedBox(height: 16),

                          Wrap(
                            spacing: 12,

                            runSpacing: 12,

                            children: availablePathologies
                                .map(
                                  (p) => FilterChip(
                                    label: Text(p),

                                    selected: pathologies[p]!,

                                    selectedColor: AppTheme.primary.withOpacity(
                                      0.1,
                                    ),

                                    checkmarkColor: AppTheme.primary,

                                    labelStyle: TextStyle(
                                      color: pathologies[p]!
                                          ? AppTheme.primary
                                          : const Color(0xFF64748B),
                                      fontWeight: pathologies[p]!
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),

                                    onSelected: (val) => setDialogState(() {
                                      if (p == "Aucune pathologie connue" &&
                                          val)
                                        pathologies.updateAll(
                                          (key, value) => false,
                                        );
                                      else if (val)
                                        pathologies["Aucune pathologie connue"] =
                                            false;

                                      pathologies[p] = val;
                                    }),
                                  ),
                                )
                                .toList(),
                          ),

                          if (pathologies["Allergies médicamenteuses"]!) ...[
                            const SizedBox(height: 20),

                            TextField(
                              controller: allergyCtrl,
                              decoration: AppTheme.inputDecoration(
                                "Détails des allergies",
                                Icons.warning_amber_rounded,
                              ),
                            ),
                          ],

                          if (pathologies["Autre"]!) ...[
                            const SizedBox(height: 20),

                            TextField(
                              controller: otherCtrl,
                              decoration: AppTheme.inputDecoration(
                                "Préciser l'autre pathologie",
                                Icons.add_moderator_rounded,
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          Row(
                            children: [
                              const Text(
                                "Groupe Sanguin : ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),

                              const SizedBox(width: 24),

                              DropdownButton<String>(
                                value: bloodGroup,

                                underline: const SizedBox(),

                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),

                                items: bloodGroups
                                    .map(
                                      (g) => DropdownMenuItem(
                                        value: g,
                                        child: Text(g),
                                      ),
                                    )
                                    .toList(),

                                onChanged: (val) =>
                                    setDialogState(() => bloodGroup = val!),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          TextField(
                            controller: obsCtrl,
                            maxLines: 3,
                            decoration: AppTheme.inputDecoration(
                              "Observations cliniques complémentaires",
                              Icons.notes_rounded,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                if (isEditing)
                  Container(
                    padding: const EdgeInsets.all(32),

                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),

                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(32),
                      ),

                      border: Border(
                        top: BorderSide(color: Colors.grey.withOpacity(0.1)),
                      ),
                    ),

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,

                      children: [
                        AppGradientButton(
                          onTap: () async {
                            final newMedicalJson = jsonEncode({
                              "pathologies": pathologies.entries
                                  .where((e) => e.value)
                                  .map((e) => e.key)
                                  .toList(),

                              "allergie_detail": allergyCtrl.text.trim(),

                              "autre_detail": otherCtrl.text.trim(),

                              "groupe_sanguin": bloodGroup,

                              "observations": obsCtrl.text.trim(),
                            });

                            final result = await UserService.updateUser(
                              user["cin"].toString(),
                              {
                                "nom": nameCtrl.text.trim(),

                                "email": emailCtrl.text.trim(),

                                "numero_de_telephone": _formatPhoneForBackend(
                                  phoneCtrl.text.trim(),
                                ),

                                "contact_familial": _formatPhoneForBackend(
                                  familyCtrl.text.trim(),
                                ),

                                "adresse": addressCtrl.text.trim(),

                                "etat_de_sante": newMedicalJson,

                                "sim_de_la_canne": _formatPhoneForBackend(
                                  simCtrl.text.trim(),
                                ),
                              },
                            );

                            if (!mounted) return;

                            if (result["success"]) {
                              Navigator.pop(ctx);

                              _loadData();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Modifications enregistrées avec succès",
                                  ),
                                  backgroundColor: AppTheme.neonGreen,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Erreur: ${result["error"]}"),
                                  backgroundColor: AppTheme.sosRed,
                                ),
                              );
                            }
                          },

                          icon: Icons.check_rounded,

                          label: "SAUVEGARDER LES MODIFICATIONS",

                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalSummary(
    Map<String, bool> pathologies,
    String allergy,
    String other,
    String blood,
    String obs,
  ) {
    final activePathologies = pathologies.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        _summaryRow("Groupe sanguin", blood),

        const SizedBox(height: 24),

        const Text(
          "PATHOLOGIES",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF94A3B8),
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),

        const SizedBox(height: 12),

        if (activePathologies.isEmpty)
          const Text(
            "Aucune pathologie signalée",
            style: TextStyle(
              color: Color(0xFF64748B),
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,

            children: activePathologies.map((p) {
              String label = p;

              if (p == "Allergies médicamenteuses" && allergy.isNotEmpty)
                label += " ($allergy)";

              if (p == "Autre" && other.isNotEmpty) label += " ($other)";

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),

                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                ),

                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),

        if (obs.isNotEmpty) ...[
          const SizedBox(height: 24),

          const Text(
            "OBSERVATIONS",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF94A3B8),
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            obs,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _summaryRow(String label, String value) => Row(
    children: [
      Text(
        "$label : ",
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w600,
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          color: AppTheme.primary,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    ],
  );

  Widget _fieldOrText(
    String label,
    String value,
    TextEditingController? controller,
    bool isEditing, {
    bool isPhone = false,
  }) {
    if (!isEditing || controller == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            SizedBox(
              width: 160,
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),

            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),

      child: TextField(
        controller: controller,

        keyboardType: isPhone ? TextInputType.number : TextInputType.text,

        inputFormatters: isPhone
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ]
            : null,

        decoration:
            AppTheme.inputDecoration(
              label,
              isPhone ? Icons.phone_rounded : Icons.edit_rounded,
            ).copyWith(
              prefixText: isPhone ? '+216 ' : null,

              prefixStyle: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }

  Widget _alertStatCard(int sos, int help, bool hasAlert) {
    final Color cardColor = sos > 0
        ? AppTheme.sosRed
        : help > 0
        ? AppTheme.accent
        : const Color(0xFF94A3B8);

    return Expanded(
      child: _HoverAlertCard(
        sos: sos,
        help: help,
        hasAlert: hasAlert,
        cardColor: cardColor,
        onTap: () => widget.onNavigate("/alerts"),
      ),
    );
  }

  Widget _alertBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
    ),
  );

  Widget _buildSystemStatus() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: AlertService.getTelemetryStream(),

      builder: (context, snapshot) {
        final tele = snapshot.data ?? {};

        final bool firebaseOk = tele.isNotEmpty;

        final String status = tele["status"]?.toString() ?? "HORS LIGNE";

        final String pitch = tele["pitch"]?.toString() ?? "0";

        final String roll = tele["roll"]?.toString() ?? "0";

        final String lat = tele["latitude"]?.toString() ?? "0";

        final String lon = tele["longitude"]?.toString() ?? "0";

        final bool isFallen = status.toUpperCase().contains("FALLEN");

        return Container(
          padding: const EdgeInsets.all(32),

          decoration: AppTheme.glassCard(),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  const Text(
                    "TÉLÉMÉTRIE LIVE",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                      letterSpacing: 1,
                    ),
                  ),

                  if (firebaseOk) _LiveDot(),
                ],
              ),

              const SizedBox(height: 32),

              _telemetryTile(
                "État du Terminal",
                status,
                isFallen ? AppTheme.sosRed : AppTheme.neonGreen,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _telemetryTile("Pitch", "$pitch°", AppTheme.primary),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: _telemetryTile("Roll", "$roll°", AppTheme.accent),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _telemetryTile(
                "Coordonnées GPS",
                "$lat, $lon",
                const Color(0xFF0EA5E9),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Divider(),
              ),

              const Text(
                "SERVICES RÉSEAU",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              _statusIndicator("Firebase Cloud Bridge", firebaseOk),

              _statusIndicator("GPS Satellites", lat != "0"),

              _statusIndicator("Capteurs MPU6050", pitch != "0"),
            ],
          ),
        );
      },
    );
  }

  Widget _telemetryTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusIndicator(String label, bool ok) => Padding(
    padding: const EdgeInsets.only(bottom: 14),

    child: Row(
      children: [
        Container(
          width: 10,

          height: 10,

          decoration: BoxDecoration(
            shape: BoxShape.circle,

            color: ok ? AppTheme.neonGreen : AppTheme.sosRed,

            boxShadow: [
              BoxShadow(
                color: (ok ? AppTheme.neonGreen : AppTheme.sosRed).withOpacity(
                  0.3,
                ),
                blurRadius: 8,
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        Text(
          ok ? "ACTIF" : "ERREUR",
          style: TextStyle(
            color: ok ? AppTheme.neonGreen : AppTheme.sosRed,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );

  Widget _typeStat(String label, int count, Color color) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    ],
  );

  String _normalizePhoneDigits(String raw) {
    String cleaned = raw.trim();

    if (cleaned.startsWith('+216'))
      cleaned = cleaned.substring(4);
    else if (cleaned.startsWith('00216'))
      cleaned = cleaned.substring(5);
    else if (cleaned.startsWith('216') && cleaned.length > 3)
      cleaned = cleaned.substring(3);

    cleaned = cleaned.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.length > 8) cleaned = cleaned.substring(0, 8);

    return cleaned;
  }

  String _formatPhoneForBackend(String eightDigits) {
    final digits = eightDigits.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) return '';

    return '+216$digits';
  }
}

class _HoverGlowButton extends StatefulWidget {
  final Widget child;

  final VoidCallback onTap;

  const _HoverGlowButton({required this.child, required this.onTap});

  @override
  State<_HoverGlowButton> createState() => _HoverGlowButtonState();
}

class _HoverGlowButtonState extends State<_HoverGlowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),

      onExit: (_) => setState(() => _hovered = false),

      child: GestureDetector(
        onTap: widget.onTap,

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),

          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),

          decoration: BoxDecoration(
            color: _hovered ? AppTheme.primary.withOpacity(0.08) : Colors.white,

            borderRadius: BorderRadius.circular(12),

            border: Border.all(
              color: _hovered
                  ? AppTheme.primary.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
            ),

            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.1),
                      blurRadius: 15,
                    ),
                  ]
                : [],
          ),

          child: widget.child,
        ),
      ),
    );
  }
}

// ── Hoverable Alert Card ────────────────────────────────────────────────
class _HoverAlertCard extends StatefulWidget {
  final int sos;
  final int help;
  final bool hasAlert;
  final Color cardColor;
  final VoidCallback? onTap;

  const _HoverAlertCard({
    required this.sos,
    required this.help,
    required this.hasAlert,
    required this.cardColor,
    this.onTap,
  });

  @override
  State<_HoverAlertCard> createState() => _HoverAlertCardState();
}

class _HoverAlertCardState extends State<_HoverAlertCard> {
  bool _hovered = false;

  Widget _alertBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final Color hoverColor = widget.cardColor;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _hovered ? hoverColor.withOpacity(0.06) : AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? hoverColor.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.1),
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: [
              if (_hovered)
                BoxShadow(
                  color: hoverColor.withOpacity(0.15),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                )
              else
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.cardColor.withOpacity(_hovered ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: widget.cardColor,
                      size: 24,
                    ),
                  ),

                ],
              ),
              const SizedBox(height: 24),
              Text(
                (widget.sos + widget.help).toString(),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: _hovered ? hoverColor : AppTheme.primary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Alertes Actives",
                style: TextStyle(
                  color: _hovered ? hoverColor : AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _alertBadge("${widget.sos} SOS", AppTheme.sosRed),
                  const SizedBox(width: 8),
                  _alertBadge("${widget.help} HELP", AppTheme.accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hoverable Stat Card ───────────────────────────────────────────────────────
class _HoverStatCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final int value;
  final String sub;
  final Color color;
  final VoidCallback? onTap;

  const _HoverStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    this.onTap,
  });

  @override
  State<_HoverStatCard> createState() => _HoverStatCardState();
}

class _HoverStatCardState extends State<_HoverStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withOpacity(0.06)
                : AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? widget.color.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.1),
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: [
              if (_hovered)
                BoxShadow(
                  color: widget.color.withOpacity(0.15),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                )
              else
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(_hovered ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.color, size: 24),
              ),
              const SizedBox(height: 24),
              Text(
                widget.value.toString(),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: _hovered ? widget.color : AppTheme.primary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  color: _hovered ? widget.color : AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                widget.sub,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _c,

          builder: (_, __) => Container(
            width: 8,

            height: 8,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              color: AppTheme.neonGreen.withOpacity(0.3 + (_c.value * 0.7)),

              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonGreen.withOpacity(0.3 * _c.value),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 10),

        const Text(
          "CONNEXION ACTIVE",
          style: TextStyle(
            color: AppTheme.neonGreen,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
