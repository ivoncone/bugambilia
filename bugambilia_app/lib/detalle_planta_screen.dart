import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'historial_riegos_screen.dart';
import 'registrar_riego_screen.dart';


class DetallePlantaScreen extends StatefulWidget {

  final String code;

  const DetallePlantaScreen({
    super.key,
    required this.code,
  });

  @override
  State<DetallePlantaScreen> createState() =>
      _DetallePlantaScreenState();
}

class _DetallePlantaScreenState
    extends State<DetallePlantaScreen> {

  Map<String, dynamic>? planta;

  bool cargando = true;

  bool subiendoFoto = false;

  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    obtenerPlanta();
  }

  Future<void> editarProximoRiego() async {
    final DateTime hoy = DateTime.now();

    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: hoy,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: DateTime(hoy.year + 10),
      helpText: 'Selecciona el próximo riego',
      cancelText: 'Cancelar',
      confirmText: 'Guardar',
    );

    if (fechaSeleccionada == null || !mounted) return;

    final fecha = [
      fechaSeleccionada.year.toString().padLeft(4, '0'),
      fechaSeleccionada.month.toString().padLeft(2, '0'),
      fechaSeleccionada.day.toString().padLeft(2, '0'),
    ].join('-');

  debugPrint('Fecha enviada al backend: $fecha');

    try {
      final response = await http.put(
        Uri.parse(
          'http://127.0.0.1:8000/plants/${planta!['id']}',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'next_watering_day': fecha,
        }),
      );
      debugPrint('HTTP: ${response.statusCode}');
      debugPrint('Respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          planta = {
            ...planta!,
            'next_watering_day': data['next_watering_day'],
          };
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Próximo riego actualizado'),
          ),
        );
      } else {
        throw Exception(
          'Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar la fecha: $e'),
        ),
      );
    }
  }

  Future<void> editarFrecuenciaRiego() async {
  final TextEditingController controlador =
      TextEditingController(
    text: '${planta!['days_to_water'] ?? 0}',
  );

  final int? dias = await showDialog<int>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Frecuencia de riego'),
        content: TextField(
          controller: controlador,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Cada cuántos días',
            suffixText: 'días',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final int? valor =
                  int.tryParse(controlador.text.trim());

              if (valor == null || valor < 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Introduce un número de días válido.',
                    ),
                  ),
                );
                return;
              }

              Navigator.pop(context, valor);
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );

  controlador.dispose();

  if (dias == null) return;

  try {
    final response = await http.put(
      Uri.parse(
        'http://127.0.0.1:8000/plants/frequency/${planta!['id']}',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'days_to_water': dias,
      }),
    );

    debugPrint('HTTP frecuencia: ${response.statusCode}');
    debugPrint('Respuesta: ${response.body}');

    if (response.statusCode == 200) {
      setState(() {
        planta!['days_to_water'] = dias;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Frecuencia de riego actualizada correctamente.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al actualizar la frecuencia: ${response.body}',
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint('Error al actualizar frecuencia: $e');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No se pudo conectar con el servidor.',
        ),
      ),
    );
  }
}

  Future<void> obtenerPlanta() async {

    final url = Uri.parse(
      'http://127.0.0.1:8000/plants/${widget.code}',
    );

    try {

      final response = await http.get(url);

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        setState(() {
          planta = data;
          cargando = false;
        });

      } else {

        setState(() {
          cargando = false;
        });

        print(
          'Error: ${response.statusCode}',
        );
      }

    } catch (e) {

      setState(() {
        cargando = false;
      });

      print(
        'Error al obtener planta: $e',
      );
    }
  }

  Future<void> seleccionarFoto() async {
    try {
      final XFile? imagen = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (imagen == null) return;

      setState(() {
        subiendoFoto = true;
      });

      final bytes = await imagen.readAsBytes();

      final plantId = planta?['id'];

      if (plantId == null) {
        throw Exception('No se encontró el ID de la planta');
      }

      final url = Uri.parse(
        'http://127.0.0.1:8000/plants/$plantId/photo',
      );

      final request = http.MultipartRequest('PUT', url);

      final extension = imagen.name.split('.').last.toLowerCase();

      MediaType tipoMime;

      switch (extension) {
        case 'jpg':
        case 'jpeg':
          tipoMime = MediaType('image', 'jpeg');
          break;
        case 'webp':
          tipoMime = MediaType('image', 'webp');
          break;
        case 'png':
          tipoMime = MediaType('image', 'png');
          break;
        default:
          throw Exception('Formato de imagen no permitido: $extension');
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: imagen.name,
          contentType: tipoMime,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint('Código HTTP: ${response.statusCode}');
      debugPrint('Respuesta API: $responseBody');

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        if (!mounted) return;

        // Actualizar directamente la foto con la URL de Cloudinary.
        final data = jsonDecode(responseBody);

        setState(() {
          planta!['photo'] = data['photo'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto subida correctamente'),
          ),
        );
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: $responseBody',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error subiendo foto: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error subiendo foto: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          subiendoFoto = false;
        });
      }
    }
  }

  Future<void> _confirmarEliminar() async {
  if (planta == null || planta!['id'] == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se encontró el ID de la planta'),
      ),
    );
    return;
  }

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Eliminar planta'),
        content: Text(
          '¿Estás seguro de que deseas eliminar '
          '"${planta!['name'] ?? 'esta planta'}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    },
  );

  if (confirmar != true || !mounted) {
    return;
  }

  final plantId = planta!['id'];

  try {
    final url = Uri.parse(
      'http://127.0.0.1:8000/plants/$plantId',
    );

    debugPrint('Eliminando planta: $url');

    final response = await http.delete(url);

    debugPrint('HTTP DELETE: ${response.statusCode}');
    debugPrint('Respuesta DELETE: ${response.body}');

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Planta eliminada correctamente'),
        ),
      );

      // Regresar a la pantalla anterior.
      Navigator.pop(context, true);

    } else {
      throw Exception(
        'Error ${response.statusCode}: ${response.body}',
      );
    }
  } catch (e) {
    debugPrint('Error eliminando planta: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No se pudo eliminar la planta: $e'),
      ),
    );
  }
}


  @override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return Scaffold(
    backgroundColor: const Color(0xFFF7F9F7),

    appBar: AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: const Text(
        'Detalle de planta',
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
          ),
          tooltip: 'Eliminar planta',
          onPressed: () => _confirmarEliminar(),
        ),
      ],
    ),

    body: cargando
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : planta == null
            ? const Center(
                child: Text(
                  'No se encontró la planta',
                  style: TextStyle(fontSize: 16),
                ),
              )
            : RefreshIndicator(
                onRefresh: obtenerPlanta,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    32,
                  ),
                  children: [

                    // =====================================================
                    // FOTO
                    // =====================================================

                    _buildFoto(),

                    const SizedBox(height: 16),

                    // =====================================================
                    // ENCABEZADO
                    // =====================================================

                    _buildEncabezado(),

                    const SizedBox(height: 16),

                    // =====================================================
                    // PRÓXIMO RIEGO
                    // =====================================================

                    _buildProximoRiego(),

                    const SizedBox(height: 16),

                    // =====================================================
                    // ACCIONES DE RIEGO
                    // =====================================================

                    _buildAccionesRiego(),

                    const SizedBox(height: 16),

                    // =====================================================
                    // INFORMACIÓN
                    // =====================================================

                    _buildInformacion(),

                    const SizedBox(height: 16),

                    // =====================================================
                    // CUIDADOS
                    // =====================================================

                    _buildCuidados(),

                    const SizedBox(height: 16),

                    // =====================================================
                    // CAUSA DE MUERTE
                    // =====================================================

                    if (planta!['death_cause'] != null &&
                        planta!['death_cause']
                            .toString()
                            .isNotEmpty)
                      _buildCausaMuerte(),

                  ],
                ),
              ),
  );
}


