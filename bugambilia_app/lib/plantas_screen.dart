import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'detalle_planta_screen.dart';

class PlantasScreen extends StatefulWidget {
  const PlantasScreen({super.key});

  @override
  State<PlantasScreen> createState() => _PlantasScreenState();
}

class _PlantasScreenState extends State<PlantasScreen> {

  List<dynamic> plantas = [];

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    obtenerPlantas();
  }

  Future<void> obtenerPlantas() async {

    final url = Uri.parse(
      'http://127.0.0.1:8000/plants/',
    );

    try {

      final response = await http.get(url);

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        setState(() {
          plantas = data;
          cargando = false;
        });

      } else {

        setState(() {
          cargando = false;
        });

        print('Error: ${response.statusCode}');
      }

    } catch (e) {

      setState(() {
        cargando = false;
      });

      print('Error al obtener plantas: $e');
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF6F8F6),

    appBar: AppBar(
      title: const Text(
        'Mis plantas',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: false,
      elevation: 0,
    ),

    body: cargando
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : plantas.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_florist_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'No hay plantas registradas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Cuando registres una planta aparecerá aquí.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: plantas.length,
                itemBuilder: (context, index) {
                  final planta = plantas[index];

                  final String nombre =
                      planta['name'] ?? 'Sin nombre';

                  final String codigo =
                      planta['code'] ?? 'Sin código';

                  final String? foto = planta['photo'];

                  final String? proximoRiego =
                      planta['next_watering_day'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,

                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DetallePlantaScreen(
                              code: codigo,
                            ),
                          ),
                        );
                      },

                      child: Padding(
                        padding: const EdgeInsets.all(12),

                        child: Row(
                          children: [

                            // FOTO / ICONO
                            Container(
                              width: 65,
                              height: 65,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(14),
                                color: Colors.green.shade50,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: foto != null &&
                                      foto.isNotEmpty
                                  ? Image.network(
                                      foto,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Icon(
                                          Icons.local_florist,
                                          size: 32,
                                          color: Colors.green.shade700,
                                        );
                                      },
                                    )
                                  : Icon(
                                      Icons.local_florist,
                                      size: 32,
                                      color: Colors.green.shade700,
                                    ),
                            ),

                            const SizedBox(width: 14),

                            // INFORMACIÓN
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    nombre,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  Text(
                                    'Código: $codigo',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  Row(
                                    children: [

                                      Icon(
                                        Icons.water_drop_outlined,
                                        size: 16,
                                        color: proximoRiego != null
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),

                                      const SizedBox(width: 5),

                                      Expanded(
                                        child: Text(
                                          proximoRiego != null &&
                                                  proximoRiego
                                                      .isNotEmpty
                                              ? 'Próximo riego: $proximoRiego'
                                              : 'Sin fecha de riego',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: proximoRiego != null
                                                ? Colors.grey.shade700
                                                : Colors.orange.shade700,
                                          ),
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // FLECHA
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade500,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
  );
}
}