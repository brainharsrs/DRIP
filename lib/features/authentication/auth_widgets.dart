import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/components/buttons.dart';
import '../../core/components/drip_icon.dart';
import '../../core/components/loading.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/components/wordmark.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';

/// Moldura das telas de entrada: palavra-título, frase de apoio e formulário.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.word,
    required this.spokenTitle,
    required this.lead,
    required this.children,
    this.showBack = false,
  });

  /// Título em tipografia gigante (uma palavra curta).
  final String word;

  /// Título lido pelo leitor de tela.
  final String spokenTitle;
  final String lead;
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                Space.x6,
                Space.x2,
                Space.x6,
                Space.x6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 44,
                    child: showBack
                        ? Transform.translate(
                            offset: const Offset(-10, 0),
                            child: IconPill(
                              glyph: DripGlyph.arrowLeft,
                              label: 'Voltar',
                              onTap: () => context.pop(),
                            ),
                          )
                        : const Align(
                            alignment: Alignment.centerLeft,
                            child: DripWordmark(height: 18),
                          ),
                  ),
                  const SizedBox(height: Space.x10),
                  Semantics(
                    header: true,
                    label: spokenTitle,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: GiantWord(
                        word,
                        color: c.text,
                        height: 58,
                        entrance: GiantEntrance.rise,
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.x4),
                  Text(
                    lead,
                    style: DripType.bodyL.copyWith(color: c.textMuted),
                  ),
                  const SizedBox(height: Space.x8),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mensagem de erro do formulário: aparece acima do botão e é anunciada
/// pelo leitor de tela.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = message;
    return SoftSize(
      child: text == null
          ? const SizedBox(width: double.infinity)
          : Semantics(
              liveRegion: true,
              container: true,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: Space.x4),
                padding: const EdgeInsets.all(Space.x3 + 2),
                decoration: BoxDecoration(
                  color: c.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: DripIcon(
                        DripGlyph.info,
                        size: 18,
                        color: c.danger,
                      ),
                    ),
                    const SizedBox(width: Space.x2 + 2),
                    Expanded(
                      child: Text(
                        text,
                        style: DripType.caption.copyWith(color: c.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Divisor "ou" + botão "Continuar com Google", com seu próprio estado de
/// carregamento e de erro. Some no modo demonstração (sem Firebase).
class GoogleSignInSection extends ConsumerStatefulWidget {
  const GoogleSignInSection({super.key, this.enabled = true});

  /// `false` enquanto o formulário de e-mail e senha está enviando.
  final bool enabled;

  @override
  ConsumerState<GoogleSignInSection> createState() =>
      _GoogleSignInSectionState();
}

class _GoogleSignInSectionState extends ConsumerState<GoogleSignInSection> {
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      // Com a sessão aberta, o roteador leva sozinho para o Discover.
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Não foi possível entrar com o Google agora. Tente de novo.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(authRepositoryProvider).canUseGoogle) {
      return const SizedBox.shrink();
    }
    final c = context.c;
    final line = Expanded(child: Container(height: 1, color: c.line));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.x4),
          child: ExcludeSemantics(
            child: Row(
              children: [
                line,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.x3),
                  child: Text(
                    'ou',
                    style: DripType.caption.copyWith(color: c.textFaint),
                  ),
                ),
                line,
              ],
            ),
          ),
        ),
        ErrorBanner(_error),
        Pressable(
          onTap: _loading || !widget.enabled ? null : _signIn,
          disabledOpacity: _loading ? 1 : 0.4,
          semanticLabel: _loading
              ? 'Continuar com Google, carregando'
              : 'Continuar com Google',
          focusRadius: Radii.pill,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Radii.pill),
              border: Border.all(color: c.line),
            ),
            child: AnimatedSwitcher(
              duration: Motion.base,
              child: _loading
                  ? DripLoader(key: const ValueKey('loading'), color: c.text)
                  : Row(
                      key: const ValueKey('content'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const GoogleMark(size: 20),
                        const SizedBox(width: Space.x3),
                        Flexible(
                          child: Text(
                            'Continuar com Google',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DripType.button.copyWith(color: c.text),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// O "G" de quatro cores do Google, desenhado em vetor.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const _GoogleMarkPainter());
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.2;
    final rect = Rect.fromCircle(
      center: Offset(s / 2, s / 2),
      radius: (s - stroke) / 2,
    );
    const deg = math.pi / 180;
    void arc(Color color, double start, double sweep) => canvas.drawArc(
      rect,
      start * deg,
      sweep * deg,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    // Ângulos em graus, sentido horário a partir das "3 horas".
    arc(_red, 190, 115);
    arc(_yellow, 145, 46);
    arc(_green, 45, 101);
    arc(_blue, -2, 48);
    // Barra horizontal do "G".
    canvas.drawRect(
      Rect.fromLTWH(s / 2, s / 2 - stroke / 2, s / 2 - s * 0.02, stroke),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GoogleMarkPainter old) => false;
}

/// Frase com um link ao lado: "Novo por aqui? Criar conta".
class LinkLine extends StatelessWidget {
  const LinkLine({
    super.key,
    required this.text,
    required this.link,
    required this.onTap,
  });

  final String text;
  final String link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    // Wrap: com letra grande, o link desce para a linha de baixo em vez de
    // estourar a largura.
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text, style: DripType.body.copyWith(color: c.textMuted)),
        Pressable(
          onTap: onTap,
          semanticLabel: link,
          child: Center(
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                link,
                style: DripType.button.copyWith(
                  color: c.text,
                  decoration: TextDecoration.underline,
                  decorationColor: c.textMuted,
                  decorationThickness: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Aviso discreto de que o app está sem servidor (dados só no aparelho).
class DemoNotice extends ConsumerWidget {
  const DemoNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(firebaseReadyProvider)) return const SizedBox.shrink();
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(top: Space.x6),
      child: Text(
        'Modo demonstração: a conta e os dados ficam guardados só neste '
        'aparelho, sem servidor.',
        style: DripType.footnote.copyWith(color: c.textFaint),
      ),
    );
  }
}
