import 'dart:typed_data';

import '../../../../core/config/empresa_info.dart';
import '../../../../core/errors/domain_exception.dart';
import '../repositories/empresa_repository.dart';

const logoTamanhoMaximo = 2 * 1024 * 1024;

/// PNG ou JPG, pelos primeiros bytes do arquivo.
bool imagemSuportada(Uint8List b) =>
    (b.length > 8 &&
        b[0] == 0x89 &&
        b[1] == 0x50 &&
        b[2] == 0x4E &&
        b[3] == 0x47) ||
    (b.length > 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF);

/// Carrega os dados e o logotipo e passa a usá-los em todos os documentos.
class CarregarPersonalizacao {
  const CarregarPersonalizacao(this._repo);
  final EmpresaRepository _repo;

  Future<void> call() async {
    final dados = await _repo.obter();
    final logo = await _repo.obterLogo();
    EmpresaInfo.aplicar(dados, logo: logo);
  }
}

class SalvarDadosEmpresa {
  const SalvarDadosEmpresa(this._repo);
  final EmpresaRepository _repo;

  Future<void> call(DadosEmpresa d) async {
    if (d.nome.trim().isEmpty) {
      throw const DomainException('Informe o nome da imobiliária.');
    }
    await _repo.salvar(d);
    EmpresaInfo.aplicar(d, logo: EmpresaInfo.logo);
  }
}

class SalvarLogo {
  const SalvarLogo(this._repo);
  final EmpresaRepository _repo;

  Future<void> call(Uint8List imagem) async {
    if (!imagemSuportada(imagem)) {
      throw const DomainException('Use uma imagem PNG ou JPG.');
    }
    if (imagem.length > logoTamanhoMaximo) {
      throw const DomainException('O logotipo deve ter no máximo 2 MB.');
    }
    await _repo.salvarLogo(imagem);
    EmpresaInfo.aplicar(EmpresaInfo.atual, logo: imagem);
  }
}

class RemoverLogo {
  const RemoverLogo(this._repo);
  final EmpresaRepository _repo;

  Future<void> call() async {
    await _repo.removerLogo();
    EmpresaInfo.aplicar(EmpresaInfo.atual);
  }
}
