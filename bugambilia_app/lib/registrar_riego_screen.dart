import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegistrarRiegoScreen extends StatefulWidget {

  final int plantId;

  const RegistrarRiegoScreen({
    super.key,
    required this.plantId,
  });

  @override
  State<RegistrarRiegoScreen> createState() =>
      _RegistrarRiegoScreenState();
}

class _RegistrarRiegoScreenState
    extends State<RegistrarRiegoScreen> {

  final TextEditingController notesController =
      TextEditingController();

  bool food = false;
  bool pruning = false;
  bool guardando = false;

  Future<void> registrarRiego() async {

    setState(() {
      guardando = true;
    });

    final url = Uri.parse(
      'http://127.0.0.1:8000/watering/',
    );

    try {

      final response = await http.post(

        url,

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({

          'season_id': 1,

          'plant_id': widget.plantId,

          'days_to_water': 7,

          'watering_date': DateTime.now().toIso8601String(),

          'notes': notesController.text.isEmpty
              ? null
              : notesController.text,

          'food': food,

          'pruning': pruning,

          'is_dead': false,

          'death_cause': null,

        }),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Riego registrado correctamente 💧',
            ),
          ),
        );

        Navigator.pop(context);

      } else {

        print(
          'Error: ${response.statusCode}',
        );

        print(response.body);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al registrar riego: '
              '${response.body}',
            ),
          ),
        );
      }

    } catch (e) {

      print(
        'Error de conexión: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error de conexión: $e',
          ),
        ),
      );

    } finally {

      if (mounted) {

        setState(() {
          guardando = false;
        });

      }
    }
  }

  @override
  void dispose() {

    notesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Registrar riego',
        ),
      ),

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(
              'Información del riego',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            // =====================================
            // NOTAS
            // =====================================

            TextField(

              controller: notesController,

              maxLines: 4,

              decoration: const InputDecoration(

                labelText: 'Notas',

                hintText:
                    'Escribe alguna observación...',

                border: OutlineInputBorder(),

              ),
            ),

            const SizedBox(height: 25),

            // =====================================
            // ALIMENTO
            // =====================================

            SwitchListTile(

              title: const Text(
                '¿Se aplicó alimento?',
              ),

              subtitle: const Text(
                'Indica si la planta recibió alimento',
              ),

              value: food,

              onChanged: (value) {

                setState(() {
                  food = value;
                });

              },
            ),

            // =====================================
            // PODA
            // =====================================

            SwitchListTile(

              title: const Text(
                '¿Se realizó poda?',
              ),

              subtitle: const Text(
                'Indica si la planta fue podada',
              ),

              value: pruning,

              onChanged: (value) {

                setState(() {
                  pruning = value;
                });

              },
            ),

            const Spacer(),

            // =====================================
            // BOTÓN GUARDAR
            // =====================================

            SizedBox(

              width: double.infinity,

              child: ElevatedButton.icon(

                onPressed: guardando
                    ? null
                    : registrarRiego,

                icon: guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.water_drop,
                      ),

                label: Text(
                  guardando
                      ? 'Guardando...'
                      : 'Guardar riego',
                ),

              ),
            ),

          ],
        ),
      ),
    );
  }
}