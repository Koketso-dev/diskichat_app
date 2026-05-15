import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../data/models/feedback_model.dart';
import '../../utils/themes/app_colors.dart';
import '../../components/buttons/gradient_button.dart';
import '../../components/inputs/custom_text_field.dart';
import '../../providers/auth_provider.dart';

class FeatureRequestScreen extends StatefulWidget {
  const FeatureRequestScreen({super.key});

  @override
  State<FeatureRequestScreen> createState() => _FeatureRequestScreenState();
}

class _FeatureRequestScreenState extends State<FeatureRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _firestoreService = FirestoreService();

  String _selectedType = 'Feature Request';
  bool _isLoading = false;

  final Map<String, String> _typeOptions = {
    'Feature Request': 'Request a Feature',
    'Bug Report': 'Report a Bug',
    'General Feedback': 'General Feedback',
    'Other': 'Other',
  };

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final profile = Provider.of<AuthProvider>(context, listen: false).userProfile;

      final feedback = FeedbackModel(
        id: '',
        userId: user?.uid ?? 'anonymous',
        username: profile?.username ?? user?.displayName ?? 'Anonymous',
        userEmail: user?.email ?? 'No Email',
        type: _selectedType,
        description: _descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _firestoreService.submitFeedback(feedback);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your feedback has been submitted.'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(title: const Text('FEEDBACK & REQUESTS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentBlue),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    dropdownColor: AppColors.cardSurface,
                    style: const TextStyle(color: AppColors.textWhite),
                    isExpanded: true,
                    items: _typeOptions.entries.map((entry) {
                      return DropdownMenuItem(value: entry.key, child: Text(entry.value));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedType = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description',
                hintText: 'Describe your idea or issue in detail...',
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter a description';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              GradientButton(text: 'SUBMIT FEEDBACK', onPressed: _submit, isLoading: _isLoading),
            ],
          ),
        ),
      ),
    );
  }
}