// ===========================================================================
// FOTO
// ===========================================================================

Widget _buildFoto() {
  final photo = planta!['photo'];

  return Container(
    height: 250,
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      fit: StackFit.expand,
      children: [

        // FOTO
        if (photo != null &&
            photo.toString().isNotEmpty)
          Image.network(
            photo.toString(),
            fit: BoxFit.cover,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return _buildPlaceholderFoto();
            },
          )
        else
          _buildPlaceholderFoto(),

        // DEGRADADO INFERIOR
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 90,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.45),
                ],
              ),
            ),
          ),
        ),

        // BOTÓN CAMBIAR FOTO
        Positioned(
          right: 12,
          bottom: 12,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            elevation: 3,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: subiendoFoto
                  ? null
                  : seleccionarFoto,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: subiendoFoto
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.black87,
                      ),
              ),
            ),
          ),
        ),

      ],
    ),
  );
}


// ===========================================================================
// PLACEHOLDER DE FOTO
// ===========================================================================

Widget _buildPlaceholderFoto() {
  return Container(
    color: const Color(0xFFE8F1E8),
    child: const Center(
      child: Icon(
        Icons.local_florist,
        size: 90,
        color: Color(0xFF6B8E6B),
      ),
    ),
  );
}


// ===========================================================================
// ENCABEZADO
// ===========================================================================

