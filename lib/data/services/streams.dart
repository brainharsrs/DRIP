import 'dart:async';

/// Stream que entrega primeiro o valor atual e depois as mudanças.
///
/// A inscrição em [changes] acontece no mesmo instante em que alguém começa a
/// ouvir, então nenhuma mudança se perde entre o valor inicial e as seguintes.
Stream<T> seededStream<T>(T Function() current, Stream<T> changes) {
  late final StreamController<T> controller;
  StreamSubscription<T>? sub;
  controller = StreamController<T>(
    onListen: () {
      controller.add(current());
      sub = changes.listen(controller.add, onError: controller.addError);
    },
    onCancel: () => sub?.cancel(),
  );
  return controller.stream;
}
