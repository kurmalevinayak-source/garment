import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/lot_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_text_field.dart';

/// Form screen for adding or editing a lot entry.
///
/// - If [lot] is null → Add mode (empty form)
/// - If [lot] is provided → Edit mode (pre-filled form)
///
/// Auto-calculates remaining balance (pieces in - pieces out).
class AddEditLotScreen extends StatefulWidget {
  final LotModel? lot; // null = add, not-null = edit

  const AddEditLotScreen({super.key, this.lot});

  @override
  State<AddEditLotScreen> createState() => _AddEditLotScreenState();
}

class _AddEditLotScreenState extends State<AddEditLotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  late TextEditingController _lotNameController;
  late TextEditingController _piecesInController;
  late TextEditingController _piecesOutController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  bool _isSaving = false;

  bool get _isEditing => widget.lot != null;

  @override
  void initState() {
    super.initState();

    final l = widget.lot;
    _lotNameController = TextEditingController(text: l?.lotName ?? '');
    _piecesInController =
        TextEditingController(text: l?.piecesIn.toString() ?? '');
    _piecesOutController =
        TextEditingController(text: l?.piecesOut.toString() ?? '');
    _notesController = TextEditingController(text: l?.notes ?? '');
    _selectedDate = l?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _lotNameController.dispose();
    _piecesInController.dispose();
    _piecesOutController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Calculate remaining balance for display
  int get _remaining {
    final pIn = int.tryParse(_piecesInController.text) ?? 0;
    final pOut = int.tryParse(_piecesOutController.text) ?? 0;
    return pIn - pOut;
  }

  /// Open date picker
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                Theme.of(context).colorScheme.copyWith(
                      primary: AppColors.primary,
                    ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  /// Save the lot to Firestore
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final lot = LotModel(
        id: widget.lot?.id ?? '',
        lotName: _lotNameController.text.trim(),
        date: _selectedDate,
        piecesIn: int.tryParse(_piecesInController.text) ?? 0,
        piecesOut: int.tryParse(_piecesOutController.text) ?? 0,
        notes: _notesController.text.trim(),
        createdAt: widget.lot?.createdAt,
      );

      if (_isEditing) {
        await _firestoreService.updateLot(lot);
      } else {
        await _firestoreService.addLot(lot);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? '${lot.lotName} updated successfully'
                  : '${lot.lotName} added successfully',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remainingColor = _remaining > 0
        ? AppColors.success
        : _remaining < 0
            ? AppColors.error
            : AppColors.textSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Lot' : 'Add Lot'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Lot Name ───────────────────────────────────
              CustomTextField(
                controller: _lotNameController,
                label: 'Lot Name',
                hint: 'e.g., Lot A - Blue Shirts',
                prefixIcon: Icons.label_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the lot name';
                  }
                  return null;
                },
              ),

              // ── Date Picker ────────────────────────────────
              CustomTextField(
                label: 'Date',
                hint: DateFormat('dd MMM yyyy').format(_selectedDate),
                prefixIcon: Icons.calendar_today_rounded,
                readOnly: true,
                onTap: _pickDate,
                controller: TextEditingController(
                  text: DateFormat('dd MMM yyyy').format(_selectedDate),
                ),
              ),

              // ── Pieces In ─────────────────────────────────
              CustomTextField(
                controller: _piecesInController,
                label: 'Pieces In',
                hint: 'Number of pieces received',
                prefixIcon: Icons.arrow_downward_rounded,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter pieces in';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              // ── Pieces Out ────────────────────────────────
              CustomTextField(
                controller: _piecesOutController,
                label: 'Pieces Out',
                hint: 'Number of pieces dispatched',
                prefixIcon: Icons.arrow_upward_rounded,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              // ── Notes ─────────────────────────────────────
              CustomTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hint: 'Any additional notes...',
                prefixIcon: Icons.note_rounded,
                maxLines: 3,
              ),

              // ── Remaining Balance Display ──────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: remainingColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: remainingColor.withAlpha(77)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory_rounded,
                            color: remainingColor, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Remaining Balance',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$_remaining pieces',
                      style: TextStyle(
                        color: remainingColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Save Button ────────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          _isEditing ? Icons.save_rounded : Icons.add_rounded),
                  label: Text(_isEditing ? 'Update Lot' : 'Add Lot'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