Widget _buildEncabezado() {
  final nombre = planta!['name'] ?? 'Sin nombre';
  final codigo = planta!['code'] ?? '';

  final activa = planta!['active'] == true;

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ICONO
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F3E8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.local_florist,
            color: Color(0xFF4F7D4F),
            size: 28,
          ),
        ),

        const SizedBox(width: 14),

        // NOMBRE + CÓDIGO
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Text(
                nombre.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Código: $codigo',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 10),

              // ESTADO
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: activa
                      ? const Color(0xFFE6F4EA)
                      : const Color(0xFFFDECEC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: activa
                            ? Colors.green
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      activa ? 'Activa' : 'Inactiva',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: activa
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),

                  ],
                ),
              ),

            ],
          ),
        ),

      ],
    ),
  );
}


// ===========================================================================
// PRÓXIMO RIEGO
// ===========================================================================

Widget _buildProximoRiego() {
  final valor = planta!['next_watering_day'];

  final sinFecha = valor == null ||
      valor.toString().isEmpty;

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF5FC),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: const Color(0xFFD3EAF7),
      ),
    ),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        Row(
          children: [

            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.water_drop,
                color: Colors.blue,
              ),
            ),

            const SizedBox(width: 12),

            const Expanded(
              child: Text(
                'PRÓXIMO RIEGO',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Colors.black54,
                ),
              ),
            ),

            IconButton(
              onPressed: editarProximoRiego,
              icon: const Icon(
                Icons.edit_calendar_outlined,
              ),
              tooltip: 'Editar fecha',
            ),

          ],
        ),

        const SizedBox(height: 14),

        Text(
          sinFecha
              ? 'Sin fecha programada'
              : valor.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: sinFecha
                ? Colors.grey.shade600
                : Colors.black87,
          ),
        ),

        if (sinFecha)
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Text(
              'Toca el calendario para programar el próximo riego',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),

      ],
    ),
  );
}


// ===========================================================================
// BOTONES DE RIEGO
// ===========================================================================

