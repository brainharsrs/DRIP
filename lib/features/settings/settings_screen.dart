import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/routes.dart';
import '../../core/components/buttons.dart';
import '../../core/components/fields.dart';
import '../../core/components/surfaces.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../data/models/user.dart';
import '../../data/providers.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/push_service.dart';
import '../authentication/auth_widgets.dart';
import 'settings_widgets.dart';

/// Configurações: conta, notificações, aparência, privacidade e sessão.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final data = ref.watch(userDataProvider);
    final auth = ref.watch(authRepositoryProvider);
    final demo = !ref.watch(firebaseReadyProvider);
    final actions = ref.read(userActionsProvider);

    Future<void> resetPassword() async {
      final email = user?.email;
      if (email == null) return;
      try {
        await auth.sendPasswordReset(email);
        if (context.mounted) {
          showToast(context, 'Enviamos o link de redefinição para $email.');
        }
      } on AuthFailure catch (e) {
        if (context.mounted) showToast(context, e.message);
      }
    }

    Future<void> signOut() async {
      final ok = await confirmSheet(
        context,
        title: 'Sair da conta?',
        message:
            'Sua Want List e as marcas que você acompanha continuam '
            'guardadas. É só entrar de novo para vê-las.',
        confirmLabel: 'Sair',
      );
      if (ok) await auth.signOut();
    }

    return SubPage(
      title: 'Configurações',
      children: [
        SettingsGroup(
          title: 'Conta',
          children: [
            SettingsRow(
              title: 'Nome',
              value: user?.name ?? '',
              onTap: () => showDripSheet<void>(
                context: context,
                title: 'Seu nome',
                builder: (_) => _EditNameSheet(initial: user?.name ?? ''),
              ),
            ),
            SettingsRow(title: 'E-mail', value: user?.email ?? ''),
            SettingsRow(
              title: 'Redefinir senha',
              subtitle: auth.canResetPassword
                  ? 'Enviamos um link para o seu e-mail'
                  : 'Disponível quando o servidor estiver configurado',
              onTap: auth.canResetPassword ? resetPassword : null,
            ),
          ],
        ),
        SettingsGroup(
          title: 'Notificações',
          footer:
              'Estas escolhas valem para os avisos da aba Atividade e para '
              'as notificações push.',
          children: [
            const _PushRow(),
            for (final pref in NotifPref.values)
              SettingsSwitchRow(
                title: pref.title,
                subtitle: pref.subtitle,
                value: data.notifEnabled(pref),
                onChanged: (v) => actions.setNotifPref(pref, v),
              ),
          ],
        ),
        SettingsGroup(
          title: 'Aparência',
          footer: 'O tema escuro é a direção visual do DRIP.',
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.x3),
              child: Segmented<ThemeMode>(
                value: ref.watch(themeModeProvider),
                onChanged: ref.read(themeModeProvider.notifier).set,
                options: const [
                  (ThemeMode.dark, 'Escuro'),
                  (ThemeMode.light, 'Claro'),
                  (ThemeMode.system, 'Sistema'),
                ],
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Privacidade',
          footer:
              'Guardamos só o necessário: nome, e-mail, o que você salvou e '
              'as marcas que acompanha.',
          children: [
            SettingsRow(
              title: 'Política de privacidade',
              onTap: () => context.push(Routes.legal('privacidade')),
            ),
            SettingsRow(
              title: 'Excluir minha conta',
              subtitle: 'Apaga a conta e todos os seus dados',
              danger: true,
              onTap: () => showDripSheet<void>(
                context: context,
                title: 'Excluir conta',
                builder: (_) => const _DeleteAccountSheet(),
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Sobre',
          children: [
            SettingsRow(
              title: 'Termos de uso',
              onTap: () => context.push(Routes.legal('termos')),
            ),
            const SettingsRow(title: 'Versão', value: AppConfig.version),
            SettingsRow(
              title: 'Dados',
              value: demo ? 'Modo demonstração' : 'Firebase',
              subtitle: demo
                  ? 'Guardados só neste aparelho'
                  : 'Sincronizados na sua conta',
            ),
          ],
        ),
        SettingsGroup(
          children: [SettingsRow(title: 'Sair', onTap: signOut)],
        ),
      ],
    );
  }
}

/// Estado das notificações push neste aparelho, com o botão para ativar.
class _PushRow extends ConsumerStatefulWidget {
  const _PushRow();

  @override
  ConsumerState<_PushRow> createState() => _PushRowState();
}

class _PushRowState extends ConsumerState<_PushRow> {
  PushStatus? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final status = await ref.read(pushServiceProvider).status();
      if (mounted) setState(() => _status = status);
    } catch (_) {
      if (mounted) setState(() => _status = PushStatus.unavailable);
    }
  }

  Future<void> _enable() async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      final status = await ref.read(pushServiceProvider).enable(uid);
      if (!mounted) return;
      setState(() => _status = status);
      if (status == PushStatus.denied) {
        showToast(
          context,
          'A permissão foi negada. Libere as notificações do DRIP nos '
          'ajustes do sistema.',
        );
      }
    } catch (_) {
      if (mounted) {
        showToast(context, 'Não deu para ativar agora. Tente de novo.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final demo = !ref.watch(firebaseReadyProvider);
    final subtitle = switch (_status) {
      null => 'Verificando…',
      PushStatus.enabled => 'Ativas neste aparelho',
      PushStatus.notAsked => 'Receba o aviso mesmo com o app fechado',
      PushStatus.denied => 'Bloqueadas nos ajustes do sistema',
      PushStatus.unavailable =>
        demo
            ? 'Indisponíveis no modo demonstração'
            : 'Indisponíveis neste aparelho',
    };
    return SettingsRow(
      title: 'Notificações push',
      subtitle: subtitle,
      trailing: _status == PushStatus.notAsked
          ? DripButton(
              label: 'Ativar',
              semanticLabel: 'Ativar notificações push',
              expand: false,
              compact: true,
              loading: _busy,
              onTap: _enable,
            )
          : null,
    );
  }
}

class _EditNameSheet extends ConsumerStatefulWidget {
  const _EditNameSheet({required this.initial});
  final String initial;

  @override
  ConsumerState<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends ConsumerState<_EditNameSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).updateName(_name.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      showToast(context, 'Nome atualizado.');
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DripField(
            label: 'Nome',
            controller: _name,
            validator: Validators.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            maxLength: 60,
            onSubmitted: (_) => _save(),
            enabled: !_saving,
          ),
          const SizedBox(height: Space.x5),
          ErrorBanner(_error),
          DripButton(label: 'Salvar', loading: _saving, onTap: _save),
        ],
      ),
    );
  }
}

