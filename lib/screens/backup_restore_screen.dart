import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/backup_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isProcessing = false;
  String? _lastSavedPath;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _exportToFile() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        // Pada Android modern (scoped storage), tulis langsung ke Downloads
        // seringkali tidak terlihat. Gunakan share sheet agar user memilih lokasi/app.
        await _exportAndShare();
        return;
      }

      final backupJson = await BackupService.instance.exportBackup();
      final bytes = Uint8List.fromList(utf8.encode(backupJson));
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('.', '')
          .replaceAll('-', '');
      final filename = 'vault_backup_$ts.json';

      final savedPath = await FileSaver.instance.saveFile(
        name: filename, // sertakan .json di name
        bytes: bytes,
        mimeType: MimeType.json,
      );
      _lastSavedPath = savedPath.isEmpty ? null : savedPath;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Backup disimpan: ${_lastSavedPath ?? "Downloads"}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan backup: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _exportAndShare() async {
    setState(() => _isProcessing = true);
    try {
      final backupJson = await BackupService.instance.exportBackup();
      final bytes = Uint8List.fromList(utf8.encode(backupJson));
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('.', '')
          .replaceAll('-', '');
      final filename = 'vault_backup_$ts.json';

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$filename';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      final xfile = XFile(
        file.path,
        name: filename,
        mimeType: 'application/json',
      );
      await Share.shareXFiles([xfile], text: 'Backup Password Vault');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal share backup: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _importFromFile() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan PIN yang sesuai dengan backup')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Restore'),
        content: const Text(
          'Restore akan menggantikan seluruh data password dan PIN saat ini.\n'
          'Pastikan backup berasal dari sumber tepercaya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Lanjut Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: kIsWeb, // on web we need bytes
      );
      if (result == null || result.files.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pemilihan file dibatalkan')),
        );
        return;
      }

      String content;
      final file = result.files.first;
      if (kIsWeb) {
        final bytes = file.bytes;
        if (bytes == null) {
          throw 'File kosong';
        }
        content = utf8.decode(bytes);
      } else {
        final path = file.path;
        if (path == null) {
          throw 'Path file tidak ditemukan';
        }
        content = await File(path).readAsString();
      }

      await BackupService.instance.importBackup(content, pin: pin);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore berhasil. Masuk ulang dengan PIN Anda.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal restore: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panduan',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _guideItem('Backup diekspor sebagai file JSON berisi data terenkripsi + hash & salt PIN.'),
                    _guideItem('Simpan file di lokasi aman (mis. drive terenkripsi, password manager lain).'),
                    _guideItem('Untuk restore, pilih file backup dan masukkan PIN yang benar.'),
                    _guideItem('Proses restore akan menggantikan seluruh data lokal saat ini.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              decoration: const InputDecoration(
                labelText: 'PIN untuk Restore',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                helperText: 'Gunakan PIN yang sama saat backup dibuat',
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _exportToFile,
                  icon: const Icon(Icons.file_download),
                  label: const Text('Export ke File'),
                ),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _exportAndShare,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Share Backup'),
                ),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _importFromFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Restore dari File'),
                ),
              ],
            ),
            if (_isProcessing) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _guideItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

