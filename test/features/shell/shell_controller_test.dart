import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/features/shell/application/shell_controller.dart';

void main() {
  test('selects valid destinations and ignores invalid indexes', () {
    final controller = ShellController();

    controller.select(3);
    expect(controller.selectedIndex, 3);

    controller.select(8);
    expect(controller.selectedIndex, 3);

    controller.reset();
    expect(controller.selectedIndex, 0);
  });
}