/// Exclusão de conta: explica o que será apagado e pede a senha.
class _DeleteAccountSheet extends ConsumerStatefulWidget {
  const _DeleteAccountSheet();

  @override
  ConsumerState<_DeleteAccountSheet> createState() =>
      _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<_DeleteAccountSheet> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!_form.currentState!.validate()) return;
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    final auth = ref.read(authRepositoryProvider);
    final userData = ref.read(userDataRepositoryProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // A senha é conferida primeiro; só então os dados são apagados.
      await auth.deleteAccount(password: _password.text);
      try {
        await userData.deleteAll(uid);
      } catch (_) {
        // No Firebase os dados já foram apagados junto com a conta.
      }
      if (mounted) showToast(context, 'Sua conta foi excluída.');
      // Sem sessão, o roteador volta sozinho para a tela de entrada.
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Não foi possível excluir agora. Tente de novo.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Isto apaga sua conta, sua Want List, as marcas que você '
            'acompanha e suas preferências. Não dá para desfazer.',
            style: DripType.body.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: Space.x5),
          if (ref.watch(authRepositoryProvider).hasPassword)
            DripField(
              label: 'Digite sua senha para confirmar',
              controller: _password,
              validator: Validators.passwordRequired,
              obscure: true,
              textInputAction: TextInputAction.done,
              enabled: !_busy,
            )
          else
            Text(
              'Para confirmar, vamos pedir que você entre de novo com a sua '
              'conta Google.',
              style: DripType.body.copyWith(color: c.text),
            ),
          const SizedBox(height: Space.x5),
          ErrorBanner(_error),
          DripButton(
            label: 'Excluir minha conta',
            background: c.danger,
            foreground: c.onAccent,
            loading: _busy,
            onTap: _delete,
          ),
          const SizedBox(height: Space.x1),
          DripButton(
            label: 'Cancelar',
            kind: DripButtonKind.ghost,
            foreground: c.text,
            onTap: _busy ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
