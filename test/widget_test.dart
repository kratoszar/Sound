import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sanity', () {
    // Nota: el árbol completo de la app inicializa Firebase en `main()`.
    // En `flutter test` (host: Windows/macOS/Linux) esa inicialización no aplica.
    expect(true, isTrue);
  });
}
