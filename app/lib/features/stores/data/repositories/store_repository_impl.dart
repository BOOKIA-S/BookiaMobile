import 'package:bookia_mobile/core/network/api_client.dart';
import 'package:bookia_mobile/features/stores/data/dto/store_detail_dto.dart';
import 'package:bookia_mobile/features/stores/data/mappers/store_detail_mapper.dart';
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
}
