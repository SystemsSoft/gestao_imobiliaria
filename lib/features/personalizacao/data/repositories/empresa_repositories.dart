import 'dart:convert';
import 'dart:typed_data';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/json.dart';
import '../../../../core/config/empresa_info.dart';
import '../../domain/repositories/empresa_repository.dart';

/// Sem servidor (testes): guarda em memória.
class EmpresaMemoryRepository implements EmpresaRepository {
  DadosEmpresa _dados = DadosEmpresa.padrao;
  Uint8List? _logo;

  @override
  Future<DadosEmpresa> obter() async => _dados;

  @override
  Future<void> salvar(DadosEmpresa dados) async => _dados = dados;

  @override
  Future<Uint8List?> obterLogo() async => _logo;

  @override
  Future<void> salvarLogo(Uint8List imagem) async => _logo = imagem;

  @override
  Future<void> removerLogo() async => _logo = null;
}

Map<String, Object?> empresaParaJson(DadosEmpresa d) => {
  'nome': d.nome,
  'atividade': d.atividade,
  'creci': d.creci,
  'documento': d.documento,
  'endereco': d.endereco,
  'telefone': d.telefone,
  'email': d.email,
  'site': d.site,
  'chavePix': d.chavePix,
};

DadosEmpresa empresaDeJson(Map<String, dynamic> j) => DadosEmpresa(
  nome: lerTexto(j['nome']),
  atividade: lerTexto(j['atividade']),
  creci: lerTexto(j['creci']),
  documento: lerTexto(j['documento']),
  endereco: lerTexto(j['endereco']),
  telefone: lerTexto(j['telefone']),
  email: lerTexto(j['email']),
  site: lerTexto(j['site']),
  chavePix: lerTexto(j['chavePix']),
);

/// Personalização no servidor (`/api/v1/personalizacao`).
class EmpresaApiRepository implements EmpresaRepository {
  const EmpresaApiRepository(this._api);
  final ApiClient _api;

  @override
  Future<DadosEmpresa> obter() async => empresaDeJson(
    await _api.get('personalizacao/empresa') as Map<String, dynamic>,
  );

  @override
  Future<void> salvar(DadosEmpresa dados) =>
      _api.put('personalizacao/empresa', empresaParaJson(dados));

  @override
  Future<Uint8List?> obterLogo() async {
    try {
      final j = await _api.get('personalizacao/logo') as Map<String, dynamic>;
      return base64Decode(j['base64'] as String);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null; // sem logotipo personalizado
      rethrow;
    }
  }

  @override
  Future<void> salvarLogo(Uint8List imagem) => _api.put('personalizacao/logo', {
    'tipo': imagem.first == 0x89 ? 'image/png' : 'image/jpeg',
    'base64': base64Encode(imagem),
  });

  @override
  Future<void> removerLogo() => _api.delete('personalizacao/logo');
}
