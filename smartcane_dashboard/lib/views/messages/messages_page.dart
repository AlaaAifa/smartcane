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

  @override
  void initState() {
    super.initState();
    // Initialize the stream once to avoid recreating it on every build
    _messagesStream = MessageService.getMessagesStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ClientMessage> _applyFilters(List<ClientMessage> allMessages) {
    return allMessages.where((msg) {
      bool matchesFilter = true;
      if (_activeFilter == 'Unread') {
        matchesFilter = msg.status == MessageStatus.unread;
      } else if (_activeFilter == 'Replied') {
        matchesFilter = msg.status == MessageStatus.replied;
      }

      final matchesSearch = msg.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          msg.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          msg.email.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<List<ClientMessage>>(
        stream: _messagesStream,
        builder: (context, snapshot) {
          final allMessages = snapshot.data ?? [];
          final filteredMessages = _applyFilters(allMessages);
          final unreadCount = allMessages.where((m) => m.status == MessageStatus.unread).length;
          final bool isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

          return Column(
            children: [
              // SaaS Header with integrated controls
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Messages",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.sosRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.notifications_active, size: 16, color: AppTheme.sosRed),
                                const SizedBox(width: 8),
                                Text(
                                  "$unreadCount NEW",
                                  style: const TextStyle(
                                    color: AppTheme.sosRed,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
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
              // Main content area
              Expanded(
                child: isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: _buildMessagesGrid(filteredMessages),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['All', 'Unread', 'Replied'].map((filter) {
          final isActive = _activeFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isActive
                    ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                filter,
                style: TextStyle(
                  color: isActive ? AppTheme.primary : Colors.grey.shade600,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
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
      width: 300,
      height: 40,
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          // We update the local state to filter the list
          // Because _searchController is stable and the widget tree identity is preserved,
          // focus will not be lost.
          setState(() => _searchQuery = val);
        },
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: "Search messages...",
          prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          fillColor: Colors.grey.shade100,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesGrid(List<ClientMessage> messages) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "No messages found",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      int crossAxisCount = constraints.maxWidth > 1400 ? 3 : (constraints.maxWidth > 900 ? 2 : 1);
      
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: crossAxisCount == 1 ? 2.5 : 1.5,
        ),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return _buildMessageCard(messages[index]);
        },
      );
    });
  }

  Widget _buildMessageCard(ClientMessage msg) {
    final bool isUnread = msg.status == MessageStatus.unread;

    return InkWell(
      onTap: () => _showDetailsModal(msg),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread ? AppTheme.primary.withOpacity(0.1) : Colors.grey.shade200,
            width: isUnread ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: (isUnread ? AppTheme.primary : Colors.grey.shade100),
                    child: Text(
                      msg.firstname[0].toUpperCase(),
                      style: TextStyle(
                        color: isUnread ? Colors.white : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          _formatDate(msg.createdAt),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusDot(msg.status),
                ],
              ),
            ),
            const Divider(height: 1),
            // Card Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                        color: isUnread ? AppTheme.primary : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        msg.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Card Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    msg.status == MessageStatus.replied ? Icons.check_circle_outline : Icons.pending_actions,
                    size: 14,
                    color: msg.status == MessageStatus.replied ? AppTheme.normalGreen : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    msg.status == MessageStatus.replied ? "Replied" : "Awaiting Reply",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: msg.status == MessageStatus.replied ? AppTheme.normalGreen : Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "View Details",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 14, color: AppTheme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDot(MessageStatus status) {
    if (status != MessageStatus.unread) return const SizedBox.shrink();
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppTheme.sosRed,
        shape: BoxShape.circle,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return "Just now";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    
    return "${date.day}/${date.month}/${date.year}";
  }

  void _showDetailsModal(ClientMessage msg) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 700,
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusBadge(msg.status),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                msg.subject,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow("Client", msg.fullName),
              _buildDetailRow("Email", msg.email),
              _buildDetailRow("Date", _formatFullDate(msg.createdAt)),
              if (msg.status == MessageStatus.replied) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.reply, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            "Replied by ${msg.staffName} on ${_formatFullDate(msg.repliedAt!)}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        msg.replyBody ?? "",
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(height: 48),
              const Text(
                "Message:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(
                    msg.message,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  if (msg.status == MessageStatus.unread)
                    _buildActionButton(
                      label: "Reply Now",
                      icon: Icons.reply,
                      color: AppTheme.primary,
                      onTap: () {
                        Navigator.pop(context); // Close details
                        _showReplyModal(msg);
                      },
                    ),
                  if (msg.status == MessageStatus.replied)
                    _buildActionButton(
                      label: "Send Another Reply",
                      icon: Icons.reply_all,
                      color: Colors.blueGrey,
                      onTap: () {
                        Navigator.pop(context); // Close details
                        _showReplyModal(msg);
                      },
                    ),
                  const Spacer(),
                  _buildActionButton(
                    label: "Delete",
                    icon: Icons.delete_outline,
                    color: AppTheme.sosRed,
                    onTap: () {
                      MessageService.deleteMessage(msg.id);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  void _showReplyModal(ClientMessage msg) {
    final TextEditingController subjectController = TextEditingController(text: "Re: ${msg.subject}");
    final TextEditingController bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Reply to Message",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              _buildReplyField("To", msg.email, enabled: false),
              const SizedBox(height: 16),
              _buildReplyField("Subject", "", controller: subjectController),
              const SizedBox(height: 16),
              const Text(
                "Message Body:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: "Type your reply here...",
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (bodyController.text.trim().isEmpty) return;

                      await MessageService.sendReply(
                        id: msg.id,
                        email: msg.email,
                        subject: subjectController.text,
                        body: bodyController.text,
                        originalMessage: msg.message,
                        staffName: BaseService.staffName ?? "SmartCane Staff",
                      );

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Reply sent successfully"),
                          backgroundColor: AppTheme.normalGreen,
                        ),
                      );
                    },
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text("Send Reply"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(MessageStatus status) {
    Color color;
    String label;

    switch (status) {
      case MessageStatus.unread:
        color = AppTheme.sosRed;
        label = "UNREAD";
        break;
      case MessageStatus.replied:
        color = Colors.blue;
        label = "REPLIED";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildReplyField(String label, String value, {bool enabled = true, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller ?? TextEditingController(text: value),
          enabled: enabled,
          style: TextStyle(
            color: enabled ? Colors.black87 : Colors.grey.shade600,
            fontWeight: enabled ? FontWeight.w500 : FontWeight.normal,
          ),
          decoration: InputDecoration(
            fillColor: enabled ? Colors.white : Colors.grey.shade100,
          ),
        ),
      ],
    );
  }
}
