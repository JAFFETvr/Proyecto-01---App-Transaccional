import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/theme/theme_extensions.dart';
import '../providers/card_provider.dart';
import 'add_card_screen.dart';

class SavedCardsScreen extends StatefulWidget {
  const SavedCardsScreen({super.key});

  @override
  State<SavedCardsScreen> createState() => _SavedCardsScreenState();
}

class _SavedCardsScreenState extends State<SavedCardsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CardProvider>().fetchCards();
    });
  }

  Future<void> _delete(String cardId) async {
    final provider = context.read<CardProvider>();
    final ok = await provider.deleteCard(cardId);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.error ?? 'No se pudo eliminar la tarjeta'),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardProvider>();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('Métodos de pago')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddCardScreen()),
          );
          if (added == true && mounted) {
            context.read<CardProvider>().fetchCards();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar tarjeta'),
      ),
      body: provider.loading && provider.cards.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.cards.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.credit_card_off_outlined, size: 48, color: context.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          'Aún no tienes tarjetas guardadas',
                          style: TextStyle(color: context.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.cards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final card = provider.cards[i];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: const Icon(Icons.credit_card_rounded),
                        title: Text('${card.cardBrand.toUpperCase()} •••• ${card.lastFourDigits}'),
                        subtitle: Text(
                          'Vence ${card.expirationMonth.toString().padLeft(2, '0')}/${card.expirationYear}',
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                          onPressed: () => _delete(card.id),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