Widget _buildAccionesRiego() {
  return Row(
    children: [

      // REGISTRAR
      Expanded(
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RegistrarRiegoScreen(
                    plantId: planta!['id'],
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.water_drop_outlined,
            ),
            label: const Text(
              'Registrar riego',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF4F8FC5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),

      const SizedBox(width: 10),

      // HISTORIAL
      Expanded(
        child: SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HistorialRiegosScreen(
                    plantId: planta!['id'],
                    plantName:
                        planta!['name'] ?? 'Planta',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.history,
            ),
            label: const Text(
              'Historial',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  const Color(0xFF4F8FC5),
              side: const BorderSide(
                color: Color(0xFF4F8FC5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),

    ],
  );
}


// ===========================================================================
// INFORMACIÓN
// ===========================================================================

Widget _buildInformacion() {
  return _buildSeccion(
    titulo: 'INFORMACIÓN',
    icono: Icons.info_outline,
    children: [

      _buildFilaDato(
        icono: Icons.calendar_today_outlined,
        titulo: 'Fecha de plantación',
        valor: planta!['date']?.toString() ??
            'Sin fecha',
      ),

      _buildSeparador(),

      _buildFilaDato(
        icono: Icons.cake_outlined,
        titulo: 'Edad',
        valor:
            '${planta!['age'] ?? 0} años',
      ),

      _buildSeparador(),

      _buildFilaDato(
        icono: Icons.timelapse_outlined,
        titulo: 'Días',
        valor:
            '${planta!['days'] ?? 0}',
      ),

      _buildSeparador(),

      _buildFilaDato(
        icono: Icons.water_drop_outlined,
        titulo: 'Frecuencia de riego',
        valor: '${planta!['days_to_water'] ?? 0} días',
        onTap: editarFrecuenciaRiego,
      ),

    ],
  );
}


// ===========================================================================
// CUIDADOS
// ===========================================================================

Widget _buildCuidados() {
  return _buildSeccion(
    titulo: 'CUIDADOS',
    icono: Icons.spa_outlined,
    children: [

      _buildFilaDato(
        icono: Icons.eco_outlined,
        titulo: 'Último abono',
        valor:
            planta!['last_food']?.toString() ??
                'Sin registro',
      ),

      _buildSeparador(),

      _buildFilaDato(
        icono: Icons.content_cut_outlined,
        titulo: 'Último recorte',
        valor:
            planta!['last_pruning']?.toString() ??
                'Sin registro',
      ),

    ],
  );
}


// ===========================================================================
// CAUSA DE MUERTE
// ===========================================================================

Widget _buildCausaMuerte() {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3F3),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: const Color(0xFFFFD5D5),
      ),
    ),
    child: Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        const Icon(
          Icons.warning_amber_rounded,
          color: Colors.red,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              const Text(
                'CAUSA DE MUERTE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                planta!['death_cause'].toString(),
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),

            ],
          ),
        ),

      ],
    ),
  );
}


// ===========================================================================
// SECCIÓN
// ===========================================================================

Widget _buildSeccion({
  required String titulo,
  required IconData icono,
  required List<Widget> children,
}) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        Row(
          children: [

            Icon(
              icono,
              size: 21,
              color: const Color(0xFF4F7D4F),
            ),

            const SizedBox(width: 8),

            Text(
              titulo,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: Colors.black54,
              ),
            ),

          ],
        ),

        const SizedBox(height: 14),

        ...children,

      ],
    ),
  );
}


// ===========================================================================
// FILA DE INFORMACIÓN
// ===========================================================================
Widget _buildFilaDato({
  required IconData icono,
  required String titulo,
  required String valor,
  VoidCallback? onTap,
}) {
  final editable = onTap != null;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F6F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icono,
                size: 20,
                color: const Color(0xFF5B805B),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
              ),
            ),

            const SizedBox(width: 10),

            Flexible(
              child: Text(
                valor,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            if (editable) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: Colors.grey.shade500,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
// ===========================================================================
// SEPARADOR
// ===========================================================================

Widget _buildSeparador() {
  return Padding(
    padding: const EdgeInsets.symmetric(
      vertical: 12,
    ),
    child: Divider(
      height: 1,
      color: Colors.grey.shade200,
    ),
  );
}
}