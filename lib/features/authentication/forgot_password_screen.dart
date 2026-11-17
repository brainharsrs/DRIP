import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/components/buttons.dart';
import '../../core/components/fields.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/providers.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  bool _loading = false;
  bool _tried = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) {
      setState(() => _tried = true);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Não foi possível enviar agora. Tente de novo.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final canReset = ref.watch(authRepositoryProvider).canResetPassword;

    if (_sent) {
      return AuthScaffold(
        word: 'ENVIADO',
        spokenTitle: 'Link enviado',
        lead:
            'Se existir uma conta com ${_email.text.trim()}, você vai receber '
            'um e-mail com o link para criar uma nova senha. Confira também a '
            'caixa de spam.',
        showBack: true,
        children: [
          DripButton(label: 'Voltar para o login', onTap: () => context.pop()),
        ],
      );
    }

    return AuthScaffold(
      word: 'SENHA',
      spokenTitle: 'Recuperar senha',
      lead: canReset
          ? 'Informe o e-mail da sua conta. Enviamos um link para você criar '
                'uma nova senha.'
          : 'A recuperação por e-mail precisa do servidor (Firebase), que '
                'ainda não está configurado neste aparelho.',
      showBack: true,
      children: [
        Form(
          key: _form,
          autovalidateMode: _tried
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DripField(
                label: 'E-mail',
                hint: 'nome@email.com',
                controller: _email,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                onSubmitted: (_) => _submit(),
                enabled: !_loading && canReset,
              ),
              const SizedBox(height: Space.x5),
              ErrorBanner(_error),
              DripButton(
                label: 'Enviar link',
                loading: _loading,
                onTap: canReset ? _submit : null,
              ),
            ],
          ),
        ),
        if (!canReset) ...[
          const SizedBox(height: Space.x4),
          Text(
            'No modo demonstração, crie uma nova conta para continuar testando.',
            style: DripType.footnote.copyWith(color: c.textFaint),
          ),
        ],
      ],
    );
  }
}
