
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HistorialRiegosScreen extends StatefulWidget {
  final int plantId;
  final String plantName;

  const HistorialRiegosScreen({
    super.key,
    required this.plantId,
    required this.plantName,
  });

  @override
  State<HistorialRiegosScreen> createState() =>
      _HistorialRiegosScreenState();
}

class _HistorialRiegosScreenState
    extends State<HistorialRiegosScreen> {
  List<dynamic> riegos = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    obtenerRiegos();
  }

  Future<void> obtenerRiegos() async {
    final url = Uri.parse(
      'http://127.0.0.1:8000/watering/${widget.plantId}/',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          setState(() {
            riegos = data;
            cargando = false;
          });
        } else {
          setState(() {
            error = data['message'] ??
                'Respuesta inesperada del servidor';
            cargando = false;
          });
        }
      } else {
        setState(() {
          error = 'Error al consultar los riegos: '
              '${response.statusCode}';
          cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'No se pudo conectar con el servidor';
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riegos de ${widget.plantName}'),
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  child: Text(error!),
                )
              : riegos.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.water_drop_outlined,
                            size: 65,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No hay riegos registrados '
                            'para esta planta',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 17),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: obtenerRiegos,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: riegos.length,
                        itemBuilder: (context, index) {
                          final riego = riegos[index];

                          return Card(
                            margin: const EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.water_drop),
                              ),
                              title: Text(
                                'Fecha de riego: ${riego['watering_date']}',
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (riego['notes'] != null &&
                                      riego['notes']
                                          .toString()
                                          .isNotEmpty)
                                    Text(
                                      'Notas: ${riego['notes']}',
                                    ),
                                  Text(
                                    'Abono: '
                                    '${riego['food'] == true ? 'Sí' : 'No'}',
                                  ),
                                  Text(
                                    'Poda: '
                                    '${riego['pruning'] == true ? 'Sí' : 'No'}',
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}