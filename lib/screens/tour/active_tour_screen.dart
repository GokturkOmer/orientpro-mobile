import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/tour.dart';
import '../../providers/tour_provider.dart';
import '../../core/theme/app_theme.dart';

class ActiveTourScreen extends ConsumerStatefulWidget {
  final int sessionId;
  const ActiveTourScreen({super.key, required this.sessionId});
  @override
  ConsumerState<ActiveTourScreen> createState() => _ActiveTourScreenState();
}

class _ActiveTourScreenState extends ConsumerState<ActiveTourScreen> {
  bool _isScanning = false;
  bool _isProcessing = false;
  ScanResult? _lastScanResult;
  TourSession? _session;
  String? _error;

  @override
  void initState() { super.initState(); _loadSession(); }

  Future<void> _loadSession() async {
    try {
      final session = await ref.read(sessionDetailProvider(widget.sessionId).future);
      if (mounted) setState(() => _session = session);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: ScadaColors.bg,
        appBar: AppBar(backgroundColor: ScadaColors.surface, title: const Text('Tur')),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error, size: 48, color: ScadaColors.red),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: ScadaColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () { setState(() => _error = null); _loadSession(); }, child: const Text('Tekrar Dene')),
        ])),
      );
    }

    if (_session == null) {
      return Scaffold(
        backgroundColor: ScadaColors.bg,
        appBar: AppBar(backgroundColor: ScadaColors.surface, title: const Text('Yukleniyor...')),
        body: const Center(child: CircularProgressIndicator(color: ScadaColors.cyan)),
      );
    }

    final s = _session!;
    final progress = s.totalCheckpoints > 0 ? s.scannedCheckpoints / s.totalCheckpoints : 0.0;

    return Scaffold(
      backgroundColor: ScadaColors.bg,
      appBar: AppBar(
        backgroundColor: ScadaColors.surface,
        title: Text(s.routeName, style: const TextStyle(fontSize: 14, color: ScadaColors.textPrimary)),
        actions: [
          if (s.status == 'active')
            PopupMenuButton<String>(
              color: ScadaColors.surface,
              onSelected: (v) async {
                if (v == 'complete') await _completeTour();
                if (v == 'cancel') await _cancelTour();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'complete', child: Row(children: [Icon(Icons.check_circle, color: ScadaColors.green, size: 16), SizedBox(width: 8), Text('Tamamla', style: TextStyle(color: ScadaColors.textPrimary))])),
                const PopupMenuItem(value: 'cancel', child: Row(children: [Icon(Icons.cancel, color: ScadaColors.red, size: 16), SizedBox(width: 8), Text('Iptal Et', style: TextStyle(color: ScadaColors.textPrimary))])),
              ],
            ),
        ],
      ),
      body: Column(children: [
        // Progress
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: ScadaColors.surface,
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${s.scannedCheckpoints}/${s.totalCheckpoints} nokta', style: const TextStyle(fontWeight: FontWeight.w600, color: ScadaColors.textPrimary, fontSize: 13)),
              if (s.skippedCheckpoints > 0)
                Text('${s.skippedCheckpoints} atlandi', style: const TextStyle(color: ScadaColors.amber, fontSize: 11)),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.w700, color: ScadaColors.cyan, fontSize: 13)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress, minHeight: 6,
                backgroundColor: ScadaColors.border,
                color: ScadaColors.cyan,
              ),
            ),
          ]),
        ),

        if (_lastScanResult != null) _buildScanResultCard(_lastScanResult!),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: s.checkpoints.length,
            itemBuilder: (ctx, i) => _checkpointTile(s.checkpoints[i]),
          ),
        ),
      ]),
      floatingActionButton: s.status == 'active' ? FloatingActionButton.extended(
        onPressed: _isProcessing ? null : () => setState(() => _isScanning = true),
        backgroundColor: ScadaColors.cyan,
        foregroundColor: ScadaColors.bg,
        icon: const Icon(Icons.qr_code_scanner),
        label: Text(_isScanning ? 'Taraniyor...' : 'QR Tara', style: const TextStyle(fontWeight: FontWeight.w700)),
      ) : null,
      bottomSheet: _isScanning ? _buildScanner() : null,
    );
  }

  Widget _buildScanner() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: ScadaColors.borderBright),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
      ),
      child: Column(children: [
        Container(margin: const EdgeInsets.symmetric(vertical: 8), width: 40, height: 4, decoration: BoxDecoration(color: ScadaColors.borderBright, borderRadius: BorderRadius.circular(2))),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Padding(padding: EdgeInsets.only(left: 16), child: Text('QR Kodu Okutun', style: TextStyle(color: ScadaColors.cyan, fontWeight: FontWeight.w600, fontSize: 13))),
          IconButton(icon: const Icon(Icons.close, color: ScadaColors.textDim), onPressed: () => setState(() => _isScanning = false)),
        ]),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MobileScanner(
                onDetect: (capture) {
                  if (_isProcessing) return;
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty && barcodes.first.rawValue != null) _onQrScanned(barcodes.first.rawValue!);
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Future<void> _onQrScanned(String qrCode) async {
    if (_isProcessing || _session == null) return;
    setState(() { _isProcessing = true; _isScanning = false; });
    try {
      final result = await TourService.scanCheckpoint(widget.sessionId, qrCode);
      setState(() { _lastScanResult = result; _isProcessing = false; });
      if (result.orderWarning != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.orderWarning!), backgroundColor: ScadaColors.amber));
      }
      if (result.autoCompleted && mounted) _showCompletionDialog();
      await _loadSession();
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tarama hatasi: $e'), backgroundColor: ScadaColors.red));
    }
  }

  Widget _buildScanResultCard(ScanResult result) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ScadaColors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ScadaColors.green.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.check_circle, color: ScadaColors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(result.checkpointName, style: const TextStyle(fontWeight: FontWeight.w600, color: ScadaColors.green, fontSize: 13))),
          Text('${result.remaining} kaldi', style: const TextStyle(fontSize: 11, color: ScadaColors.textDim)),
        ]),
        if (result.instructions != null) ...[
          const SizedBox(height: 6),
          Text(result.instructions!, style: const TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
        ],
        if (result.checkItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...result.checkItems.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(children: [
              Icon(Icons.check_box_outline_blank, size: 14, color: ScadaColors.textDim),
              const SizedBox(width: 6),
              Expanded(child: Text(item, style: const TextStyle(fontSize: 11, color: ScadaColors.textSecondary))),
            ]),
          )),
        ],
      ]),
    );
  }

  Widget _checkpointTile(TourCheckpoint cp) {
    Color statusColor;
    IconData statusIcon;
    switch (cp.scanStatus) {
      case 'ok': statusColor = ScadaColors.green; statusIcon = Icons.check_circle; break;
      case 'skipped': statusColor = ScadaColors.amber; statusIcon = Icons.skip_next; break;
      case 'issue': statusColor = ScadaColors.red; statusIcon = Icons.warning; break;
      default: statusColor = ScadaColors.textDim; statusIcon = Icons.radio_button_unchecked;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cp.scanned ? statusColor.withOpacity(0.06) : ScadaColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cp.scanned ? statusColor.withOpacity(0.3) : ScadaColors.border),
      ),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: statusColor.withOpacity(0.15), shape: BoxShape.circle),
          child: cp.scanned
            ? Icon(statusIcon, size: 14, color: statusColor)
            : Center(child: Text('${cp.orderIndex}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cp.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cp.scanned ? statusColor : ScadaColors.textPrimary)),
          if (cp.location != null) Text(cp.location!, style: const TextStyle(fontSize: 10, color: ScadaColors.textDim)),
        ])),
        if (cp.photoRequired) Icon(Icons.camera_alt, size: 13, color: ScadaColors.amber.withOpacity(0.5)),
        if (!cp.scanned && _session?.status == 'active')
          IconButton(icon: const Icon(Icons.skip_next, size: 16), color: ScadaColors.amber, tooltip: 'Atla', onPressed: () => _showSkipDialog(cp)),
      ]),
    );
  }

  void _showSkipDialog(TourCheckpoint cp) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ScadaColors.surface,
        title: Text('${cp.name} atla', style: const TextStyle(color: ScadaColors.textPrimary, fontSize: 14)),
        content: TextField(controller: controller, style: const TextStyle(color: ScadaColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Atlama sebebi (zorunlu)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgec', style: TextStyle(color: ScadaColors.textDim))),
          ElevatedButton(onPressed: () async {
            if (controller.text.isEmpty) return;
            Navigator.pop(ctx);
            try { await TourService.skipCheckpoint(widget.sessionId, cp.id, controller.text); await _loadSession(); }
            catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: ScadaColors.red)); }
          }, child: const Text('Atla')),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: ScadaColors.surface,
      icon: const Icon(Icons.celebration, size: 48, color: ScadaColors.green),
      title: const Text('Tur Tamamlandi!', style: TextStyle(color: ScadaColors.green)),
      content: const Text('Tum kontrol noktalari tarandi.', style: TextStyle(color: ScadaColors.textSecondary)),
      actions: [ElevatedButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('Tamam'))],
    ));
  }

  Future<void> _completeTour() async {
    try {
      final result = await TourService.completeSession(widget.sessionId);
      if (mounted) showDialog(context: context, builder: (ctx) => AlertDialog(
        backgroundColor: ScadaColors.surface,
        icon: const Icon(Icons.check_circle, size: 48, color: ScadaColors.green),
        title: const Text('Tur Tamamlandi', style: TextStyle(color: ScadaColors.green)),
        content: Text('Taranan: ${result['scanned']}/${result['total']}\nAtlanan: ${result['skipped']}\nTamamlanma: %${result['completion_rate']}',
          style: const TextStyle(color: ScadaColors.textSecondary)),
        actions: [ElevatedButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('Tamam'))],
      ));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: ScadaColors.red)); }
  }

  Future<void> _cancelTour() async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: ScadaColors.surface,
      title: const Text('Turu iptal et?', style: TextStyle(color: ScadaColors.textPrimary)),
      content: const Text('Bu islem geri alinamaz.', style: TextStyle(color: ScadaColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgec', style: TextStyle(color: ScadaColors.textDim))),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: ScadaColors.red.withOpacity(0.15), foregroundColor: ScadaColors.red),
          onPressed: () => Navigator.pop(ctx, true), child: const Text('Iptal Et')),
      ],
    ));
    if (confirmed == true) { await TourService.cancelSession(widget.sessionId); if (mounted) Navigator.pop(context); }
  }
}
