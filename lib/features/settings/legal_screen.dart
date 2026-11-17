import 'package:material_ui/material_ui.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import 'settings_widgets.dart';

class _Section {
  const _Section(this.title, this.body);
  final String title;
  final String body;
}

// RASCUNHO. Os textos abaixo descrevem o funcionamento real do app, mas
// precisam de revisão jurídica antes da publicação nas lojas.
const _terms = [
  _Section(
    'O que é o DRIP',
    'O DRIP é um radar de lançamentos de sneakers e streetwear. Reunimos '
        'datas, informações e links oficiais para você acompanhar os drops '
        'que interessam.',
  ),
  _Section(
    'O DRIP não vende produtos',
    'Não há carrinho, pagamento ou entrega dentro do aplicativo. O botão '
        '"Comprar no site da marca" abre o site oficial da marca, fora do '
        'DRIP. A compra, o preço final, o estoque e a entrega são de '
        'responsabilidade de cada marca.',
  ),
  _Section(
    'Datas e preços',
    'As informações são cadastradas pela equipe do DRIP a partir do que as '
        'marcas divulgam e podem mudar sem aviso. Confirme sempre no site '
        'oficial antes de comprar.',
  ),
  _Section(
    'Sua conta',
    'Você é responsável por manter sua senha em segurança. Pode sair ou '
        'excluir sua conta a qualquer momento em Configurações.',
  ),
  _Section(
    'Marcas e imagens',
    'Nomes, logotipos e imagens pertencem aos respectivos titulares e são '
        'usados apenas para identificar os lançamentos.',
  ),
];

const _privacy = [
  _Section(
    'O que guardamos',
    'Seu nome e e-mail, os drops que você salvou na Want List, as marcas '
        'que você acompanha, suas categorias de interesse e suas '
        'preferências de notificação.',
  ),
  _Section(
    'Para que usamos',
    'Para manter sua lista sincronizada entre aparelhos e avisar você '
        'sobre os lançamentos que escolheu acompanhar. Não vendemos seus '
        'dados.',
  ),
  _Section(
    'Notificações',
    'Se você ativar as notificações push, guardamos um identificador do '
        'seu aparelho para conseguir enviar os avisos. Você pode desativar '
        'nos ajustes do sistema quando quiser.',
  ),
  _Section(
    'Onde ficam os dados',
    'Na infraestrutura do Firebase (Google). No modo demonstração, tudo '
        'fica guardado apenas no seu aparelho.',
  ),
  _Section(
    'Como apagar',
    'Em Configurações, "Excluir minha conta" apaga sua conta e todos os '
        'dados ligados a ela. Dúvidas: ${AppConfig.supportEmail}.',
  ),
];

/// Termos de uso e política de privacidade.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});

  /// `termos` ou `privacidade`.
  final String doc;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final privacy = doc == 'privacidade';
    final sections = privacy ? _privacy : _terms;
    return SubPage(
      title: privacy ? 'Política de privacidade' : 'Termos de uso',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Space.x3 + 2),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Text(
                  'Versão preliminar. Este texto ainda passa por revisão '
                  'jurídica antes do lançamento do app.',
                  style: DripType.caption.copyWith(color: c.textMuted),
                ),
              ),
              for (final s in sections) ...[
                const SizedBox(height: Space.x6),
                Semantics(
                  header: true,
                  child: Text(
                    s.title,
                    style: DripType.headline.copyWith(color: c.text),
                  ),
                ),
                const SizedBox(height: Space.x2),
                Text(s.body, style: DripType.bodyL.copyWith(color: c.text)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
