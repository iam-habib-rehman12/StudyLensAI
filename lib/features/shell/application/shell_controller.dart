import 'package:flutter/foundation.dart';

class ShellController extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void select(int index) {
    if (index < 0 || index > 4 || index == _selectedIndex) return;
    _selectedIndex = index;
    notifyListeners();
  }

  void reset() => select(0);
}
