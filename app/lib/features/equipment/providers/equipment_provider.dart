import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';

part 'equipment_provider.g.dart';

class EquipmentItem {
  final int id;
  final String name;
  final int categoryId;
  final String categoryName;
  bool selected;

  EquipmentItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    this.selected = false,
  });
}

@riverpod
Future<List<EquipmentItem>> equipmentCatalog(EquipmentCatalogRef ref) async {
  final lang = 'ru'; // TODO: get from locale
  final catalogResp = await apiDio.get(
    '/api/v1/equipment/',
    options: _langOption(lang),
  );
  final userResp = await apiDio.get(
    '/api/v1/equipment/user',
    options: _langOption(lang),
  );

  final userEquip = userResp.data as List? ?? [];
  final selectedIds = <int>{};
  for (final ue in userEquip) {
    final id = (ue as Map<String, dynamic>)['item_id'] as int?;
    if (id != null) selectedIds.add(id);
  }

  final catalog = catalogResp.data as List? ?? [];
  final items = <EquipmentItem>[];
  for (final cat in catalog) {
    final cm = cat as Map<String, dynamic>;
    final catId = cm['id'] as int;
    final catName = cm['name'] as String;
    for (final item in cm['items'] as List? ?? []) {
      final im = item as Map<String, dynamic>;
      final itemId = im['id'] as int;
      items.add(EquipmentItem(
        id: itemId,
        name: im['name'] as String,
        categoryId: catId,
        categoryName: catName,
        selected: selectedIds.contains(itemId),
      ));
    }
  }
  return items;
}

Future<void> saveUserEquipment(List<EquipmentItem> selected) async {
  final payload = selected.map((e) => {'item_id': e.id}).toList();
  await apiDio.put('/api/v1/equipment/user', data: payload);
}

Options _langOption(String lang) => Options(headers: {'Accept-Language': lang});
