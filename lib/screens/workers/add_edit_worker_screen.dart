import 'package:flutter/material.dart';
import '../../models/worker_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';

/// Form screen for adding or editing a worker.
///
/// - If [worker] is null → Add mode (empty form)
/// - If [worker] is provided → Edit mode (pre-filled form)
///
/// Auto-calculates and displays estimated salary based on rate × total pieces.
class AddEditWorkerScreen extends StatefulWidget {
  final WorkerModel? worker; // null = add, not-null = edit

  const AddEditWorkerScreen({super.key, this.worker});

  @override
  State<AddEditWorkerScreen> createState() => _AddEditWorkerScreenState();
}

class _AddEditWorkerScreenState extends State<AddEditWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  late TextEditingController _nameController;
  late TextEditingController _rateController;
  late TextEditingController _piecesTodayController;
  late TextEditingController _totalPiecesController;
  String _selectedRole = AppConstants.roleWorker;
  bool _isSaving = false;

  bool get _isEditing => widget.worker != null;

  @override
  void initState() {
    super.initState();

    // Pre-fill if editing
    final w = widget.worker;
    _nameController = TextEditingController(text: w?.name ?? '');
    _rateController = TextEditingController(
        text: w?.ratePerPiece.toString() ??
            AppConstants.defaultRatePerPiece.toString());
    _piecesTodayController =
        TextEditingController(text: w?.piecesToday.toString() ?? '0');
    _totalPiecesController =
        TextEditingController(text: w?.totalPieces.toString() ?? '0');
    _selectedRole = w?.role ?? AppConstants.roleWorker;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    _piecesTodayController.dispose();
    _totalPiecesController.dispose();
    super.dispose();
  }

  /// Calculate estimated salary for display
  double get _estimatedSalary {
    final rate = double.tryParse(_rateController.text) ?? 0;
    final total = int.tryParse(_totalPiecesController.text) ?? 0;
    return rate * total;
  }

  /// Save the worker to Firestore
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final worker = WorkerModel(
        id: widget.worker?.id ?? '', // Firestore will assign ID for new docs
        name: _nameController.text.trim(),
        role: _selectedRole,
        ratePerPiece: double.tryParse(_rateController.text) ??
            AppConstants.defaultRatePerPiece,
        piecesToday: int.tryParse(_piecesTodayController.text) ?? 0,
        totalPieces: int.tryParse(_totalPiecesController.text) ?? 0,
        createdAt: widget.worker?.createdAt,
      );

      if (_isEditing) {
        await _firestoreService.updateWorker(worker);
      } else {
        await _firestoreService.addWorker(worker);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? '${worker.name} updated successfully'
                  : '${worker.name} added successfully',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Worker' : 'Add Worker'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Worker Name ────────────────────────────────
              CustomTextField(
                controller: _nameController,
                label: 'Worker Name',
                hint: 'Enter full name',
                prefixIcon: Icons.person_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the worker name';
                  }
                  return null;
                },
              ),

              // ── Role Dropdown ──────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    prefixIcon: const Icon(Icons.work_rounded),
                  ),
                  items: AppConstants.roles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRole = value);
                    }
                  },
                ),
              ),

              // ── Rate per Piece ─────────────────────────────
              CustomTextField(
                controller: _rateController,
                label: 'Rate per Piece (${AppConstants.currencySymbol})',
                hint: '5.0',
                prefixIcon: Icons.currency_rupee_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}), // Refresh salary display
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the rate per piece';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              // ── Pieces Today ───────────────────────────────
              CustomTextField(
                controller: _piecesTodayController,
                label: 'Pieces Today',
                hint: '0',
                prefixIcon: Icons.today_rounded,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              // ── Total Pieces ───────────────────────────────
              CustomTextField(
                controller: _totalPiecesController,
                label: 'Total Pieces',
                hint: '0',
                prefixIcon: Icons.inventory_2_rounded,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}), // Refresh salary display
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              // ── Estimated Salary Display ───────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withAlpha(77),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet_rounded,
                            color: AppColors.success, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Estimated Salary',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${AppConstants.currencySymbol}${_estimatedSalary.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColors.success,
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
                      : Icon(_isEditing ? Icons.save_rounded : Icons.add_rounded),
                  label: Text(_isEditing ? 'Update Worker' : 'Add Worker'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
