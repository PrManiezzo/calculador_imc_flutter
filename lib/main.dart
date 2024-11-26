import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart'; // Importar o pacote

void main() {
  runApp(const IMCCalculatorApp());
}

class IMCCalculatorApp extends StatelessWidget {
  const IMCCalculatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calculadora de IMC',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const IMCCalculatorScreen(),
    );
  }
}

class IMCCalculatorScreen extends StatefulWidget {
  const IMCCalculatorScreen({Key? key}) : super(key: key);

  @override
  _IMCCalculatorScreenState createState() => _IMCCalculatorScreenState();
}

class _IMCCalculatorScreenState extends State<IMCCalculatorScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String _result = '';
  String? _heightError; // Variável para armazenar erro de altura
  List<Map<String, dynamic>> _history = [];

  final MaskTextInputFormatter _heightFormatter = MaskTextInputFormatter(
    mask: '#.##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyData = prefs.getString('imcHistory');
    if (historyData != null) {
      setState(() {
        _history = List<Map<String, dynamic>>.from(json.decode(historyData));
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('imcHistory', json.encode(_history));
  }

  void _calculateIMC() {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    // Verificação da altura
    if (height == null || height <= 0 || height < 0.5 || height > 3) {
      setState(() {
        _heightError = 'Por favor, insira uma altura válida (entre 0.5m e 3m).';
        _result = ''; // Limpar o resultado anterior
      });
      return;
    } else {
      setState(() {
        _heightError = null; // Limpar erro de altura se válido
      });
    }

    if (weight == null || weight <= 0) {
      setState(() {
        _result = 'Por favor, insira um peso válido.';
      });
      return;
    }

    final imc = (weight / (height * height)).toStringAsFixed(2);
    final classification = _classifyIMC(double.parse(imc));

    setState(() {
      _result = 'Seu IMC é $imc ($classification)';
      _history.add({
        'weight': weight,
        'height': height,
        'imc': imc,
        'classification': classification,
        'date': DateTime.now().toString(),
      });
    });

    _saveHistory();
  }

  String _classifyIMC(double imc) {
    if (imc < 18.5) return 'Baixo peso';
    if (imc < 24.9) return 'Peso normal';
    if (imc < 29.9) return 'Sobrepeso';
    return 'Obesidade';
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('imcHistory');
    setState(() {
      _history.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de IMC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Peso (kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                _heightFormatter, // Aplicando a máscara
              ],
              decoration: InputDecoration(
                labelText: 'Altura (m)',
                border: const OutlineInputBorder(),
                errorText: _heightError, // Exibe erro se houver
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _calculateIMC,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Calcular'),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                _result,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Histórico',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: _history.isNotEmpty
                  ? ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                                'IMC: ${item['imc']} (${item['classification']})'),
                            subtitle: Text(
                                'Peso: ${item['weight']}kg, Altura: ${item['height']}m\nData: ${item['date']}'),
                          ),
                        );
                      },
                    )
                  : const Center(child: Text('Nenhum histórico ainda.')),
            ),
          ],
        ),
      ),
    );
  }
}
