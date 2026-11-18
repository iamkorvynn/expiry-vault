import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';

import '../models/document.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/photo_service.dart';

/// Add a new document, or edit an existing one (passed as [document]).
/// The expiry date is entered manually with a date picker — no OCR,
/// so nothing is ever misread from a photo.
class AddEditScreen extends StatefulWidget {
  const AddEditScreen({this.document, super.key});

  final ExpiryDocument? document;

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _authorityController = TextEditingController();
  final PhotoService _photoService = PhotoService();

  late DocumentType _type;
  DateTime? _expiryDate;
  String? _photoPath;
  String? _pendingPhotoPath;
  bool _saving = false;

  bool get _isEditing => widget.document != null;

  @override
  void initState() {
    super.initState();
    final doc = widget.document;
    _type = doc?.type ?? DocumentType.puc;
    _titleController.text = doc?.title ?? '';
    _numberController.text = doc?.documentNumber ?? '';
    _authorityController.text = doc?.issuingAuthority ?? '';
    _expiryDate = doc?.expiryDate;
    _photoPath = doc?.photoPath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _numberController.dispose();
    _authorityController.dispose();
    super.dispose();
  }

  String get _effectivePhoto => _pendingPhotoPath ?? _photoPath ?? '';

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 365)),
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 30),
      helpText: 'Select expiry date',
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final path = await _photoService.pickAndStore(source);
    if (path == null) return;
    setState(() => _pendingPhotoPath = path);
  }

  Future<void> _removePhoto() async {
    setState(() {
      _pendingPhotoPath = null;
      _photoPath = null;
    });
  }

  void _showPhotoSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_effectivePhoto.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick an expiry date.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final oldPhoto = widget.document?.photoPath;
    if (_pendingPhotoPath != null &&
        oldPhoto != null &&
        oldPhoto != _pendingPhotoPath) {
      await _photoService.deletePhoto(oldPhoto);
    }
    if (_pendingPhotoPath == null && _photoPath == null && oldPhoto != null) {
      await _photoService.deletePhoto(oldPhoto);
    }

    final doc = ExpiryDocument(
      id: widget.document?.id,
      type: _type,
      title: _titleController.text.trim(),
      documentNumber: _numberController.text.trim(),
      issuingAuthority: _authorityController.text.trim().isEmpty
          ? null
          : _authorityController.text.trim(),
      expiryDate: _expiryDate!,
      photoPath: _effectivePhoto.isEmpty ? null : _effectivePhoto,
      createdAt: widget.document?.createdAt,
    );

    try {
      int id;
      if (_isEditing) {
        await DatabaseService.instance.updateDocument(doc);
        id = doc.id!;
      } else {
        id = await DatabaseService.instance.insertDocument(doc);
      }
      final saved = doc.copyWith(id: id);
      await NotificationService.instance.scheduleForDocument(saved);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save: $e')));
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit document' : 'Add document'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            DropdownButtonFormField<DocumentType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Document type',
                border: OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<DocumentType>>[
                for (final t in DocumentType.values)
                  DropdownMenuItem<DocumentType>(
                    value: t,
                    child: Text(t.label),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Name / label',
                hintText: 'e.g. Honda City PUC, My passport',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'Document number',
                hintText: 'e.g. MH02AB1234',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter the document number.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _authorityController,
              decoration: const InputDecoration(
                labelText: 'Issuing authority (optional)',
                hintText: 'e.g. RTO Mumbai, HDFC ERGO',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickExpiryDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expiry date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _expiryDate == null
                      ? 'Tap to pick the expiry date'
                      : _formatDate(_expiryDate!),
                  style: TextStyle(
                    color: _expiryDate == null
                        ? Theme.of(context).hintColor
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the date printed on the document. No scanning or '
              'OCR — the date you enter is the date used for reminders.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 24),
            const Text(
              'Photo of the document (optional)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (_effectivePhoto.isNotEmpty &&
                File(_effectivePhoto).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_effectivePhoto),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _showPhotoSheet,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(
                _effectivePhoto.isEmpty ? 'Add photo' : 'Change photo',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Save document'),
            ),
          ],
        ),
      ),
    );
  }
}
