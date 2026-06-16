import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/widgets/primary_gradient_button.dart';

class RentalTrackingOwnerScreen extends StatefulWidget {
  const RentalTrackingOwnerScreen({super.key});

  @override
  State<RentalTrackingOwnerScreen> createState() =>
      _RentalTrackingOwnerScreenState();
}

class _RentalTrackingOwnerScreenState
    extends State<RentalTrackingOwnerScreen> {
  int _phase = 0;
  bool _loading = false;

  Future<void> _confirmDelivery() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() { _phase = 1; _loading = false; });
  }

  Future<void> _acceptReturn() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() { _phase = 2; _loading = false; });
  }

  Future<void> _rejectReturn() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() { _phase = 3; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.slate900),
        title: Text(
          'Panel del Propietario',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.slate900,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _OwnerPhaseIndicator(phase: _phase),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: IndexedStack(
                  index: _phase > 3 ? 3 : _phase,
                  children: [
                    _OwnerPhase0(
                      loading: _loading,
                      onConfirm: _confirmDelivery,
                    ),
                    _OwnerPhase1(),
                    _OwnerPhase2Accepted(),
                    _OwnerPhase2Rejected(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Botones fase 1: Devolución ─────────────────────────────────────
      bottomNavigationBar: _phase == 1
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    'El solicitante indica que devuelve la herramienta:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.slate600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    // ── Botón "Reportar Daño" rojo desvanecido ─────────────
                    Expanded(
                      child: GestureDetector(
                        onTap: _loading ? null : _rejectReturn,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.dangerBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.danger.withOpacity(0.3)),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cancel_outlined,
                                    color: AppColors.danger, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Reportar Daño',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ── Botón "Recibido en Buen Estado" verde ──────────────
                    Expanded(
                      child: GestureDetector(
                        onTap: _loading ? null : _acceptReturn,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Buen Estado',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ]),
              ),
            )
          : null,
    );
  }
}

// ── Fases ────────────────────────────────────────────────────────────────────

class _OwnerPhase0 extends StatelessWidget {
  final bool loading;
  final VoidCallback onConfirm;

  const _OwnerPhase0({required this.loading, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            color: AppColors.successBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.handshake_outlined,
              size: 50, color: AppColors.success),
        ),
        const SizedBox(height: 28),
        Text(
          'Confirmar Entrega',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.slate900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'El solicitante ha pagado el depósito. Cuando entregues la herramienta en persona, presiona confirmar.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.slate600,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.successBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.lock_rounded, color: AppColors.success, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Los fondos están retenidos y se liberarán al finalizar correctamente la renta.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF064E3B),
                  height: 1.4,
                ),
              ),
            ),
          ]),
        ),
        const Spacer(),
        loading
            ? const CircularProgressIndicator()
            : PrimaryGradientButton(
                label: 'Confirmar que entregué la herramienta',
                icon: Icons.check_circle_outline,
                height: 58,
                onPressed: onConfirm,
              ),
      ],
    );
  }
}

class _OwnerPhase1 extends StatelessWidget {
  const _OwnerPhase1();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.schedule_outlined,
              size: 46, color: Color(0xFF6366F1)),
        ),
        const SizedBox(height: 24),
        Text(
          'Esperando devolución',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.slate900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'La herramienta está en manos del solicitante. Cuando la devuelva, verás las opciones para confirmar o rechazar el estado.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.slate600,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFF6366F1),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Renta en curso…',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.slate600,
          ),
        ),
      ],
    );
  }
}

class _OwnerPhase2Accepted extends StatelessWidget {
  const _OwnerPhase2Accepted();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100, height: 100,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 56, color: Colors.white),
        ),
        const SizedBox(height: 28),
        Text(
          'Renta completada ✓',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.success,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Los fondos han sido liberados a tu cuenta. El depósito fue devuelto al solicitante.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.slate600,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        PrimaryGradientButton(
          label: 'Volver al inicio',
          icon: Icons.home_outlined,
          height: 52,
          onPressed: () =>
              Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ],
    );
  }
}

class _OwnerPhase2Rejected extends StatelessWidget {
  const _OwnerPhase2Rejected();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            color: AppColors.dangerBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.report_problem_outlined,
              size: 50, color: AppColors.danger),
        ),
        const SizedBox(height: 28),
        Text(
          'Disputa abierta',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.danger,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'El equipo de ToolShare revisará el caso. Los fondos quedan bloqueados hasta resolver la disputa.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.slate600,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.dangerBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.danger.withOpacity(0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.support_agent_outlined,
                color: AppColors.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Nuestro equipo se pondrá en contacto contigo en las próximas 24 horas.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.danger,
                  height: 1.4,
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

// ── Indicador de fases ───────────────────────────────────────────────────────

class _OwnerPhaseIndicator extends StatelessWidget {
  final int phase;
  const _OwnerPhaseIndicator({required this.phase});

  @override
  Widget build(BuildContext context) {
    const labels = ['Entrega', 'En Renta', 'Cierre'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                color: i ~/ 2 < (phase > 1 ? 1 : phase)
                    ? AppColors.orange500
                    : const Color(0xFFE2E8F0),
              ),
            );
          }
          final idx = i ~/ 2;
          final mapped = phase > 1 ? 1 : phase;
          final done = idx < mapped;
          final active = idx == mapped;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: done
                    ? AppColors.primaryGradient
                    : null,
                color: done
                    ? null
                    : active
                        ? AppColors.orange500.withOpacity(0.1)
                        : const Color(0xFFE2E8F0),
                border: Border.all(
                  color: active
                      ? AppColors.orange500
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${idx + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? AppColors.orange500
                              : AppColors.slate600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[idx],
              style: GoogleFonts.inter(
                fontSize: 11,
                color: active ? AppColors.orange500 : AppColors.slate600,
                fontWeight:
                    active ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ]);
        }),
      ),
    );
  }
}
