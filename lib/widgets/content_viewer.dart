import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/training.dart';
import '../core/config/api_config.dart';
import '../core/theme/app_theme.dart';

/// Egitim icerigi goruntuleyici.
/// Metin icerikleri dogrudan gosterir, dosya icerikleri icin
/// dosya adi + boyut + indirme butonu gosterir.
class ContentViewer extends StatelessWidget {
  final ModuleContent content;
  const ContentViewer({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    // Metin icerigi
    if (content.body != null && content.body!.isNotEmpty) {
      return MarkdownBody(
        data: content.body!,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(fontSize: 13, color: ScadaColors.textPrimary, height: 1.6),
          h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ScadaColors.textPrimary),
          h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary),
          h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ScadaColors.textPrimary),
          listBullet: const TextStyle(fontSize: 13, color: ScadaColors.textSecondary),
          code: TextStyle(fontSize: 12, color: ScadaColors.cyan, backgroundColor: ScadaColors.surface),
        ),
      );
    }

    // Dosya icerigi (PDF, resim vb.)
    if (content.mediaUrl != null && content.mediaUrl!.isNotEmpty) {
      return _buildFileCard(context);
    }

    return const Text(
      'Icerik bulunamadi',
      style: TextStyle(fontSize: 12, color: ScadaColors.textDim, fontStyle: FontStyle.italic),
    );
  }

  Widget _buildFileCard(BuildContext context) {
    final fileName = content.fileName ?? content.title;
    final fileSize = content.fileSize;
    final sizeText = fileSize > 0 ? _formatFileSize(fileSize) : '';

    IconData fileIcon;
    Color iconColor;
    switch (content.contentType) {
      case 'pdf':
        fileIcon = Icons.picture_as_pdf;
        iconColor = Colors.redAccent;
        break;
      case 'image':
        fileIcon = Icons.image;
        iconColor = ScadaColors.cyan;
        break;
      case 'video':
        fileIcon = Icons.videocam;
        iconColor = ScadaColors.purple;
        break;
      default:
        fileIcon = Icons.insert_drive_file;
        iconColor = ScadaColors.amber;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(fileIcon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ScadaColors.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (sizeText.isNotEmpty)
                Text(sizeText, style: const TextStyle(fontSize: 11, color: ScadaColors.textDim)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _downloadFile(context),
          icon: const Icon(Icons.download, size: 16),
          label: const Text('Indir'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ScadaColors.cyan.withValues(alpha: 0.15),
            foregroundColor: ScadaColors.cyan,
            side: BorderSide(color: ScadaColors.cyan.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }

  Future<void> _downloadFile(BuildContext context) async {
    final mediaUrl = content.mediaUrl!;
    // mediaUrl format: bucket/object_name — download endpoint'e yonlendir
    final downloadUrl = '${ApiConfig.webUrl.replaceAll('/api/v1', '')}/api/v1/files/download/$mediaUrl';
    final uri = Uri.parse(downloadUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya acilamadi: $e'), backgroundColor: ScadaColors.red),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
