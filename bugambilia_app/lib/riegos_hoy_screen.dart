import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class RiegosHoyScreen extends StatefulWidget {
  const RiegosHoyScreen({super.key});

  @override
  State<RiegosHoyScreen> createState() => _RiegosHoyScreenState();
}

class _RiegosHoyScreenState extends State<RiegosHoyScreen> {
  List<dynamic> riegos = [];
  bool cargando = true;
  String? mensaje;

  @override
  void initState() {
    super.initState();
    obtenerRiegosHoy();
  }

  Future<void> obtenerRiegosHoy() async {
    final url = Uri.parse(
      'http://127.0.0.1:8000/watering/today/',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          if (data is List) {
            riegos = data;
            mensaje = null;
          } else {
            riegos = [];
            mensaje = data['message'];
          }

          cargando = false;
        });
      } else {
        setState(() {
          cargando = false;
          mensaje = 'Error al obtener los riegos';
        });
      }
    } catch (e) {
      setState(() {
        cargando = false;
        mensaje = 'Error de conexión: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riegos de hoy'),
      ),

      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : riegos.isEmpty
              ? Center(
                  child: Text(
                    mensaje ?? 'No hay riegos programados para hoy',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: obtenerRiegosHoy,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: riegos.length,
                    itemBuilder: (context, index) {
                      final riego = riegos[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12,),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.water_drop),
                          ),
                          title: Text(
                            'Planta: ${riego['name'] ?? 'Sin nombre'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Riego programado: '
                            '${riego['next_watering_day'] ?? 'Sin fecha'}',
                          ),
                        ),

                    
                      ]
                   ),
                  ),
                );
              },
            ),
          ),
    );
  }
}