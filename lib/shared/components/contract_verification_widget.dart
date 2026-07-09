import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../feactures/checkout/domain/entitie/rental_entity.dart';
import '../../feactures/checkout/presentation/providers/rental_provider.dart';
import '../theme/app_colors.dart';

class ContractVerificationWidget extends StatefulWidget {
  final RentalEntity rental;

  const ContractVerificationWidget({
    super.key,
    required this.rental,
  });

  @override
  State<ContractVerificationWidget> createState() => _ContractVerificationWidgetState();
}

class _ContractVerificationWidgetState extends State<ContractVerificationWidget> {
  bool _verifying = false;
  bool? _isValid;
  String? _recalculatedHash;
  String? _error;

  Future<void> _verify() async {
    setState(() {
      _verifying = true;
      _isValid = null;
      _recalculatedHash = null;
      _error = null;
    });

    try {
      final res = await context.read<RentalProvider>().verifyContract(widget.rental.id);
      if (res != null) {
        setState(() {
          _isValid = res['valid'] as bool? ?? false;
          _recalculatedHash = res['recalculated_hash'] as String?;
        });
      } else {
        setState(() {
          _error = context.read<RentalProvider>().error ?? 'Error de conexión';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error inesperado al validar.';
      });
    } finally {
      setState(() {
        _verifying = false;
      });
    }
  }

  void _showLegalContract(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Encabezado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'CONTRATO DIGITAL DE ARRENDAMIENTO',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              // Cuerpo del contrato
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado legal
                      Center(
                        child: Column(
                          children: [
                            const Icon(Icons.gavel_outlined, size: 40, color: Color(0xFF475569)),
                            const SizedBox(height: 8),
                            Text(
                              'PÓLIZA DE CONTRATO Y GARANTÍA',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'ToolShare - Red de Confianza Algorítmica',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 24, thickness: 1),
                      
                      _buildClauseTitle('DECLARACIONES Y CLÁUSULAS'),
                      const SizedBox(height: 8),
                      _buildClauseText(
                        '1. VALIDEZ DE IDENTIDAD: Las partes declaran haber completado satisfactoriamente el registro biométrico y escaneo de INE (KYC), vinculando legalmente sus firmas a la presente transacción.',
                      ),
                      _buildClauseText(
                        '2. TARIFA DIARIA Y TOTAL: Se establece una tarifa de renta de \$${widget.rental.dailyRate.toStringAsFixed(0)} MXN/día. El importe total de la renta devengado es de \$${widget.rental.totalAmount.toStringAsFixed(0)} MXN.',
                      ),
                      _buildClauseText(
                        '3. COBERTURA DE SEGURO (IA): El inquilino acepta un cargo en garantía de \$${widget.rental.deductibleAmount.toStringAsFixed(0)} MXN, correspondiente al 10% del valor de catálogo del activo, que servirá de deducible en caso de siniestro.',
                      ),
                      _buildClauseText(
                        '4. INTEGRIDAD: El contrato se firma digitalmente usando la marca de tiempo de entrega, geolocalización de encuentro e identificador de hardware.',
                      ),
                      
                      const SizedBox(height: 14),
                      
                      // Tabla de Metadatos
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMetaRow('Folio de Renta:', widget.rental.id),
                            _buildMetaRow(
                              'Arrendador (Dueño):',
                              widget.rental.ownerName.isNotEmpty
                                  ? '${widget.rental.ownerName}\n(${widget.rental.ownerId})'
                                  : widget.rental.ownerId,
                            ),
                            _buildMetaRow(
                              'Arrendatario (Usuario):',
                              widget.rental.requesterName.isNotEmpty
                                  ? '${widget.rental.requesterName}\n(${widget.rental.requesterId})'
                                  : widget.rental.requesterId,
                            ),
                            if (widget.rental.deliveryLat != 0)
                              _buildMetaRow('Punto Encuentro:', '${widget.rental.deliveryLat.toStringAsFixed(5)}, ${widget.rental.deliveryLng.toStringAsFixed(5)}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Firmas
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  widget.rental.ownerName.isNotEmpty
                                      ? widget.rental.ownerName.toUpperCase()
                                      : 'ARRENDADOR',
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 8, color: const Color(0xFF64748B)),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                const Icon(Icons.fingerprint, color: Color(0xFF10B981), size: 30),
                                const SizedBox(height: 2),
                                Text('BIOMETRÍA OK', style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF047857), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 50, color: const Color(0xFFE2E8F0)),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  widget.rental.requesterName.isNotEmpty
                                      ? widget.rental.requesterName.toUpperCase()
                                      : 'ARRENDATARIO',
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 8, color: const Color(0xFF64748B)),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                const Icon(Icons.fingerprint, color: Color(0xFF10B981), size: 30),
                                const SizedBox(height: 2),
                                Text('BIOMETRÍA OK', style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF047857), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(thickness: 1),
                      const SizedBox(height: 8),
                      
                      Center(
                        child: Text(
                          'FIRMA CRIPTOGRÁFICA DIGITAL (SHA-256)',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: SelectableText(
                          widget.rental.contractHash,
                          style: GoogleFonts.shareTechMono(
                            fontSize: 10,
                            color: const Color(0xFF334155),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Botón de cierre
              Padding(
                padding: const EdgeInsets.all(14),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cerrar Documento', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClauseTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 11, color: const Color(0xFF334155)),
    );
  }

  Widget _buildClauseText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF475569), height: 1.4),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 10, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF334155), fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rental.contractHash.isEmpty) return const SizedBox.shrink();

    final isSuccess = _isValid == true;
    final isFailure = _isValid == false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess
            ? const Color(0xFFECFDF5)
            : isFailure
                ? const Color(0xFFFEF2F2)
                : AppColors.successBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : isFailure
                  ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                  : AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            isSuccess
                ? Icons.shield_outlined
                : isFailure
                    ? Icons.gpp_bad_outlined
                    : Icons.verified_outlined,
            color: isSuccess
                ? const Color(0xFF10B981)
                : isFailure
                    ? const Color(0xFFEF4444)
                    : AppColors.success,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            isSuccess
                ? '¡Firma e Integridad Criptográfica Verificada!'
                : isFailure
                    ? '¡ADVERTENCIA: Contrato Manipulado!'
                    : 'Contrato digital inmutable generado',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: isSuccess
                  ? const Color(0xFF047857)
                  : isFailure
                      ? const Color(0xFFB91C1C)
                      : AppColors.success,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Hash del contrato:',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate600, fontWeight: FontWeight.w500),
          ),
          SelectableText(
            widget.rental.contractHash,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.slate700,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (_recalculatedHash != null && _recalculatedHash != widget.rental.contractHash) ...[
            const SizedBox(height: 6),
            Text(
              'Hash recalculado (datos actuales en base de datos):',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFB91C1C), fontWeight: FontWeight.w500),
            ),
            SelectableText(
              _recalculatedHash!,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF991B1B),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),
          if (_verifying)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_error != null)
            Text(
              _error!,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w600),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.security, size: 14),
                  label: Text(
                    'Verificar Integridad',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _verify,
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF475569),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.article_outlined, size: 14),
                  label: Text(
                    'Ver Contrato',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showLegalContract(context),
                ),
              ],
            ),
          ],
          if (_isValid != null) ...[
            const SizedBox(height: 10),
            Text(
              isSuccess
                  ? '✓ Todos los datos coinciden exactamente con la firma SHA-256.'
                  : '✗ Alerta: Los datos del contrato han sido alterados.',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: isSuccess ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ]
        ],
      ),
    );
  }
}
