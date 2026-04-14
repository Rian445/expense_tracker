import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class CategoryNotifier extends Notifier<Map<String, List<String>>> {
  @override
  Map<String, List<String>> build() {
    final box = Hive.box('categoriesBox');
    final Map<String, List<String>> categories = {};
    for (var key in box.keys) {
      final value = box.get(key);
      if (value is List) {
        categories[key.toString()] = List<String>.from(value);
      }
    }
    return categories;
  }

  void addCategoryOrSubcategory(String category, String? subCategory) {
    final box = Hive.box('categoriesBox');
    final Map<String, List<String>> currentState = Map.from(state);

    if (!currentState.containsKey(category)) {
      currentState[category] = [];
    }

    if (subCategory != null && subCategory.isNotEmpty) {
      if (!currentState[category]!.contains(subCategory)) {
        currentState[category]!.add(subCategory);
      }
    }

    box.put(category, currentState[category]!);
    state = currentState;
  }
}

final categoryProvider = NotifierProvider<CategoryNotifier, Map<String, List<String>>>(() {
  return CategoryNotifier();
});
