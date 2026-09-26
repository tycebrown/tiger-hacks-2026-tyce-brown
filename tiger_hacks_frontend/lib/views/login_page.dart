import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiger_hacks_frontend/model/api_service.dart';
import 'package:tiger_hacks_frontend/model/global_state.dart';
import 'package:tiger_hacks_frontend/model/user.dart';
import 'package:tiger_hacks_frontend/views/caretaker/caretaker_main_view.dart';
import 'package:tiger_hacks_frontend/views/personal/personal_main_view.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  late GlobalState globalState;
  late BuildContext bctx;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final user = await ApiService.login(username, _passwordController.text);
    if (user == null) {
      setState(() => _error = 'User does not exist.');
      return;
    }

    setState(() => _error = null);
    this.globalState.user = user;
    await redirect();
  }

  Future<bool> _userExists(String username) async {
    // Replace with a user lookup when authentication is connected.
    return true;
  }

  Future<void> redirect() async {
    if (this.globalState.user == null) {
      throw new Exception("Wtf??? login page, globalstate user == null");
    }
    switch (this.globalState.user!.role) {
      case .individual:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PersonalMainView()),
        );
        break;
      case .caretaker:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CaretakerMainView()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    this.globalState = context.read<GlobalState>();
    this.bctx = context;
    if (this.globalState.user != null) {
      redirect();
      return Scaffold(body: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Log in')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    textInputAction: TextInputAction.next,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your username'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your password'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Text('Log in'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
