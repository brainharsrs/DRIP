import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/routes.dart';
import '../../core/components/buttons.dart';
import '../../core/components/fields.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/providers.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_widgets.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final _terms = TapGestureRecognizer()
    ..onTap = () => context.push(Routes.legal('termos'));
  late final _privacy = TapGestureRecognizer()
    ..onTap = () => context.push(Routes.legal('privacidade'));
  bool _loading = false;
  bool _tried = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) {
      // Depois da 1ª tentativa, cada erro some assim que o campo é corrigido.
      setState(() => _tried = true);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signUp(
            name: _name.text,
            email: _email.text,
            password: _password.text,
          );
      // Conta criada = sessão aberta: o roteador leva para o Discover.
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Não foi possível criar a conta agora. Tente de novo.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final link = DripType.footnote.copyWith(
      color: c.text,
      decoration: TextDecoration.underline,
      decorationColor: c.textMuted,
    );

    return AuthScaffold(
      word: 'CADASTRO',
      spokenTitle: 'Criar conta',
      lead: 'Uma conta guarda sua Want List e as marcas que você acompanha.',
      showBack: true,
      children: [
        Form(
          key: _form,
          autovalidateMode: _tried
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DripField(
                  label: 'Nome',
                  hint: 'Como quer ser chamado',
                  controller: _name,
                  validator: Validators.name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  maxLength: 60,
                  enabled: !_loading,
                ),
                const SizedBox(height: Space.x4),
                DripField(
                  label: 'E-mail',
                  hint: 'nome@email.com',
                  controller: _email,
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  enabled: !_loading,
                ),
                const SizedBox(height: Space.x4),
                DripField(
                  label: 'Senha',
                  showStrength: true,
                  controller: _password,
                  validator: Validators.newPassword,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => _submit(),
                  enabled: !_loading,
                ),
                const SizedBox(height: Space.x5),
                ErrorBanner(_error),
                DripButton(
                  label: 'Criar conta',
                  loading: _loading,
                  onTap: _submit,
                ),
              ],
            ),
          ),
        ),
        GoogleSignInSection(enabled: !_loading),
        const SizedBox(height: Space.x4),
        Text.rich(
          TextSpan(
            style: DripType.footnote.copyWith(color: c.textFaint),
            children: [
              const TextSpan(text: 'Ao criar a conta, você concorda com os '),
              TextSpan(text: 'Termos de uso', style: link, recognizer: _terms),
              const TextSpan(text: ' e a '),
              TextSpan(
                text: 'Política de privacidade',
                style: link,
                recognizer: _privacy,
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: Space.x4),
        LinkLine(
          text: 'Já tem conta?',
          link: 'Entrar',
          onTap: () => context.pop(),
        ),
        const DemoNotice(),
      ],
    );
  }
}
