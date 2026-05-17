import 'package:flutter/foundation.dart';

class ProductsRefresh {
  ProductsRefresh._();

  static final ValueNotifier<int> counter = ValueNotifier<int>(0);

  static void bump() {
    counter.value = counter.value + 1;
  }
}
