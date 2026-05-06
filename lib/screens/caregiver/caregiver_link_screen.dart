import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/caregiver_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class CaregiverLinkScreen extends StatefulWidget {
  const CaregiverLinkScreen({super.key});

  @override
  State<CaregiverLinkScreen> createState() => _CaregiverLinkScreenState();
}

class _CaregiverLinkScreenState extends State<CaregiverLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final caregiverId = context.read<AuthProvider>().currentUser?.id;
    if (caregiverId == null) return;
    final provider = context.read<CaregiverProvider>();
    await provider.linkPatient(caregiverId, _email.text);
    if (!mounted) return;
    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaregiverProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Link Patient')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                label: 'Patient email',
                hint: 'patient@example.com',
                prefixIcon: Icons.mail_outline,
                controller: _email,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Link',
                isLoading: provider.isLoading,
                onPressed: provider.isLoading ? null : _link,
                semanticsLabel: 'Link patient',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

