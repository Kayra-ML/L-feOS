import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';

/// Backend API adresini (LAN IP) girip test etmek için ayarlar ekranı.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _ctrl;
  String? _status;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: context.read<AppSettings>().baseUrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await context.read<AppSettings>().setBaseUrl(_ctrl.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydedildi.')),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _checking = true;
      _status = null;
    });
    await context.read<AppSettings>().setBaseUrl(_ctrl.text);
    try {
      final api = ApiClient(context.read<AppSettings>());
      await api.healthCheck();
      setState(() => _status = 'ok');
    } catch (e) {
      setState(() => _status = e.toString());
    } finally {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'Backend Adresi',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Telefon ile bilgisayarın aynı Wi-Fi ağında olmalı. Bilgisayarındaki '
            'komut istemine "ipconfig" yazarak LAN IP\'ni bulabilirsin (örn. 192.168.1.20). '
            'Backend "uvicorn backend.api:app --host 0.0.0.0 --port 8000" ile çalışıyor olmalı.',
            style: TextStyle(color: AppColors.textDim, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'API Base URL',
              hintText: 'http://192.168.1.20:8000',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _checking ? null : _testConnection,
                  child: _checking
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Bağlantıyı Test Et'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
          if (_status != null) ...[
            const SizedBox(height: 16),
            if (_status == 'ok')
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                  SizedBox(width: 8),
                  Text('Bağlantı başarılı!', style: TextStyle(color: AppColors.success)),
                ],
              )
            else
              Text(
                'Bağlantı başarısız: $_status',
                style: const TextStyle(color: AppColors.danger, fontSize: 12.5),
              ),
          ],
        ],
      ),
    );
  }
}
