import 'dart:convert';
import 'plantas_screen.dart';
import 'riegos_hoy_screen.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bugambilia',
      home: const PlantScreen(),
    );
  }
}

class PlantScreen extends StatefulWidget {
  const PlantScreen({super.key});

  @override
  State<PlantScreen> createState() => _PlantScreenState();
}

class _PlantScreenState extends State<PlantScreen> {

  // ==========================================
  // CONTROLADORES DE LOS CAMPOS
  // ==========================================

  final codeController = TextEditingController();
  final nameController = TextEditingController();
  final dateController = TextEditingController();

  // ==========================================
  // RECONOCIMIENTO DE VOZ
  // ==========================================

  final stt.SpeechToText speechToText = stt.SpeechToText();

  bool isListening = false;

  String text = '';

  // ==========================================
  // INICIAR MICRÓFONO
  // ==========================================

  Future<void> startListening() async {

    bool available = await speechToText.initialize();

    if (available) {

      setState(() {
        isListening = true;
      });

      await speechToText.listen(
        localeId: 'es-MX',

        onResult: (result) {

          setState(() {
            text = result.recognizedWords;
          });

        },
      );
    }
  }

  // ==========================================
  // DETENER MICRÓFONO
  // ==========================================

  Future<void> stopListening() async {

    await speechToText.stop();

    setState(() {
      isListening = false;
    });

    // Mandamos el texto a FastAPI
    if (text.isNotEmpty) {
      await sendTextToApi(text);
    }
  }

  Future<List<dynamic>> getPlants() async {
    final url = Uri.parse(
      'http://127.0.0.1:8000/plants/',
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Error al obtener las plantas: ${response.statusCode}',
      );
    }
  }

  // ==========================================
  // ENVIAR TEXTO A FASTAPI
  // ==========================================


  Future<void> sendTextToApi(String text) async {
    final url = Uri.parse(
      'http://127.0.0.1:8000/voice/',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('Respuesta de FastAPI:');
        print(data);

        // ==========================================
        // LLENAR LOS CAMPOS
        // ==========================================

        setState(() {
          codeController.text = data['code'] ?? '';
          nameController.text = data['name'] ?? '';
          dateController.text = data['date'] ?? '';
        });

      } else {
        print('Error HTTP: ${response.statusCode}');
        print(response.body);

        String mensaje = 'Error HTTP ${response.statusCode}';

        // Intentar obtener "detail" de FastAPI
        try {
          final data = jsonDecode(response.body);

          if (data['detail'] != null) {
            mensaje = data['detail'].toString();
          }
        } catch (e) {
          mensaje = response.body;
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }

    } catch (e) {
      print('Error conectando con FastAPI: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error conectando con FastAPI: $e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ==========================================
  // PANTALLA
  // ==========================================

  @override
  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF7F9F5),

    appBar: AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFFF7F9F5),
      foregroundColor: const Color(0xFF29452C),
      centerTitle: false,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bugambilia',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Registrar nueva planta',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    ),

    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // =========================================================
            // ENCABEZADO
            // =========================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F1E5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.local_florist,
                      size: 34,
                      color: Color(0xFF5B805B),
                    ),
                  ),

                  const SizedBox(width: 16),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nueva planta 🌱',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF29452C),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Registra los datos de tu planta '
                          'rápidamente.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // =========================================================
            // INFORMACIÓN DE LA PLANTA
            // =========================================================

            const Text(
              'Información de la planta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF29452C),
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                    color: Colors.black.withOpacity(0.05),
                  ),
                ],
              ),
              child: Column(
                children: [

                  TextField(
                    controller: codeController,
                    decoration: InputDecoration(
                      labelText: 'Código',
                      hintText: 'Ej. BUG-001',
                      prefixIcon: const Icon(
                        Icons.qr_code_2,
                        color: Color(0xFF5B805B),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F9F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Ej. Bugambilia rosa',
                      prefixIcon: const Icon(
                        Icons.local_florist_outlined,
                        color: Color(0xFF5B805B),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F9F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Fecha',
                      hintText: 'Fecha de registro',
                      prefixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        color: Color(0xFF5B805B),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F9F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // =========================================================
            // REGISTRO POR VOZ
            // =========================================================

            const Text(
              'Registro por voz',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF29452C),
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isListening
                      ? const Color(0xFFE57373)
                      : const Color(0xFFE5EAE3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isListening
                          ? const Color(0xFFFFEBEE)
                          : const Color(0xFFE7F1E5),
                    ),
                    child: Icon(
                      isListening
                          ? Icons.mic
                          : Icons.mic_none,
                      size: 42,
                      color: isListening
                          ? const Color(0xFFD32F2F)
                          : const Color(0xFF5B805B),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    isListening
                        ? 'Escuchando...'
                        : 'Registrar mediante voz',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isListening
                          ? const Color(0xFFD32F2F)
                          : const Color(0xFF29452C),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    isListening
                        ? 'Habla claramente para registrar la planta'
                        : 'Presiona el botón y describe la planta',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: 170,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (isListening) {
                          stopListening();
                        } else {
                          startListening();
                        }
                      },
                      icon: Icon(
                        isListening
                            ? Icons.stop
                            : Icons.mic,
                      ),
                      label: Text(
                        isListening
                            ? 'Detener'
                            : 'Comenzar',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isListening
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFF5B805B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =========================================================
            // TEXTO RECONOCIDO
            // =========================================================

            if (text.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6ED),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF5B805B),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Texto reconocido',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5B805B),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            text,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],

            // =========================================================
            // ACCIONES
            // =========================================================

            const Text(
              'Acciones rápidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF29452C),
              ),
            ),

            const SizedBox(height: 12),

            // Riegos de hoy
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const RiegosHoyScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.water_drop_outlined,
                ),
                label: const Text(
                  'Riegos de hoy',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF416B4A),
                  side: const BorderSide(
                    color: Color(0xFFB7CDB5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Ver plantas
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const PlantasScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.local_florist_outlined,
                ),
                label: const Text(
                  'Ver todas las plantas',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF416B4A),
                  side: const BorderSide(
                    color: Color(0xFFB7CDB5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  @override
  void dispose() {

    codeController.dispose();
    nameController.dispose();
    dateController.dispose();

    super.dispose();
  }
}