import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/session/session_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_extensions.dart';
import '../providers/support_threads_provider.dart';
import 'support_chat_screen.dart';

/// Abre el mismo SupportChatScreen del propietario, pero como admin (asAdmin: true).
class AdminSupportThreadsScreen extends StatefulWidget {
  const AdminSupportThreadsScreen({super.key});

  @override
  State<AdminSupportThreadsScreen> createState() => _AdminSupportThreadsScreenState();
}

class _AdminSupportThreadsScreenState extends State<AdminSupportThreadsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportThreadsProvider>().fetchThreads();
    });
  }

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupportThreadsProvider>();
    final currentUserId = context.watch<SessionProvider>().userId;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          'Chat con propietarios',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: context.textSecondary,
            onPressed: () => provider.fetchThreads(),
          ),
        ],
      ),
      body: provider.loading && provider.threads.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.threads.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forum_outlined, size: 48, color: context.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          'Todavía no hay conversaciones de soporte.',
                          style: TextStyle(color: context.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.threads.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final thread = provider.threads[i];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.orange500,
                          child: Icon(Icons.person_outline, color: Colors.white),
                        ),
                        title: Text(
                          thread.ownerName,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          thread.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          _formatTime(thread.lastMessageAt),
                          style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SupportChatScreen(
                              ownerId: thread.ownerId,
                              ownerName: thread.ownerName,
                              currentUserId: currentUserId,
                              asAdmin: true,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
