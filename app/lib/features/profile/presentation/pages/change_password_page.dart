import 'package:bookia_mobile/app/router.dart';
import 'package:bookia_mobile/app/theme/app_spacing.dart';
import 'package:bookia_mobile/core/error/failure.dart';
import 'package:bookia_mobile/core/session/session_providers.dart';
import 'package:bookia_mobile/core/session/session_status.dart';
import 'package:bookia_mobile/features/profile/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen 15 → Cambiar contraseña. Also serves the forced change of a staff
/// account created by an administrator.
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;
  bool _saving = false;
  bool _done = false;
  bool _expired = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final session = ref.read(currentSessionProvider);
    _wasForced = session is SignedInSession && session.mustChangePassword;
  }

  late final bool _wasForced;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
      _expired = false;
    });
    try {
      await ref
          .read(profileProvider.notifier)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _new.text,
          );
      if (mounted) setState(() => _done = true);
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() {
        _expired = failure is UnauthorizedFailure;
        _error = _messageFor(failure);
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _messageFor(Failure failure) {
    if (failure is ValidationFailure &&
        failure.message.toLowerCase().contains('current password')) {
      return 'La contraseña actual es incorrecta.';
    }
    if (failure is UnauthorizedFailure) {
      return 'Tu sesión expiró. Inicia sesión de nuevo.';
    }
    return failure.message;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final role = session is SignedInSession ? session.role : 'reader';
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: _done
          ? _Success(
              staff: AppRoutes.isStaffRole(role),
              onContinue: () => AppRoutes.isStaffRole(role)
                  ? context.go(AppRoutes.staff)
                  : context.go(AppRoutes.profile),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_wasForced)
                          Text(
                            'Tu cuenta necesita una contraseña nueva antes de '
                            'usar el panel de tienda.',
                            style: text.bodyLarge,
                          )
                        else
                          Text(
                            'Usa al menos 8 caracteres. La contraseña nueva '
                            'debe ser distinta de la actual.',
                            style: text.bodyLarge,
                          ),
                        const SizedBox(height: AppSpacing.xl),
                        TextFormField(
                          controller: _current,
                          obscureText: !_show,
                          autofillHints: const [AutofillHints.password],
                          decoration: const InputDecoration(
                            labelText: 'Contraseña actual',
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Escribe tu contraseña actual'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _new,
                          obscureText: !_show,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: const InputDecoration(
                            labelText: 'Contraseña nueva',
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.length < 8 ||
                                value.length > 200) {
                              return 'Debe tener entre 8 y 200 caracteres';
                            }
                            if (value == _current.text) {
                              return 'Debe ser distinta de la actual';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _confirm,
                          obscureText: !_show,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: const InputDecoration(
                            labelText: 'Repite la contraseña nueva',
                          ),
                          validator: (value) => value != _new.text
                              ? 'Las contraseñas no coinciden'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        CheckboxListTile(
                          value: _show,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text('Mostrar contraseñas'),
                          onChanged: (value) =>
                              setState(() => _show = value ?? false),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          onPressed: _saving ? null : _submit,
                          child: Text(
                            _saving ? 'Guardando…' : 'Cambiar contraseña',
                          ),
                        ),
                        if (_expired)
                          TextButton(
                            onPressed: () => context.go(AppRoutes.auth),
                            child: const Text('Iniciar sesión'),
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

class _Success extends StatelessWidget {
  const _Success({required this.staff, required this.onContinue});

  final bool staff;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 56),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Contraseña actualizada',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            staff
                ? 'Ya puedes volver al panel de tienda.'
                : 'La próxima vez usa tu contraseña nueva.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: onContinue,
            child: Text(staff ? 'Ir al panel de tienda' : 'Volver al perfil'),
          ),
        ],
      ),
    ),
  );
}
