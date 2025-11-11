import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/password_model.dart';
import '../database/database_helper.dart';
import 'add_edit_password_screen.dart';

class PasswordDetailScreen extends StatefulWidget {
  final int passwordId;

  const PasswordDetailScreen({super.key, required this.passwordId});

  @override
  State<PasswordDetailScreen> createState() => _PasswordDetailScreenState();
}

class _PasswordDetailScreenState extends State<PasswordDetailScreen> {
  final _dbHelper = DatabaseHelper.instance;
  PasswordModel? _password;
  bool _isLoading = true;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadPassword();
  }

  Future<void> _loadPassword() async {
    final password = await _dbHelper.getPassword(widget.passwordId);
    setState(() {
      _password = password;
      _isLoading = false;
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label disalin ke clipboard')),
    );
  }

  Future<void> _deletePassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Password'),
        content: const Text('Apakah Anda yakin ingin menghapus password ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && _password != null) {
      await _dbHelper.deletePassword(_password!.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil dihapus')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Password'),
        actions: [
          if (_password != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddEditPasswordScreen(password: _password),
                  ),
                );
                _loadPassword();
              },
            ),
          if (_password != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deletePassword,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _password == null
              ? const Center(child: Text('Password tidak ditemukan'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blue[100],
                                    radius: 30,
                                    child: Icon(
                                      Icons.lock,
                                      color: Colors.blue[700],
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      _password!.title,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailCard(
                        'Username/Email',
                        _password!.username,
                        Icons.person,
                      ),
                      const SizedBox(height: 12),
                      _buildPasswordCard(),
                      if (_password!.website != null &&
                          _password!.website!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildDetailCard(
                          'Website/URL',
                          _password!.website!,
                          Icons.link,
                        ),
                      ],
                      if (_password!.notes != null &&
                          _password!.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildDetailCard(
                          'Catatan',
                          _password!.notes!,
                          Icons.note,
                          isMultiline: true,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        'Dibuat',
                        DateFormat('dd MMMM yyyy, HH:mm')
                            .format(_password!.createdAt),
                        Icons.calendar_today,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        'Diperbarui',
                        DateFormat('dd MMMM yyyy, HH:mm')
                            .format(_password!.updatedAt),
                        Icons.update,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailCard(
    String label,
    String value,
    IconData icon, {
    bool isMultiline = false,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: isMultiline ? null : 2,
                    overflow: isMultiline ? null : TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyToClipboard(value, label),
                  tooltip: 'Salin $label',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isPasswordVisible
                        ? _password!.password
                        : '•' * _password!.password.length,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _isPasswordVisible = !_isPasswordVisible);
                  },
                  tooltip: _isPasswordVisible
                      ? 'Sembunyikan Password'
                      : 'Tampilkan Password',
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () =>
                      _copyToClipboard(_password!.password, 'Password'),
                  tooltip: 'Salin Password',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

