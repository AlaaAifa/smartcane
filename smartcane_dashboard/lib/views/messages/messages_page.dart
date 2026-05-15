import 'package:flutter/material.dart';

import '../../models/message_model.dart';

import '../../services/services.dart';

import '../theme.dart';



class MessagesPage extends StatefulWidget {

  const MessagesPage({super.key});



  @override

  State<MessagesPage> createState() => _MessagesPageState();

}



class _MessagesPageState extends State<MessagesPage> {

  final TextEditingController _searchController = TextEditingController();

  late Stream<List<ClientMessage>> _messagesStream;

  String _activeFilter = 'All';
  String _searchQuery = '';
  
  // Cache for performance
  List<ClientMessage> _allMessages = [];
  List<ClientMessage> _filteredMessages = [];
  int _unreadCount = 0;



  @override

  void initState() {

    super.initState();

    _messagesStream = MessageService.getMessagesStream();

  }



  @override

  void dispose() {

    _searchController.dispose();

    super.dispose();

  }



  void _updateDerivedData(List<ClientMessage> all) {
    _allMessages = all;
    _unreadCount = all.where((m) => m.status == MessageStatus.unread).length;
    _filteredMessages = all.where((msg) {
      bool matchesFilter = true;
      if (_activeFilter == 'Unread') matchesFilter = msg.status == MessageStatus.unread;
      else if (_activeFilter == 'Replied') matchesFilter = msg.status == MessageStatus.replied;

      final sq = _searchQuery.toLowerCase();
      final matchesSearch = msg.subject.toLowerCase().contains(sq) ||
          msg.fullName.toLowerCase().contains(sq) ||
          msg.email.toLowerCase().contains(sq);

      return matchesFilter && matchesSearch;
    }).toList();
  }



  @override

