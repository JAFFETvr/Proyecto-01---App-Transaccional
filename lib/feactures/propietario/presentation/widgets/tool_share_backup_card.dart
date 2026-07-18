import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/theme/app_colors.dart';
import '../providers/tool_provider.dart';
import '../screes/insurance_checkout_screen.dart';
import '../components/tool_list_item.dart' show kInsuranceMonthlyRate;
import 'section_title.dart';

/// Sección "Garantía y seguro" del formulario de herramienta: la garantía es
/// informativa/automática (la paga el solicitante), el seguro es opcional y
/// lo contrata el propietario vía Mercado Pago.
class ToolShareBackupCard extends StatefulWidget {
  final String toolId;
  final double estimatedValue;
  final bool isAvailable;
  final bool insuranceActive;

  const ToolShareBackupCard({
    super.key,
    required this.toolId,
    required this.estimatedValue,
    required this.isAvailable,
    required this.insuranceActive,
  });

  @override
  State<ToolShareBackupCard> createState() => _ToolShareBackupCardState();
}

class _ToolShareBackupCardState extends State<ToolShareBackupCard> {
  bool _processingInsurance = false;
  bool _cancellingInsurance = false;
  late bool _insuranceActive;

  double get _monthlyPremium => widget.estimatedValue * kInsuranceMonthlyRate;

  @override
  void initState() {
    super.initState();
    _insuranceActive = widget.insuranceActive;
  }

  /// El WebView de pago no devuelve el tool actualizado directamente; se lee
  /// del ToolProvider (ya sincronizado por confirmInsurancePayment) para
  /// reflejar el cambio sin tener que salir y volver a entrar a la pantalla.
  void _syncInsuranceFromProvider() {
    final tools = context.read<ToolProvider>().tools;
    for (final t in tools) {
      if (t.id == widget.toolId) {
        if (mounted) setState(() => _insuranceActive = t.wantsInsurance);
        return;
      }
    }
  }

  Future<void> _buyInsurance() async {
    setState(() => _processingInsurance = true);
    await openInsuranceCheckout(context, widget.toolId);
    _syncInsuranceFromProvider();
    if (mounted) setState(() => _processingInsurance = false);
  }

  Future<void> _cancelInsurance() async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Cancelar el seguro?'),
        content: const Text(
          'Se detiene la cobertura y no se te volverá a cobrar la prima mensual. '
          'Lo ya pagado este mes no se reembolsa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancellingInsurance = true);
    final provider = context.read<ToolProvider>();
    final ok = await provider.cancelInsurance(widget.toolId);
    if (!mounted) return;
    setState(() {
      _cancellingInsurance = false;
      if (ok) _insuranceActive = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Seguro cancelado.' : provider.error ?? 'No se pudo cancelar el seguro.'),
      backgroundColor: ok ? AppColors.success : AppColors.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showTerms(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.shield_outlined, color: cs.primary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Qué cubre la garantía de ToolShare',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.onSurface)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Text('Sí cubre:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
                  const SizedBox(height: 6),
                  const _TermLine(text: 'Daño accidental durante el periodo de renta'),
                  const _TermLine(text: 'Robo o extravío comprobado de la herramienta'),
                  const _TermLine(text: 'Roturas atribuibles al uso indebido del solicitante'),
                  const SizedBox(height: 14),
                  Text('No cubre:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.error)),
                  const SizedBox(height: 6),
                  const _TermLine(text: 'Desgaste normal por uso (brocas, discos, consumibles)', negative: true),
                  const _TermLine(text: 'Fletes, traslados o tiempo de inactividad del propietario', negative: true),
                  const _TermLine(text: 'Daños previos no declarados al publicar la herramienta', negative: true),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Entendido'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAvailable = widget.isAvailable;
    final semaphoreColor = isAvailable ? AppColors.success : const Color(0xFF2563EB);
    final semaphoreText = isAvailable
        ? 'Listo para rentar. Tu equipo está respaldado contra daño total y robo.'
        : 'Fondo bloqueado. MercadoPago tiene retenido el depósito del solicitante.';
    final semaphoreIcon = isAvailable ? Icons.check_circle_outline : Icons.lock_outline;
    final deposit = widget.estimatedValue * 0.10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Garantía y seguro'),
        const SizedBox(height: 12),

        // ── Garantía: informativa, automática, la paga el solicitante al rentar ──
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.verified_user_rounded, color: cs.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Garantía de la herramienta',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface)),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(
                  'Valor comercial tasado por IA: \$${widget.estimatedValue.toStringAsFixed(0)} MXN',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  'Depósito de garantía: \$${deposit.toStringAsFixed(0)} MXN (10% del valor tasado)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary),
                ),
                const SizedBox(height: 6),
                Text(
                  'No tienes que pagarlo ni activarlo tú: se cobra automáticamente al solicitante al confirmar la renta, y se libera si la herramienta se devuelve sin incidentes.',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: semaphoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: semaphoreColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(semaphoreIcon, color: semaphoreColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          semaphoreText,
                          style: TextStyle(fontSize: 12, color: semaphoreColor, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showTerms(context),
                    child: const Text('Ver qué cubre la garantía'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Seguro opcional: lo activa el propietario, prima mensual aparte ──
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.health_and_safety_outlined, color: cs.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Seguro opcional contra daños y robo',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface)),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(
                  '\$${_monthlyPremium.toStringAsFixed(0)} MXN/mes (5% del valor tasado)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cs.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Distinto del depósito de garantía: esta prima mensual es opcional y la paga el propietario, vía Mercado Pago.',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 12),
                if (_insuranceActive) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.verified_rounded, color: AppColors.success, size: 18),
                      const SizedBox(width: 8),
                      Text('Seguro activo',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.success)),
                    ]),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _cancellingInsurance ? null : _cancelInsurance,
                      icon: _cancellingInsurance
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.close_rounded, size: 16, color: cs.error),
                      label: Text(
                        _cancellingInsurance ? 'Cancelando...' : 'Cancelar seguro',
                        style: TextStyle(color: cs.error),
                      ),
                    ),
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _processingInsurance ? null : _buyInsurance,
                      icon: _processingInsurance
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.health_and_safety_outlined, size: 18),
                      label: Text(_processingInsurance ? 'Abriendo pago...' : 'Contratar seguro'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TermLine extends StatelessWidget {
  final String text;
  final bool negative;
  const _TermLine({required this.text, this.negative = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            negative ? Icons.close_rounded : Icons.check_rounded,
            size: 15,
            color: negative ? cs.error : AppColors.success,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
