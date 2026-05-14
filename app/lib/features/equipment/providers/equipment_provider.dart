import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';

part 'equipment_provider.g.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class EquipmentOption {
  final int id;
  final String name;
  const EquipmentOption({required this.id, required this.name});
}

class EquipmentItem {
  final int id;
  final String name;
  final int categoryId;
  final String categoryName;
  final List<EquipmentOption> options;
  final Set<int> selectedOptionIds; // populated from user equipment (options)
  bool selected; // true when item selected without options

  EquipmentItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    this.options = const [],
    Set<int>? selectedOptionIds,
    this.selected = false,
  }) : selectedOptionIds = selectedOptionIds ?? {};

  bool get hasOptions => options.isNotEmpty;
}

class EquipmentCategory {
  final int id;
  final String name;
  final List<EquipmentItem> items;

  EquipmentCategory({required this.id, required this.name, required this.items});

  bool get hasOptions => items.any((i) => i.hasOptions);
}

// ─── Providers ───────────────────────────────────────────────────────────────

@riverpod
Future<List<EquipmentItem>> equipmentCatalog(EquipmentCatalogRef ref) async {
  const lang = 'ru'; // TODO: get from locale
  final catalogResp =
      await apiDio.get('/api/v1/equipment/', options: _langOption(lang));
  final userResp =
      await apiDio.get('/api/v1/equipment/user', options: _langOption(lang));

  // Parse user's saved equipment
  final userEquip = userResp.data as List? ?? [];
  final selectedItemIds = <int>{};
  final selectedOptionsByItem = <int, Set<int>>{};
  for (final ue in userEquip) {
    final m = ue as Map<String, dynamic>;
    final itemId = m['item_id'] as int;
    final optionId = m['option_id'] as int?;
    if (optionId != null) {
      selectedOptionsByItem.putIfAbsent(itemId, () => {}).add(optionId);
    } else {
      selectedItemIds.add(itemId);
    }
  }

  // Parse catalog
  final catalog = catalogResp.data as List? ?? [];
  final items = <EquipmentItem>[];
  for (final cat in catalog) {
    final cm = cat as Map<String, dynamic>;
    final catId = cm['id'] as int;
    final catName = cm['name'] as String;
    for (final item in cm['items'] as List? ?? []) {
      final im = item as Map<String, dynamic>;
      final itemId = im['id'] as int;
      final optList = im['options'] as List? ?? [];
      final opts = optList.map((o) {
        final om = o as Map<String, dynamic>;
        return EquipmentOption(id: om['id'] as int, name: om['name'] as String);
      }).toList();
      items.add(EquipmentItem(
        id: itemId,
        name: im['name'] as String,
        categoryId: catId,
        categoryName: catName,
        options: opts,
        selectedOptionIds: selectedOptionsByItem[itemId],
        selected: selectedItemIds.contains(itemId),
      ));
    }
  }
  return items;
}

@riverpod
Future<List<EquipmentCategory>> equipmentCategories(
    EquipmentCategoriesRef ref) async {
  final items = await ref.watch(equipmentCatalogProvider.future);
  final map = <int, EquipmentCategory>{};
  for (final item in items) {
    map
        .putIfAbsent(
          item.categoryId,
          () => EquipmentCategory(
              id: item.categoryId, name: item.categoryName, items: []),
        )
        .items
        .add(item);
  }
  return map.values.toList();
}

// ─── Save ─────────────────────────────────────────────────────────────────────

/// Saves the full equipment selection to the backend.
/// [pickedItems] — item_id → selected (for items without options).
/// [pickedOptions] — item_id → set of selected option_ids (for items with options).
Future<void> saveUserEquipment(
  List<EquipmentItem> allItems,
  Map<int, bool> pickedItems,
  Map<int, Set<int>> pickedOptions,
) async {
  final equipList = <Map<String, dynamic>>[];
  for (final item in allItems) {
    if (item.hasOptions) {
      final opts = pickedOptions[item.id] ?? {};
      for (final optId in opts) {
        equipList.add({
          'category_id': item.categoryId,
          'item_id': item.id,
          'option_id': optId,
        });
      }
    } else {
      if (pickedItems[item.id] == true) {
        equipList.add({
          'category_id': item.categoryId,
          'item_id': item.id,
          'option_id': null,
        });
      }
    }
  }
  await apiDio.put('/api/v1/equipment/user', data: {'equipment': equipList});
}

Options _langOption(String lang) => Options(headers: {'Accept-Language': lang});
