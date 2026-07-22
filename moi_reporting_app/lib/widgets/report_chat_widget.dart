import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import '../models/models.dart';
import '../services/report_service.dart';

class ReportChatWidget extends StatefulWidget {
  final String reportId;
  final String token;
  final String currentUserId;

  const ReportChatWidget({
    super.key,
    required this.reportId,
    required this.token,
    required this.currentUserId,
  });

  @override
  State<ReportChatWidget> createState() => _ReportChatWidgetState();
}

class _ReportChatWidgetState extends State<ReportChatWidget> {
  final List<ReportMessageModel> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  Timer? _pollingTimer;
  final Dio _dio = Dio(BaseOptions(baseUrl: ReportService.baseUrl));

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Poll for new messages every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchMessages(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    try {
      final response = await _dio.get(
        '/api/v1/lawyer/reports/${widget.reportId}/messages',
        options: Options(
          headers: {'Authorization': 'Bearer ${widget.token}'},
        ),
      );

      final List rawMessages = response.data ?? [];
      final List<ReportMessageModel> parsedMessages = rawMessages
          .map((m) => ReportMessageModel.fromJson(m))
          .toList();

      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(parsedMessages);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      final response = await _dio.post(
        '/api/v1/lawyer/reports/${widget.reportId}/messages',
        data: {'messageText': text},
        options: Options(
          headers: {'Authorization': 'Bearer ${widget.token}'},
        ),
      );

      final newMessage = ReportMessageModel.fromJson(response.data);
      if (mounted) {
        setState(() {
          _messages.add(newMessage);
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.forum_outlined, color: Color(0xFF1E3A8A), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Legal Counsel Chat',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          // Chat Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet. Start the discussion.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderId == widget.currentUserId;
                      return _buildMessageBubble(msg, isMe);
                    },
                  ),
          ),
          const Divider(height: 1, color: Colors.grey),
          // Input bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF1E3A8A),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ReportMessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1E3A8A) : Colors.grey[100],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender role indicator
            Text(
              isMe ? 'You' : (msg.senderRole == 'lawyer' ? 'Advocate' : 'Citizen'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isMe ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.messageText,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
