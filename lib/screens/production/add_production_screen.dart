import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/production_record.dart';
import '../../models/worker_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/loading_widget.dart';

class AddProductionScreen extends StatefulWidget {
  const AddProductionScreen({super.key});

  @override
  State<AddProductionScreen> createState() => _AddProductionScreenState();
}

class _AddProductionScreenState extends State<AddProductionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  String? _selectedWorkerId;
  String? _selectedWorkerName;
  final _piecesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _piecesController.dispose();
    super.dispose();
  }

  void _saveProduction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWorkerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a worker')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final pieces = int.parse(_piecesController.text);
      final record = ProductionRecord(
        id: '', // Firestore generates this mapping
        workerId: _selectedWorkerId!,
        workerName: _selectedWorkerName ?? 'Unknown',
        date: _selectedDate,
        pieces: pieces,
      );

      await _firestoreService.addProductionRecord(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Production added successfully')),
        );
        Navigator.pop(context, true); // Return true to signal refresh needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Production'),
      ),
      body: _isSaving
          ? const LoadingWidget(message: 'Saving production...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Worker selection
                    StreamBuilder<List<WorkerModel>>(
                      stream: _firestoreService.getWorkers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ));
                        }

                        final workers = snapshot.data ?? [];
                        if (workers.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withAlpha(26),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('No workers available. Add a worker first.'),
                          );
                        }

                        // Ensure selected worker is in the list (in case of updates)
                        if (_selectedWorkerId != null && !workers.any((w) => w.id == _selectedWorkerId)) {
                          _selectedWorkerId = null;
                          _selectedWorkerName = null;
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedWorkerId,
                          decoration: InputDecoration(
                            labelText: 'Select Worker',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.person_rounded),
                          ),
                          items: workers.map((worker) {
                            return DropdownMenuItem<String>(
                              value: worker.id,
                              child: Text('${worker.name} (${worker.role})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedWorkerId = val;
                              if (val != null) {
                                _selectedWorkerName = workers.firstWhere((w) => w.id == val).name;
                              }
                            });
                          },
                          validator: (val) => val == null ? 'Required' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Pieces Field
                    TextFormField(
                      controller: _piecesController,
                      decoration: InputDecoration(
                        labelText: 'Number of Pieces',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.precision_manufacturing_rounded),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (int.tryParse(val) == null || int.parse(val) <= 0) {
                          return 'Enter valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Date Selection
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.calendar_today_rounded),
                        ),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _saveProduction,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Save Production',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
