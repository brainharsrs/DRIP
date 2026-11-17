import 'package:url_launcher/url_launcher.dart';

/// Validação e abertura de links externos (sites oficiais das marcas).
abstract final class Links {
  /// Aceita apenas `http`/`https` com um domínio de verdade.
  /// Devolve `null` para vazio, malformado ou esquemas não permitidos
  /// (`javascript:`, `file:`, `tel:` etc.).
  static Uri? parse(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty || text.contains(' ')) return null;
    final uri = Uri.tryParse(text);
    if (uri == null) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    if (uri.host.isEmpty || !uri.host.contains('.')) return null;
    return uri;
  }

  /// Domínio enxuto para mostrar na interface: "marca.com".
  static String host(Uri uri) => uri.host.replaceFirst(RegExp(r'^www\.'), '');
}

/// Abre um link fora do app. Devolve `false` se não foi possível.
typedef LinkOpener = Future<bool> Function(Uri uri);

Future<bool> openExternalLink(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
