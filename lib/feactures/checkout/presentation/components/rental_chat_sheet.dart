import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../providers/chat_provider.dart';

class RentalChatSheet extends StatefulWidget {
  final String rentalId;
  final String currentUserId;
  final String title;

  const RentalChatSheet({
    super.key,
    required this.rentalId,
    required this.currentUserId,
    required this.title,
  });

  static void show(BuildContext context, {required String rentalId, required String currentUserId, required String title}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RentalChatSheet(
        rentalId: rentalId,
        currentUserId: currentUserId,
        title: title,
      ),
    );
  }

  @override
  State<RentalChatSheet> createState() => _RentalChatSheetState();
}

class _RentalChatSheetState extends State<RentalChatSheet> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().startChat(widget.rentalId);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.orange500),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.slate900),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.slate600),
                  onPressed: () {
                    context.read<ChatProvider>().stopChat();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: chat.loading && chat.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : chat.messages.isEmpty
                    ? Center(
                        child: Text(
                          'Aún no hay mensajes. ¡Escribe el primero para coordinar la entrega!',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate600),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: chat.messages.length,
                        itemBuilder: (_, i) {
                          final m = chat.messages[i];
                          final isMe = m.senderId == widget.currentUserId;

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isMe ? AppColors.orange500 : AppColors.surface,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                                boxShadow: AppColors.cardShadow,
                              ),
                              child: Text(
                                m.message,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: isMe ? Colors.white : AppColors.slate900,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Input Bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.slate600),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.orange500,
                  child: chat.sending
                      ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : IconButton(
                          icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                          onPressed: _send,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _send() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    await context.read<ChatProvider>().sendMessage(text);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
