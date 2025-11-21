import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../models/health_record.dart';
import '../providers/health_records_provider.dart';
import '../widgets/bottom_nav_bar.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key, this.record});

  final HealthRecord? record;

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stepsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _waterController = TextEditingController();
  int _currentIndex = 2;
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.record?.date ?? DateTime.now();
    _stepsController.text = widget.record?.steps.toString() ?? '';
    _caloriesController.text = widget.record?.calories.toString() ?? '';
    _waterController.text = widget.record?.water.toString() ?? '';
    _startStepCounting();
  }

  void _startStepCounting() async {
    // Simulate automatic step counting
    // In a real app, you would use pedometer package here
    // For now, we'll add a button to get steps
  }

  @override
  void dispose() {
    _stepsController.dispose();
    _caloriesController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveRecord() async {
    // Allow saving with partial data - default to 0 if empty
    setState(() => _isSaving = true);

    final provider = context.read<HealthRecordsProvider>();
    final record = HealthRecord(
      id: widget.record?.id,
      date: _selectedDate,
      steps: _stepsController.text.isEmpty ? 0 : int.tryParse(_stepsController.text) ?? 0,
      calories: _caloriesController.text.isEmpty ? 0 : int.tryParse(_caloriesController.text) ?? 0,
      water: _waterController.text.isEmpty ? 0 : int.tryParse(_waterController.text) ?? 0,
    );

    // Check if at least one field has data
    if (record.steps == 0 && record.calories == 0 && record.water == 0) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter at least one value'),
            backgroundColor: AppColors.red,
          ),
        );
      }
      return;
    }

    try {
      if (widget.record == null) {
        await provider.addRecord(record);
      } else {
        await provider.updateRecord(record);
      }

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.record == null ? 'Record saved successfully!' : 'Record updated successfully!'),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _getStepsFromDevice() async {
    // Simulate getting steps from device
    // In a real app, use pedometer package
    final steps = 5000 + (DateTime.now().millisecond % 5000); // Simulated steps
    setState(() {
      _stepsController.text = steps.toString();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Steps synced from device'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.record != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Update Record' : 'Add Record',
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputField(
                label: 'Select Date',
                value: DateFormat('yyyy-MM-dd').format(_selectedDate),
                icon: Icons.calendar_today,
                iconColor: AppColors.blue,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberInputField(
                      controller: _stepsController,
                      label: 'Steps Walked',
                      icon: Icons.directions_walk,
                      iconColor: AppColors.green,
                      bgColor: AppColors.greenLight,
                      unit: 'steps',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: IconButton(
                      icon: const Icon(Icons.sync, color: AppColors.green),
                      onPressed: _getStepsFromDevice,
                      tooltip: 'Sync steps from device',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildNumberInputField(
                controller: _caloriesController,
                label: 'Calories Burned',
                icon: Icons.local_fire_department,
                iconColor: AppColors.red,
                bgColor: AppColors.redLight,
                unit: 'kcal',
              ),
              const SizedBox(height: 20),
              _buildNumberInputField(
                controller: _waterController,
                label: 'Water Intake',
                icon: Icons.water_drop,
                iconColor: AppColors.blue,
                bgColor: AppColors.blueLight,
                unit: 'ml',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(AppColors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check, color: AppColors.white),
                            const SizedBox(width: 8),
                            Text(
                              isEditing ? 'Update Record' : 'Save Record',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grayLight),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    border: InputBorder.none,
                  ),
                  // Allow empty values - will default to 0
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final number = int.tryParse(value);
                      if (number == null || number < 0) {
                        return 'Enter a valid positive number';
                      }
                    }
                    return null;
                  },
                ),
              ),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

