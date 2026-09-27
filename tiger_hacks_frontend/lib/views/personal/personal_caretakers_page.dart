import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiger_hacks_frontend/model/api_models.dart';
import 'package:tiger_hacks_frontend/model/api_service.dart';
import 'package:tiger_hacks_frontend/model/global_state.dart';

class PersonalCaretakersPage extends StatefulWidget {
  const PersonalCaretakersPage({super.key});

  @override
  State<PersonalCaretakersPage> createState() => _PersonalCaretakersPageState();
}

class _PersonalCaretakersPageState extends State<PersonalCaretakersPage> {
  int? _userId;
  bool _userInitialized = false;
  Future<List<SharedUserModel>>? _caretakersFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.watch<GlobalState>().user?.id;
    if (!_userInitialized || userId != _userId) {
      _userInitialized = true;
      _userId = userId;
      _caretakersFuture = userId == null
          ? null
          : ApiService.getCaretakers(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;
    if (userId == null) {
      return const Center(child: Text('Log in to view caretakers.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: _inviteCaretaker,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Invite caretaker'),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<SharedUserModel>>(
            future: _caretakersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Could not load caretakers.'));
              }
              final caretakers = snapshot.data ?? const <SharedUserModel>[];
              if (caretakers.isEmpty) {
                return const Center(
                  child: Text('No caretakers are linked to your account.'),
                );
              }
              return _buildCaretakersView(caretakers);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _inviteCaretaker() async {
    final userId = _userId;
    if (userId == null) return;

    final usernameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var isSubmitting = false;
    String? errorMessage;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Invite caretaker'),
            content: SizedBox(
              width: 360,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: usernameController,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Caretaker username',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter an existing caretaker username'
                          : null,
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        setDialogState(() {
                          isSubmitting = true;
                          errorMessage = null;
                        });
                        try {
                          await ApiService.shareUser(
                            userId: userId,
                            caretakerUsername: usernameController.text.trim(),
                          );
                          Navigator.pop(dialogContext);
                        } catch (error) {
                          if (!dialogContext.mounted) return;
                          setDialogState(() {
                            isSubmitting = false;
                            errorMessage = 'Could not invite caretaker: $error';
                          });
                        }
                      },
                icon: isSubmitting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1),
                label: const Text('Invite'),
              ),
            ],
          ),
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final caretakersFuture = ApiService.getCaretakers(userId);
        if (!mounted) return;
        setState(() {
          _caretakersFuture = caretakersFuture;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Caretaker added.')));
      });
    } finally {
      usernameController.dispose();
    }
  }

  Widget _buildCaretakersView(List<SharedUserModel> caretakers) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: caretakers.length,
      itemBuilder: (context, index) {
        final caretaker = caretakers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: ListTile(
              leading: CircleAvatar(
                radius: 28,
                child: Icon(Icons.medical_services_outlined, size: 28),
              ),
              title: Text(
                caretaker.username,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${caretaker.role.name[0].toUpperCase()}${caretaker.role.name.substring(1)}'
                  '  ·  Connection #${caretaker.sharepointId}',
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
