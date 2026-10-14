import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokedex_app/shared/repositories/model_3d_repository.dart';

void main() {
  test('returns the first candidate that exists and caches the answer',
      () async {
    final requested = <String>[];
    final repo = Model3dRepository(
      baseUrl: 'https://models.test/',
      client: MockClient((req) async {
        requested.add(req.url.path);
        expect(req.method, 'HEAD');
        return http.Response('', req.url.path.endsWith('/25-M.glb') ? 200 : 404);
      }),
    );

    expect(await repo.findModel(25), 'https://models.test/25-M.glb');
    expect(requested, ['/25.glb', '/25-M.glb']);

    expect(await repo.findModel(25), 'https://models.test/25-M.glb');
    expect(requested, hasLength(2));
  });

  test('null when nothing exists or the network fails', () async {
    final none = Model3dRepository(
      client: MockClient((_) async => http.Response('', 404)),
    );
    expect(await none.findModel(1), isNull);

    final offline = Model3dRepository(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    expect(await offline.findModel(2), isNull);
  });
}
