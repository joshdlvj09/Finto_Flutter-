// Formulario para registrar o editar un movimiento.
// Usa los tres gadgets: camara/galeria (foto del ticket), microfono (dictar la nota)
// y GPS (se captura la ubicacion al abrir un movimiento nuevo).
// "Agregar otro" pasa lo capturado a una lista y al final se guardan todos juntos.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_theme.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/format.dart';
import '../../data/models/entry_metadata.dart';
import '../../data/models/movement.dart';
import '../../data/repositories/repository_exception.dart';
import '../../services/camera_service.dart';
import '../../services/location_service.dart';
import '../../services/speech_service.dart';
import '../providers/auth_provider.dart';
import '../providers/movement_provider.dart';
import '../widgets/hardware_feedback.dart';

enum _GpsState { idle, loading, ok, failed }

class MovementFormScreen extends StatefulWidget {
  final int? editId;
  const MovementFormScreen({super.key, this.editId});

  @override
  State<MovementFormScreen> createState() => _MovementFormScreenState();
}

class _MovementFormScreenState extends State<MovementFormScreen> {
  static const _maxPending = 30;

  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  Movement? _editing;
  String _type = 'gasto';
  String? _category;
  DateTime _date = DateTime.now();
  String _invoice = 'no';
  String? _imagePath;
  double? _lat;
  double? _lng;

  _GpsState _gps = _GpsState.idle;
  bool _listening = false;
  bool _saving = false;
  bool _saved = false;
  final List<Movement> _pending = [];

  late final SpeechService _speech;
  late final CameraService _camera;

  bool get _isEditing => _editing != null;

  @override
  void initState() {
    super.initState();
    _speech = context.read<SpeechService>();
    _camera = context.read<CameraService>();
    if (widget.editId != null) {
      _editing = context.read<MovementProvider>().byId(widget.editId!);
      _fillFrom(_editing);
    } else {
      // Movimiento nuevo: capturamos la ubicacion desde que se abre el formulario
      WidgetsBinding.instance.addPostFrameCallback((_) => _captureLocation());
    }
  }

  void _fillFrom(Movement? m) {
    if (m == null) return;
    _type = m.type;
    _amountCtrl.text = m.amount.toString().replaceAll(RegExp(r'\.0$'), '');
    _category = m.category;
    _descCtrl.text = m.description;
    _date = m.date;
    _invoice = m.invoice;
    _imagePath = m.metadata.imagePath;
    _lat = m.metadata.latitude;
    _lng = m.metadata.longitude;
    if (m.metadata.hasLocation) _gps = _GpsState.ok;
  }

