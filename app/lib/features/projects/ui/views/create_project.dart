import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../viewmodels/user_projects_controller.dart';

/// Pantalla "Crear proyecto" de Imker
class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({super.key});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  /// Pestaña seleccionada: 0 = "Info. básica", 1 = "Miembros".
  int _selectedTab = 0;

  /// Estado de envío del formulario al backend Roble.
  bool _isSubmitting = false;

  /// Controlador del campo "Nombre del proyecto".
  final TextEditingController _nombreController = TextEditingController();

  /// Controlador del campo "Descripción".
  final TextEditingController _descripcionController = TextEditingController();

  /// Controlador del campo "URL de la imagen".
  final TextEditingController _imageUrlController = TextEditingController();

  /// Controlador del campo de texto para agregar una carrera relacionada.
  final TextEditingController _carreraController = TextEditingController();

  /// Controlador del campo de texto para agregar un conocimiento/habilidad.
  final TextEditingController _habilidadController = TextEditingController();

  /// Controlador del campo de correo para invitar miembros.
  final TextEditingController _miembroController = TextEditingController();

  /// Lista de carreras relacionadas ya agregadas al proyecto.
  /// Arranca vacía a propósito: nada de datos precargados.
  final List<String> _carreras = [];

  /// Lista de conocimientos/habilidades requeridos ya agregados.
  /// Arranca vacía a propósito: nada de datos precargados.
  final List<String> _habilidades = [];

  /// Correos de las personas invitadas a colaborar en el proyecto.
  /// Se verifican TODOS en el servidor antes de crear el proyecto.
  final List<String> _invitados = [];

  @override
  void dispose() {
    // Liberar los controladores de texto para evitar fugas de memoria.
    _nombreController.dispose();
    _descripcionController.dispose();
    _imageUrlController.dispose();
    _carreraController.dispose();
    _habilidadController.dispose();
    _miembroController.dispose();
    super.dispose();
  }

  /// Toma el texto escrito en [_carreraController], lo agrega a
  /// [_carreras] (si no está vacío ni ya existía) y limpia el campo.
  void _addCarrera() => _addTo(_carreras, _carreraController, 'carrera');

  /// Toma el texto escrito en [_habilidadController], lo agrega a
  /// [_habilidades] (si no está vacío ni ya existía) y limpia el campo.
  void _addHabilidad() =>
      _addTo(_habilidades, _habilidadController, 'conocimiento');

  /// Regla común de las listas con chip: sin duplicados y sin vacíos.
  void _addTo(List<String> target, TextEditingController field, String kind) {
    final value = field.text.trim();
    if (value.isEmpty) return;
    if (target.any((item) => item.toLowerCase() == value.toLowerCase())) {
      Get.snackbar(
        'Ya agregado',
        'El $kind "$value" ya estaba en la lista.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    setState(() {
      target.add(value);
      field.clear();
    });
  }

  /// Añade un correo a la lista de invitados. El formato se chequea aquí y
  /// la existencia de la cuenta la resuelve el servidor al crear el proyecto.
  void _addInvitado() {
    final value = _miembroController.text.trim();
    if (value.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      Get.snackbar(
        'Correo inválido',
        '"$value" no parece un correo electrónico.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    _addTo(_invitados, _miembroController, 'correo');
  }

  @override
  Widget build(BuildContext context) {
    // Se obtienen una sola vez por build y se pasan como parámetros a los
    // métodos privados, en vez de leer Theme.of(context) repetidamente.
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: Scaffold(
        backgroundColor: cs.secondaryContainer,
        appBar: _buildAppBar(cs, tt),
        body: Column(
          children: [
            _buildTabs(cs, tt),
            // El formulario completo es desplazable para que la descripción
            // y los demás campos no queden cortados en pantallas pequeñas
            // o cuando aparece el teclado.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: _selectedTab == 0
                    ? _buildInfoBasicaForm(cs, tt)
                    : _buildMiembrosPlaceholder(cs, tt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// AppBar superior con el ícono de retroceso y el título "Crear Proyecto".
  PreferredSizeWidget _buildAppBar(ColorScheme cs, TextTheme tt) {
    return AppBar(
      backgroundColor: cs.primaryContainer,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: cs.onSurface),
        onPressed: () => Get.back(),
      ),
      title: Text(
        'Crear Proyecto',
        style: tt.titleLarge?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// Barra de pestañas "Info. básica" / "Miembros" que controla
  /// [_selectedTab].
  Widget _buildTabs(ColorScheme cs, TextTheme tt) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(children: [_buildTabItem('Info. básica', 0, cs, tt)]),
    );
  }

  /// Un ítem individual de la barra de pestañas.
  ///
  /// [label] es el texto mostrado, [index] identifica la pestaña
  /// (comparado contra [_selectedTab] para saber si está activa).
  Widget _buildTabItem(String label, int index, ColorScheme cs, TextTheme tt) {
    final bool selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            // Subrayado que solo se muestra en la pestaña activa.
            border: Border(
              bottom: BorderSide(
                color: selected ? cs.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: tt.titleMedium?.copyWith(
                color: selected ? cs.onSurface : cs.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Formulario completo de la pestaña "Info. básica": nombre, descripción,
  /// carreras relacionadas, conocimientos requeridos, invitar miembros y
  /// el botón final "Crear proyecto".
  Widget _buildInfoBasicaForm(ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Nombre del proyecto ---
        _sectionCard(
          cs,
          child: _labeledField(
            cs,
            tt,
            label: 'Nombre del proyecto',
            child: TextField(
              controller: _nombreController,
              style: tt.headlineSmall?.copyWith(
                color: cs.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
              decoration: _fieldDecoration(cs, tt, hint: 'Nombre Proyecto'),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // --- Descripción ---
        _sectionCard(
          cs,
          child: _labeledField(
            cs,
            tt,
            label: 'Descripción',
            child: TextField(
              controller: _descripcionController,
              maxLines: 4,
              minLines: 3,
              style: tt.bodyMedium?.copyWith(color: cs.onSecondaryContainer),
              decoration: _fieldDecoration(
                cs,
                tt,
                hint: 'la cosa la cosa la cosa hacer la cosa es muy importante porque la cosa la cosa la cosa',
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // --- URL de la imagen ---
        _sectionCard(
          cs,
          child: _labeledField(
            cs,
            tt,
            label: 'URL de la imagen (opcional)',
            child: TextField(
              controller: _imageUrlController,
              style: tt.bodyMedium?.copyWith(color: cs.onSecondaryContainer),
              decoration: _fieldDecoration(
                cs,
                tt,
                hint: 'https://ejemplo.com/imagen.png',
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // --- Carreras relacionadas ---
        _tagField(
          cs,
          tt,
          label: 'Carreras relacionadas',
          hint: 'Escribe una carrera relacionada',
          emptyText: 'Todavía no has agregado ninguna carrera.',
          controller: _carreraController,
          values: _carreras,
          valueKind: 'carrera',
          onAdd: _addCarrera,
          onRemove: (value) => setState(() => _carreras.remove(value)),
        ),
        const SizedBox(height: 14),

        // --- Conocimientos requeridos ---
        _tagField(
          cs,
          tt,
          label: 'Conocimientos requeridos',
          hint: 'Añade un conocimiento',
          emptyText: 'Todavía no has agregado ningún conocimiento.',
          controller: _habilidadController,
          values: _habilidades,
          valueKind: 'conocimiento',
          onAdd: _addHabilidad,
          onRemove: (value) => setState(() => _habilidades.remove(value)),
        ),
        const SizedBox(height: 14),

        // --- Invitar miembros ---
        // Se agregan correos como chips; el servidor verifica que todos
        // tengan cuenta antes de crear el proyecto (si falta alguno, no se
        // crea nada). Esta sección es opcional.
        _tagField(
          cs,
          tt,
          label: 'Invitar miembros (opcional)',
          hint: 'compañero@ejemplo.com',
          emptyText:
              'Todavía no has invitado a nadie. '
              'Puedes hacerlo después desde el proyecto.',
          controller: _miembroController,
          values: _invitados,
          valueKind: 'correo',
          onAdd: _addInvitado,
          onRemove: (value) => setState(() => _invitados.remove(value)),
        ),
        const SizedBox(height: 20),

        // --- Botón principal ---
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.inversePrimary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: cs.outline),
              ),
            ),
            child: _isSubmitting
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: cs.onPrimary,
                    ),
                  )
                : Text(
                    'Crear proyecto',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// Recolecta los valores del formulario y envía la solicitud de creación
  /// a través del [UserProjectsController] hacia el repositorio de Roble.
  Future<void> _submitForm() async {
    final title = _nombreController.text.trim();
    final description = _descripcionController.text.trim();
    final imageUrl = _imageUrlController.text.trim();

    if (title.isEmpty) {
      Get.snackbar(
        'Campo requerido',
        'Por favor, ingresa el nombre del proyecto.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (description.isEmpty) {
      Get.snackbar(
        'Campo requerido',
        'Por favor, ingresa una descripción para el proyecto.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final controller = Get.isRegistered<UserProjectsController>()
          ? Get.find<UserProjectsController>()
          : Get.put(UserProjectsController());

      await controller.createProject(
        title: title,
        description: description,
        imageUrl: imageUrl,
        jobs: List<String>.from(_carreras),
        skills: List<String>.from(_habilidades),
        inviteEmails: List<String>.from(_invitados),
      );

      Get.back();
      Get.snackbar(
        '¡Éxito!',
        _invitados.isEmpty
            ? 'El proyecto "$title" ha sido creado correctamente.'
            : 'El proyecto "$title" ha sido creado y se invitó a '
                  '${_invitados.length} ${_invitados.length == 1 ? 'persona' : 'personas'}.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error al crear proyecto',
        e.toString().replaceAll('ProjectFailure: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Contenido temporal de la pestaña "Miembros".
  ///
  /// Placeholder a reemplazar por la gestión real de miembros del
  /// proyecto (lista de invitados, roles, estado de la invitación, etc).
  Widget _buildMiembrosPlaceholder(ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          'Aquí irá la gestión de miembros del proyecto.',
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
    );
  }

  /// Contenedor con fondo, bordes redondeados y borde sutil, usado como
  /// "tarjeta" para cada sección del formulario (nombre, descripción, etc).
  Widget _sectionCard(ColorScheme cs, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        border: Border.all(color: cs.outline),
      ),
      child: child,
    );
  }

  /// Envuelve un campo (`child`) con su etiqueta (`label`) arriba,
  /// siguiendo el patrón "Label" + input que se repite en todo el
  /// formulario.
  Widget _labeledField(
    ColorScheme cs,
    TextTheme tt, {
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: tt.labelLarge?.copyWith(
            color: cs.onSecondaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  /// Decoración compartida por todos los [TextField] del formulario:
  /// hint, relleno y bordes redondeados que cambian de color al enfocar.
  InputDecoration _fieldDecoration(
    ColorScheme cs,
    TextTheme tt, {
    required String hint,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      filled: true,
      fillColor: cs.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderSide: BorderSide(color: cs.outline)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: cs.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
    );
  }

  /// Fila reutilizable de "campo de texto + botón Añadir", usada para
  /// agregar carreras, conocimientos e invitar miembros.
  ///
  /// [controller] guarda el texto escrito, [hint] es el placeholder y
  /// [onAdd] se ejecuta al presionar el botón "Añadir" o al confirmar
  /// con el teclado.
  Widget _addRow(
    ColorScheme cs,
    TextTheme tt, {
    required TextEditingController controller,
    required String hint,
    required VoidCallback onAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: tt.bodyMedium?.copyWith(color: cs.onSecondaryContainer),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onAdd(),
            decoration: _fieldDecoration(cs, tt, hint: hint),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.inversePrimary,
            foregroundColor: cs.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(side: BorderSide(color: cs.outline)),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            'Añadir',
            style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  /// Campo con lista: arriba la fila de escritura (lo que se teclea),
  /// abajo, en un contenedor con borde propio, lo que ya quedó agregado.
  ///
  /// Las dos zonas se separan a propósito para que nunca se confunda el
  /// input de teclado con los datos ya puestos en el formulario.
  Widget _tagField(
    ColorScheme cs,
    TextTheme tt, {
    required String label,
    required String hint,
    required String emptyText,
    required TextEditingController controller,
    required List<String> values,
    required String valueKind,
    required VoidCallback onAdd,
    required ValueChanged<String> onRemove,
  }) {
    return _sectionCard(
      cs,
      child: _labeledField(
        cs,
        tt,
        label: label,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zona de escritura: se teclea aquí y se confirma con "Añadir".
            _addRow(cs, tt, controller: controller, hint: hint, onAdd: onAdd),
            const SizedBox(height: 12),
            // Zona de datos ya agregados.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border.all(color: cs.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.checklist,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (values.isEmpty)
                    Text(
                      emptyText,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    )
                  else
                    ...values.map(
                      (value) => _tagChip(
                        cs,
                        tt,
                        label: value,
                        valueKind: valueKind,
                        onRemove: () => onRemove(value),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Chip de un elemento ya agregado: relleno distinto al del input y
  /// un botón de cerrar explícito para quitarlo de la lista.
  Widget _tagChip(
    ColorScheme cs,
    TextTheme tt, {
    required String label,
    required String valueKind,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: tt.bodyMedium?.copyWith(color: cs.onTertiaryContainer),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Quitar $valueKind',
            icon: Icon(Icons.close, size: 18, color: cs.onTertiaryContainer),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
