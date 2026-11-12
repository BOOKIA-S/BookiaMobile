import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

/// Profile tab entry until the S04 profile screen is available.
class AuthEntryPage extends ConsumerWidget {
  const AuthEntryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authControllerProvider);
    final session = ref.read(authControllerProvider.notifier).currentSession;
    if (session == null) return const AuthPage();
    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sesión iniciada: ${session.user.name}'),
            TextButton(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).logout(),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _staff = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (ref.read(authControllerProvider).isLoading ||
        !_form.currentState!.validate()) {
      return;
    }
    final controller = ref.read(authControllerProvider.notifier);
    if (_register) {
      controller.register(
        _name.text.trim(),
        _email.text.trim(),
        _password.text,
      );
    } else {
      controller.login(_email.text.trim(), _password.text, staff: _staff);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      if (next.asData?.value != null &&
          GoRouterState.of(context).uri.path == '/auth') {
        context.go('/profile');
      }
    });
    final session = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _register
              ? 'Crear cuenta'
              : _staff
              ? 'Acceso staff'
              : 'Iniciar sesión',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Para reservar libros y guardar favoritos. Buscar no requiere cuenta.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (_register) ...[
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Escribe tu nombre'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) =>
                          value == null ||
                              !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(value.trim())
                          ? 'Escribe un correo válido'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _password,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                      ),
                      obscureText: true,
                      autofillHints: [
                        _register
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      validator: (value) =>
                          value == null ||
                              value.length < 8 ||
                              value.length > 200
                          ? 'La contraseña debe tener entre 8 y 200 caracteres'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (session.isLoading)
                      const Center(child: CircularProgressIndicator()),
                    if (session.hasError && !session.isLoading)
                      Text(switch (session.error) {
                        UnauthorizedFailure() =>
                          'Correo o contraseña incorrectos.',
                        ConflictFailure() => 'Este correo ya está registrado.',
                        RateLimitFailure() =>
                          'Demasiados intentos. Espera unos minutos.',
                        _ =>
                          'No pudimos completar el acceso. Intenta de nuevo.',
                      }, style: TextStyle(color: theme.colorScheme.error)),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton(
                      onPressed: session.isLoading ? null : _submit,
                      child: Text(
                        _register ? 'Crear cuenta' : 'Iniciar sesión',
                      ),
                    ),
                    TextButton(
                      onPressed: session.isLoading
                          ? null
                          : () => setState(() {
                              _register = !_register;
                              _staff = false;
                            }),
                      child: Text(
                        _register ? 'Ya tengo cuenta' : 'Crear cuenta',
                      ),
                    ),
                    if (!_register)
                      TextButton(
                        onPressed: session.isLoading
                            ? null
                            : () => setState(() => _staff = !_staff),
                        child: Text(
                          _staff ? 'Acceso para lectores' : 'Acceso staff',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