  @override
  void dispose() {
    if (_listening) _speech.stop();
    // Si salio sin guardar, borramos las fotos nuevas que ya no se van a usar
    if (!_saved) {
      if (_imagePath != null && _imagePath != _editing?.metadata.imagePath) {
        _camera.deleteImage(_imagePath);
      }
      for (final m in _pending) {
        _camera.deleteImage(m.metadata.imagePath);
      }
    }
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ---------------- Gadgets ----------------

  Future<void> _captureLocation() async {
    setState(() => _gps = _GpsState.loading);
    final result = await context.read<LocationService>().getCurrentPosition();
    if (!mounted) return;
    if (result.isOk) {
      setState(() {
        _lat = result.data!.latitude;
        _lng = result.data!.longitude;
        _gps = _GpsState.ok;
      });
    } else {
      setState(() => _gps = _GpsState.failed);
      showHardwareError(context, result);
    }
  }

  Future<void> _pickImage(bool fromCamera) async {
    final camera = _camera;
    final result = fromCamera ? await camera.takePhoto() : await camera.pickFromGallery();
    if (!mounted) return;
    if (result.isOk) {
      // Si ya habia una foto nueva (no guardada) la borramos
      if (_imagePath != null && _imagePath != _editing?.metadata.imagePath) {
        await camera.deleteImage(_imagePath);
      }
      setState(() => _imagePath = result.data);
    } else {
      showHardwareError(context, result);
    }
  }

  Future<void> _removeImage() async {
    if (_imagePath != null && _imagePath != _editing?.metadata.imagePath) {
      await _camera.deleteImage(_imagePath);
    }
    setState(() => _imagePath = null);
  }

  Future<void> _toggleDictation() async {
    final speech = _speech;
    if (_listening) {
      await speech.stop();
      setState(() => _listening = false);
      return;
    }

    final init = await speech.init(onError: (msg) {
      if (!mounted) return;
      setState(() => _listening = false);
      showMessage(context, msg);
    });
    if (!mounted) return;
    if (!init.isOk) {
      showHardwareError(context, init);
      return;
    }

    final before = _descCtrl.text.trim();
    setState(() => _listening = true);
    await speech.start(onText: (text, isFinal) {
      if (!mounted) return;
      // Agregamos lo dictado despues de lo que ya estaba escrito (max 60 caracteres)
      var full = before.isEmpty ? text : '$before $text';
      if (full.length > 60) full = full.substring(0, 60);
      _descCtrl.value = TextEditingValue(
        text: full,
        selection: TextSelection.collapsed(offset: full.length),
      );
      if (isFinal) setState(() => _listening = false);
    });
  }

  // ---------------- Formulario ----------------

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day, _date.hour, _date.minute));
    }
  }

  void _changeType(String type) {
    setState(() {
      _type = type;
      if (_category != null && !Categories.byId(_category!).fitsType(type)) _category = null;
      if (type == 'ingreso') _invoice = 'no';
    });
  }

  // Valida y arma el movimiento con lo capturado. Regresa null si falta algo.
  Movement? _buildCurrent() {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      showMessage(context, 'Escribe un monto válido');
      return null;
    }
    if (_category == null) {
      showMessage(context, 'Elige una categoría');
      return null;
    }
    final userId = context.read<AuthProvider>().user!.id!;
    return Movement(
      id: _editing?.id,
      userId: userId,
      type: _type,
      amount: double.parse(amount.toStringAsFixed(2)),
      category: _category!,
      description: _descCtrl.text.trim(),
      date: _date,
      invoice: _type == 'gasto' ? _invoice : 'no',
      metadata: EntryMetadata(imagePath: _imagePath, latitude: _lat, longitude: _lng),
    );
  }

  void _addAnother() {
    if (_pending.length >= _maxPending) {
      showMessage(context, 'Máximo $_maxPending movimientos por lote');
      return;
    }
    final m = _buildCurrent();
    if (m == null) return;
    setState(() {
      _pending.add(m);
      // Limpiamos lo de un movimiento; tipo, fecha y ubicacion se conservan
      _amountCtrl.clear();
      _descCtrl.clear();
      _category = null;
      _invoice = 'no';
      _imagePath = null;
    });
  }

  Future<void> _save() async {
    // Si el formulario esta vacio y hay pendientes, solo guardamos los pendientes
    final formEmpty = _amountCtrl.text.trim().isEmpty && _category == null;
    final current = (formEmpty && _pending.isNotEmpty) ? null : _buildCurrent();
    if (current == null && _pending.isEmpty) return;

    setState(() => _saving = true);
    final provider = context.read<MovementProvider>();
    try {
      if (_isEditing) {
        await provider.update(current!, oldImagePath: _editing!.metadata.imagePath);
      } else {
        final all = [..._pending, if (current != null) current];
        if (all.length == 1) {
          await provider.add(all.first);
        } else {
          await provider.addMany(all);
        }
      }
      _saved = true;
      if (!mounted) return;
      Navigator.pop(context);
    } on RepositoryException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (e) {
      if (mounted) showMessage(context, 'No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final saveLabel = _isEditing
        ? 'Guardar cambios'
        : _pending.isEmpty
            ? 'Guardar'
            : 'Guardar ${_pending.length + (_amountCtrl.text.isEmpty ? 0 : 1)} movimientos';

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar movimiento' : 'Nuevo movimiento')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'gasto', label: Text('Gasto'), icon: Icon(Icons.arrow_upward)),
              ButtonSegment(value: 'ingreso', label: Text('Ingreso'), icon: Icon(Icons.arrow_downward)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => _changeType(s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,2}'))],
            style: const TextStyle(fontSize: 24, color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$ '),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Categoría'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Categories.forType(_type).map((c) {
              final selected = _category == c.id;
              return ChoiceChip(
                avatar: Icon(c.icon, size: 18, color: selected ? Colors.black : c.color),
                label: Text(c.label),
                selected: selected,
                selectedColor: c.color,
                onSelected: (_) => setState(() => _category = c.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: _listening ? 'Escuchando...' : 'Nota (opcional)',
              suffixIcon: IconButton(
                tooltip: 'Dictar por voz',
                onPressed: _toggleDictation,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _listening ? Icons.stop_circle : Icons.mic_none,
                    key: ValueKey(_listening),
                    color: _listening ? AppColors.expense : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined, color: AppColors.secondary),
            title: Text(Format.dateLabel(_date), style: const TextStyle(color: AppColors.textPrimary)),
            trailing: TextButton(onPressed: _pickDate, child: const Text('Cambiar')),
          ),
          if (_type == 'gasto') ...[
            _sectionTitle('Factura'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'no', label: Text('No')),
                ButtonSegment(value: 'pendiente', label: Text('Pendiente')),
                ButtonSegment(value: 'realizada', label: Text('Hecha')),
              ],
              selected: {_invoice},
              onSelectionChanged: (s) => setState(() => _invoice = s.first),
            ),
            const SizedBox(height: 16),
          ],
          _sectionTitle('Foto del ticket'),
          _photoSection(),
          const SizedBox(height: 16),
          _sectionTitle('Ubicación'),
          _locationSection(),
          if (_pending.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionTitle('Por guardar (${_pending.length})'),
            ..._pending.asMap().entries.map((e) => _pendingTile(e.key, e.value)),
          ],
          const SizedBox(height: 24),
          if (!_isEditing)
            OutlinedButton.icon(
              onPressed: _saving ? null : _addAnother,
              icon: const Icon(Icons.playlist_add),
              label: const Text('Agregar otro movimiento'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(saveLabel),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600)),
      );

  Widget _photoSection() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _imagePath == null
          ? Row(
              key: const ValueKey('no-photo'),
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(true),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Cámara'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(false),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galería'),
                  ),
                ),
              ],
            )
          : Stack(
              key: ValueKey(_imagePath),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(_imagePath!),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: AppColors.card,
                      alignment: Alignment.center,
                      child: const Text('No se pudo cargar la foto'),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _roundButton(Icons.photo_camera_outlined, () => _pickImage(true)),
                      const SizedBox(width: 8),
                      _roundButton(Icons.close, _removeImage),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) => Material(
        color: Colors.black54,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, size: 20)),
        ),
      );

  Widget _locationSection() {
    Widget leading;
    String text;
    switch (_gps) {
      case _GpsState.loading:
        leading = const SizedBox(
            width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary));
        text = 'Obteniendo ubicación...';
        break;
      case _GpsState.ok:
        leading = const Icon(Icons.place, color: AppColors.income);
        text = '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}';
        break;
      case _GpsState.failed:
        leading = const Icon(Icons.location_off_outlined, color: AppColors.expense);
        text = 'Sin ubicación (se guardará sin mapa)';
        break;
      case _GpsState.idle:
        leading = const Icon(Icons.location_searching, color: AppColors.textMuted);
        text = 'Sin ubicación';
    }
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: leading,
        title: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_gps == _GpsState.ok)
              IconButton(
                tooltip: 'Quitar ubicación',
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => setState(() {
                  _lat = null;
                  _lng = null;
                  _gps = _GpsState.idle;
                }),
              ),
            IconButton(
              tooltip: 'Actualizar ubicación',
              icon: const Icon(Icons.my_location, color: AppColors.primary),
              onPressed: _gps == _GpsState.loading ? null : _captureLocation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingTile(int index, Movement m) {
    final c = Categories.byId(m.category);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: Icon(c.icon, color: c.color),
        title: Text(m.description.isEmpty ? c.label : m.description),
        subtitle: Text(Format.dateLabel(m.date), style: const TextStyle(color: AppColors.textMuted)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${m.isIncome ? '+' : '-'}${Format.money(m.amount)}',
                style: TextStyle(color: m.isIncome ? AppColors.income : AppColors.expense)),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () async {
                setState(() => _pending.removeAt(index));
                await _camera.deleteImage(m.metadata.imagePath);
              },
            ),
          ],
        ),
      ),
    );
  }
}
