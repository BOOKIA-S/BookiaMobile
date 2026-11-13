import 'package:bookia_mobile/core/network/api_client.dart';
import 'package:bookia_mobile/features/stores/data/dto/store_detail_dto.dart';
import 'package:bookia_mobile/features/stores/data/dto/store_dto.dart';
import 'package:bookia_mobile/features/stores/data/mappers/store_detail_mapper.dart';
import 'package:bookia_mobile/features/stores/data/mappers/store_mapper.dart';
import 'package:bookia_mobile/features/stores/domain/entities/store.dart';
import 'package:bookia_mobile/features/stores/domain/repositories/store_repository.dart';

/// Repository (PAT-01): the only place that knows the `/stores` endpoints.
class StoreRepositoryImpl implements StoreRepository {
  const StoreRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<StoreDetail> getStore(String id) async {
    final json = await _api.get<Map<String, dynamic>>('/stores/$id');
    return StoreDetailDto.fromJson(json).toEntity();
  }

  @override
  Future<List<Store>> getStores({double? lat, double? lng}) async {
    final nearby = lat != null && lng != null;
    final json = await _api.get<List<dynamic>>(
      nearby ? '/stores/near' : '/stores',
      query: nearby ? {'lat': lat, 'lng': lng} : null,
    );
    return json
        .whereType<Map<String, dynamic>>()
        .map((s) => StoreDto.fromJson(s).toEntity())
        .toList();
  }
}