  Widget build(BuildContext context) {

    return StreamBuilder<List<ClientMessage>>(

      stream: _messagesStream,

      builder: (context, snapshot) {

        if (snapshot.hasData) {
          _updateDerivedData(snapshot.data!);
        }
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return RepaintBoundary(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Centre de Messagerie", style: Theme.of(context).textTheme.headlineMedium),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text("${_allMessages.length} DEMANDES CLIENTS", style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                              ),
                            ],
                          ),
                          if (_unreadCount > 0)
                            _PulseStatus(count: _unreadCount),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          _buildFilterTabs(),
                          const Spacer(),
                          _buildSearchField(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Stats indicator for total
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  child: Text("${_allMessages.length} DEMANDES TOTALES", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
              
              // Messages Content
              if (isLoading && _allMessages.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(48),
                  sliver: _buildMessagesSliver(_filteredMessages),
                ),
            ],
          ),
        );

      },

    );

  }



  Widget _buildFilterTabs() {

    return Container(

      padding: const EdgeInsets.all(6),

      decoration: BoxDecoration(

        color: const Color(0xFFF1F5F9),

        borderRadius: BorderRadius.circular(14),

      ),

      child: Row(

        mainAxisSize: MainAxisSize.min,

        children: ['All', 'Unread', 'Replied'].map((filter) {

          final isActive = _activeFilter == filter;

          final String label = filter == 'All' ? 'TOUS' : (filter == 'Unread' ? 'NON LUS' : 'RÉPONDUS');

          return GestureDetector(

            onTap: () => setState(() => _activeFilter = filter),

            child: AnimatedContainer(

              duration: const Duration(milliseconds: 200),

              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),

              decoration: BoxDecoration(

                color: isActive ? Colors.white : Colors.transparent,

                borderRadius: BorderRadius.circular(10),

                boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : null,

              ),

              child: Text(

                label,

                style: TextStyle(

                  color: isActive ? AppTheme.primary : const Color(0xFF64748B),

                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,

                  fontSize: 11,

                  letterSpacing: 0.5,

                ),

              ),

            ),

          );

        }).toList(),

      ),

    );

  }



  Widget _buildSearchField() {

    return SizedBox(

      width: 350,

      child: TextField(

        controller: _searchController,

        onChanged: (val) => setState(() => _searchQuery = val),

        style: const TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w600),

        decoration: AppTheme.inputDecoration("Rechercher dans les messages...", Icons.search_rounded),

      ),

    );

  }



  Widget _buildMessagesSliver(List<ClientMessage> messages) {
    if (messages.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text(
                "Aucun message ne correspond à vos critères",
                style: TextStyle(fontSize: 16, color: Colors.grey.withOpacity(0.5), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return SliverLayoutBuilder(builder: (context, constraints) {
      int crossAxisCount = constraints.crossAxisExtent > 1400 ? 3 : (constraints.crossAxisExtent > 900 ? 2 : 1);
      
      return SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 32,
          mainAxisSpacing: 32,
          childAspectRatio: crossAxisCount == 1 ? 2.3 : 1.4,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildMessageCard(messages[index]),
          childCount: messages.length,
        ),
      );
    });
  }



  Widget _buildMessageCard(ClientMessage msg) {
    final bool isUnread = msg.status == MessageStatus.unread;
    final bool isReplied = msg.status == MessageStatus.replied;
    final accentColor = isUnread ? AppTheme.sosRed : (isReplied ? AppTheme.neonGreen : AppTheme.primary);
    
    final Color bgColor = isUnread 
        ? const Color(0xFFFFF1F2) 
        : (isReplied ? const Color(0xFFF0FDF4) : Colors.white);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(width: 6, color: accentColor),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showDetailsModal(msg),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                msg.firstname.isNotEmpty ? msg.firstname[0].toUpperCase() : "?",
                                style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(msg.fullName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppTheme.primary)),
                                const SizedBox(height: 2),
                                Text(_formatDate(msg.createdAt), style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          if (isUnread)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: AppTheme.sosRed, borderRadius: BorderRadius.circular(8)),
                              child: const Text("NOUVEAU", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        msg.subject.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          msg.message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF334155), fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(
                            isReplied ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
                            size: 16,
                            color: isReplied ? AppTheme.neonGreen : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isReplied ? "TRAITÉ ET RÉPONDU" : "EN ATTENTE",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isReplied ? AppTheme.neonGreen : const Color(0xFF94A3B8),
                            ),
                          ),
                          const Spacer(),
                          const Text("LIRE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_right_alt_rounded, size: 18, color: AppTheme.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  String _formatDate(DateTime date) {

    final now = DateTime.now();

    final diff = now.difference(date);

    if (diff.inMinutes < 60) return "À l'instant";

    if (diff.inHours < 24) return "Il y a ${diff.inHours}h";

    if (diff.inDays < 7) return "Il y a ${diff.inDays}j";

    return "${date.day}/${date.month}/${date.year}";

  }



  void _showDetailsModal(ClientMessage msg) {

    showDialog(

      context: context,

      builder: (context) => Dialog(

        backgroundColor: Colors.transparent,

        child: Container(

          width: 750,

          decoration: BoxDecoration(

            color: AppTheme.bgCard,

            borderRadius: BorderRadius.circular(32),

            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40)],

          ),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              _dialogHeader(msg.status),

              Flexible(

                child: SingleChildScrollView(

                  padding: const EdgeInsets.all(40),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(msg.subject, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -0.5)),

                      const SizedBox(height: 32),

                      _buildDetailRow("CLIENT", msg.fullName, Icons.person_outline_rounded),

                      _buildDetailRow("EMAIL", msg.email, Icons.email_outlined),

                      _buildDetailRow("RÉCEPTION", _formatFullDate(msg.createdAt), Icons.calendar_today_rounded),

                      

                      if (msg.status == MessageStatus.replied) ...[

                        const SizedBox(height: 32),

                        Container(

                          padding: const EdgeInsets.all(20),

                          decoration: BoxDecoration(

                            color: const Color(0xFFF8FAFC),

                            borderRadius: BorderRadius.circular(20),

                            border: Border.all(color: AppTheme.primary.withOpacity(0.1)),

                          ),

                          child: Column(

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              Row(

                                children: [

                                  const Icon(Icons.reply_rounded, size: 18, color: AppTheme.primary),

                                  const SizedBox(width: 12),

                                  Text(

                                    "RÉPONDU PAR ${msg.staffName?.toUpperCase() ?? 'STAFF'} LE ${_formatFullDate(msg.repliedAt!).toUpperCase()}",

                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1),

                                  ),

                                ],

                              ),

                              const SizedBox(height: 16),

                              Text(msg.replyBody ?? "", style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.6, fontWeight: FontWeight.w500)),

                            ],

                          ),

                        ),

                      ],

                      

                      const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Divider(height: 1, color: Color(0xFFF1F5F9))),

                      const Text("MESSAGE DU CLIENT :", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF94A3B8), letterSpacing: 1.2)),

                      const SizedBox(height: 16),

                      Container(

                        width: double.infinity,

                        padding: const EdgeInsets.all(20),

                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),

                        child: Text(msg.message, style: const TextStyle(fontSize: 15, height: 1.6, color: AppTheme.primary, fontWeight: FontWeight.w500)),

                      ),

                    ],

                  ),

                ),

              ),

              _dialogActions(msg),

            ],

          ),

        ),

      ),

    );

  }



  Widget _dialogHeader(MessageStatus status) => Container(

    padding: const EdgeInsets.all(32),

    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),

    child: Row(

      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [

        _buildStatusBadge(status),

        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8))),

      ],

    ),

  );



  Widget _dialogActions(ClientMessage msg) => Container(

    padding: const EdgeInsets.all(32),

    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)), border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1)))),

    child: Row(

      children: [

        AppGradientButton(

          onTap: () {

            Navigator.pop(context);

            _showReplyModal(msg);

          },

          icon: Icons.reply_rounded,

          label: msg.status == MessageStatus.unread ? "RÉPONDRE AU CLIENT" : "NOUVELLE RÉPONSE",

          color: AppTheme.primary,

        ),

        const Spacer(),

        TextButton.icon(

          onPressed: () {

            MessageService.deleteMessage(msg.id);

            Navigator.pop(context);

          },

          icon: const Icon(Icons.delete_outline_rounded, size: 18),

          label: const Text("SUPPRIMER", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),

          style: TextButton.styleFrom(foregroundColor: AppTheme.sosRed),

        ),

      ],

    ),

  );



  Widget _buildDetailRow(String label, String value, IconData icon) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 20),

      child: Row(

        children: [

          Container(

            padding: const EdgeInsets.all(8),

            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),

            child: Icon(icon, size: 16, color: AppTheme.primary),

          ),

          const SizedBox(width: 16),

          SizedBox(

            width: 100,

            child: Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),

          ),

          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 14)),

        ],

      ),

    );

  }



  void _showReplyModal(ClientMessage msg) {

    final TextEditingController subjectController = TextEditingController(text: "Re: ${msg.subject}");

    final TextEditingController bodyController = TextEditingController();



    showDialog(

      context: context,

      builder: (context) => Dialog(

        backgroundColor: Colors.transparent,

        child: Container(

          width: 650,

          decoration: BoxDecoration(

            color: AppTheme.bgCard,

            borderRadius: BorderRadius.circular(32),

            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40)],

          ),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Container(

                padding: const EdgeInsets.all(32),

                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),

                child: Row(

                  children: [

                    const Icon(Icons.reply_rounded, color: AppTheme.primary),

                    const SizedBox(width: 16),

                    const Text("RÉPONDRE AU CLIENT", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 0.5)),

                    const Spacer(),

                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8))),

                  ],

                ),

              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDialogField("Destinataire", TextEditingController(text: msg.email), Icons.email_outlined, enabled: false),
                      const SizedBox(height: 16),
                      _buildDialogField("Objet", subjectController, Icons.subject_rounded),
                      const SizedBox(height: 24),
                      const Text("VOTRE RÉPONSE :", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF94A3B8), letterSpacing: 1)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: bodyController,
                        maxLines: 6,
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                        decoration: AppTheme.inputDecoration("Écrivez votre message ici...", Icons.edit_note_rounded),
                      ),
                    ],
                  ),
                ),
              ),

              Container(

                padding: const EdgeInsets.all(32),

                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)), border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1)))),

                child: Row(

                  mainAxisAlignment: MainAxisAlignment.end,

                  children: [

                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("ANNULER", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900))),

                    const SizedBox(width: 24),

                    AppGradientButton(

                      onTap: () async {

                        if (bodyController.text.trim().isEmpty) return;

                        await MessageService.sendReply(

                          id: msg.id,

                          email: msg.email,

                          subject: subjectController.text,

                          body: bodyController.text,

                          originalMessage: msg.message,

                          staffName: BaseService.staffName ?? "SIRIUS Staff",

                        );

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Réponse envoyée avec succès"), backgroundColor: AppTheme.primary));

                      },

                      icon: Icons.send_rounded,

                      label: "ENVOYER LA RÉPONSE",

                      color: AppTheme.primary,

                    ),

                  ],

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildDialogField(String label, TextEditingController controller, IconData icon, {bool enabled = true}) {

    return TextField(

      controller: controller,

      enabled: enabled,

      style: TextStyle(color: enabled ? AppTheme.primary : const Color(0xFF94A3B8), fontWeight: FontWeight.w600),

      decoration: AppTheme.inputDecoration(label, icon).copyWith(

        fillColor: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),

      ),

    );

  }



  Widget _buildStatusBadge(MessageStatus status) {

    final bool isUnread = status == MessageStatus.unread;

    final color = isUnread ? AppTheme.sosRed : AppTheme.primary;

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),

      child: Text(isUnread ? "MESSAGE NON LU" : "TRAITÉ ET RÉPONDU", style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),

    );

  }



  String _formatFullDate(DateTime date) {

    return "${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

  }

}



class _PulseStatus extends StatefulWidget {

  final int count;

  const _PulseStatus({required this.count});



  @override

  State<_PulseStatus> createState() => _PulseStatusState();

}



class _PulseStatusState extends State<_PulseStatus> with SingleTickerProviderStateMixin {

  late AnimationController _controller;



  @override

  void initState() {

    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  }



  @override

  void dispose() {

    _controller.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    return AnimatedBuilder(

      animation: _controller,

      builder: (context, child) => Container(

        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),

        decoration: BoxDecoration(

          color: AppTheme.sosRed.withOpacity(0.05 + (_controller.value * 0.05)),

          borderRadius: BorderRadius.circular(14),

          border: Border.all(color: AppTheme.sosRed.withOpacity(0.2 + (_controller.value * 0.2))),

        ),

        child: Row(

          children: [

            const Icon(Icons.notifications_active_rounded, size: 20, color: AppTheme.sosRed),

            const SizedBox(width: 12),

            Text("${widget.count} NOUVEAU(X) MESSAGE(S)", style: const TextStyle(color: AppTheme.sosRed, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),

          ],

        ),

      ),

    );

  }

}

