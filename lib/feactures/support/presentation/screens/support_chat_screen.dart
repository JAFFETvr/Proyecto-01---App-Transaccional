import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_extensions.dart';
import '../providers/support_chat_provider.dart';

/// Chat de soporte entre el propietario y el administrador. [ownerId] es el
/// dueño del hilo: si lo abre el propio propietario es su propio ID, si lo
/// abre un admin es el ID del propietario cuyo hilo está consultando.
class SupportChatScreen extends StatefulWidget {
  final String ownerId;
  final String ownerName;
  final String currentUserId;
  final bool asAdmin;

  const SupportChatScreen({
    super.key,
    required this.ownerId,
    required this.ownerName,
    required this.currentUserId,
    required this.asAdmin,
  });

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late SupportChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportChatProvider>().startChat(
        widget.ownerId,
        asAdmin: widget.asAdmin,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider = context.read<SupportChatProvider>();
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

  void _send() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    await context.read<SupportChatProvider>().sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<SupportChatProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Row(
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.orange500),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.ownerName,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: chat.loading && chat.messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : chat.messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Aún no hay mensajes. Escribe el primero para '
                              'resolver cualquier duda.',
                              style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
                              textAlign: TextAlign.center,
                            ),
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
                                  color: isMe ? AppColors.orange500 : context.surface,
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
                                    color: isMe ? Colors.white : context.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              decoration: BoxDecoration(
                color: context.surface,
                border: Border(top: BorderSide(color: context.borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        hintStyle: GoogleFonts.inter(fontSize: 14, color: context.textSecondary),
                        filled: true,
                        fillColor: context.bg,
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
      ),
    );
  }

  @override
  void dispose() {
    _chatProvider.stopChat();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
