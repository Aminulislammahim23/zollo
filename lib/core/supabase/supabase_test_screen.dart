import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseTestScreen extends StatefulWidget {
  const SupabaseTestScreen({super.key});

  @override
  State<SupabaseTestScreen> createState() => _SupabaseTestScreenState();
}

class _SupabaseTestScreenState extends State<SupabaseTestScreen> {
  bool _isLoading = true;
  String _statusMessage = 'Testing Supabase connection...';
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    try {
      // Try fetching from 'products' table
      final response = await Supabase.instance.client
          .from('products')
          .select()
          .limit(5);

      setState(() {
        _isLoading = false;
        _statusMessage = 'Successfully connected to Supabase! Found ${response.length} products.';
        _data = response;
      });
    } catch (e) {
      try {
        final session = Supabase.instance.client.auth.currentSession;
        setState(() {
          _isLoading = false;
          _statusMessage = 'Connected to Supabase client! Auth session: ${session != null ? 'Active' : 'None'}. Query note: $e';
        });
      } catch (authError) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Connection failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Connection Test'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : Icon(
                    _statusMessage.contains('Successfully') || _statusMessage.contains('Connected')
                        ? Icons.check_circle
                        : Icons.error,
                    color: _statusMessage.contains('Successfully') || _statusMessage.contains('Connected')
                        ? Colors.green
                        : Colors.red,
                    size: 64,
                  ),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _statusMessage = 'Retesting connection...';
                  _data = [];
                });
                _testConnection();
              },
              child: const Text('Retry Connection Test'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _data.length,
                itemBuilder: (context, index) {
                  final item = _data[index];
                  return Card(
                    child: ListTile(
                      title: Text(item['name'] ?? item['title'] ?? 'Item ${index + 1}'),
                      subtitle: Text('ID: ${item['id']}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
