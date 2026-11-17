import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/routes.dart';
import '../../core/components/buttons.dart';
import '../../core/components/fields.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/providers.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _tried = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
          .signIn(email: _email.text, password: _password.text);
      // Com a sessão aberta, o roteador leva sozinho para o Discover.
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Não foi possível entrar agora. Tente de novo.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AuthScaffold(
      word: 'ENTRAR',
      spokenTitle: 'Entrar',
      lead: 'Volte para o radar: seus drops salvos estão esperando.',
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
                  controller: _password,
                  validator: Validators.passwordRequired,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submit(),
                  enabled: !_loading,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Pressable(
                    onTap: () =>
                        context.push(Routes.forgot, extra: _email.text.trim()),
                    semanticLabel: 'Esqueci minha senha',
                    child: Center(
                      widthFactor: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          'Esqueci minha senha',
                          style: DripType.caption.copyWith(color: c.textMuted),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Space.x3),
                ErrorBanner(_error),
                DripButton(label: 'Entrar', loading: _loading, onTap: _submit),
              ],
            ),
          ),
        ),
        GoogleSignInSection(enabled: !_loading),
        const SizedBox(height: Space.x4),
        LinkLine(
          text: 'Novo por aqui?',
          link: 'Criar conta',
          onTap: () => context.push(Routes.signup),
        ),
        const DemoNotice(),
      ],
    );
  }
}
