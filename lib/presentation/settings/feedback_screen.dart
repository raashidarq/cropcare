// lib/presentation/settings/feedback_screen.dart

import 'package:flutter/material.dart';

import '../../domain/entities/local_user.dart';
import '../../domain/usecases/feedback/submit_feedback_use_case.dart';
import '../onboarding/localization/localization_provider.dart';

class FeedbackScreen extends StatefulWidget {
  final LocalUser? user;
  final SubmitFeedbackUseCase? submitFeedbackUseCase;

  const FeedbackScreen({
    super.key,
    this.user,
    this.submitFeedbackUseCase,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  String _selectedCategory = 'general';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.submitFeedbackUseCase != null) {
        await widget.submitFeedbackUseCase!(
          message: _messageController.text.trim(),
          category: _selectedCategory,
          userId: widget.user?.remoteUserId ?? widget.user?.id,
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('feedback_success')),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting feedback: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('feedback_title')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('feedback_subtitle'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              // ── Category Selector ──────────────────────────────────────
              Text(
                context.tr('feedback_category'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: const Key('feedback_category_dropdown'),
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'general',
                    child: Text(context.tr('category_general')),
                  ),
                  DropdownMenuItem(
                    value: 'bug',
                    child: Text(context.tr('category_bug')),
                  ),
                  DropdownMenuItem(
                    value: 'suggestion',
                    child: Text(context.tr('category_suggestion')),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              // ── Message Textbox ────────────────────────────────────────
              Text(
                context.tr('send_feedback'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('feedback_message_field'),
                controller: _messageController,
                maxLines: 6,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: context.tr('feedback_hint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return context.tr('feedback_empty_error');
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // ── Submit Button ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('feedback_submit_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    context.tr('feedback_submit'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: _isSubmitting ? null : _submitFeedback,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
