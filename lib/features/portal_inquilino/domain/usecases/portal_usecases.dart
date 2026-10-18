import '../../../../core/arquivos/arquivo_repository.dart';
import '../../../../core/errors/domain_exception.dart';
import '../../../../core/utils/id.dart';
import '../entities/portal.dart';
import '../repositories/portal_repository.dart';

/// Publica um documento da imobiliária no contrato (envia o arquivo e o
/// deixa visível para o inquilino, que recebe um aviso).
class PublicarDocumentoContrato {
  const PublicarDocumentoContrato(this._portal, this._arquivos);
  final PortalInquilinoRepository _portal;
  final ArquivoRepository _arquivos;

  Future<void> call({
    required String contratoId,
    required TipoArquivoContrato tipo,
    required String titulo,
    required ArquivoEscolhido arquivo,
    bool visivelInquilino = true,
  }) async {
    if (!TipoArquivoContrato.daImobiliaria.contains(tipo)) {
      throw const DomainException('Tipo de documento inválido.');
    }
    final nome = titulo.trim().isEmpty ? tipo.label : titulo.trim();
    CategoriaArquivo.arquivo.validar(arquivo.nome, arquivo.tamanho);
    final enviado = await _arquivos.enviar(
      bytes: await arquivo.ler(),
      nome: arquivo.nome,
      categoria: CategoriaArquivo.arquivo,
    );
    await _portal.salvarArquivo(
      ArquivoContrato(
        id: gerarId(),
        contratoId: contratoId,
        tipo: tipo,
        titulo: nome,
        referencia: enviado.referencia,
        visivelInquilino: visivelInquilino,
        criadoEm: DateTime.now(),
      ),
    );
  }
}

class EnviarComunicado {
  const EnviarComunicado(this._portal);
  final PortalInquilinoRepository _portal;

  Future<void> call({
    String? contratoId,
    required String titulo,
    required String mensagem,
  }) async {
    if (titulo.trim().isEmpty || mensagem.trim().isEmpty) {
      throw const DomainException('Informe o título e a mensagem do aviso.');
    }
    await _portal.enviarComunicado(
      contratoId: contratoId,
      titulo: titulo.trim(),
      mensagem: mensagem.trim(),
    );
  }
}

/// Texto pronto para mandar ao inquilino (WhatsApp/e-mail) com o acesso.
String mensagemDeAcesso({
  required String nome,
  required String enderecoSite,
  required SenhaProvisoria senha,
}) =>
    'Olá, ${nome.split(' ').first}! Seu acesso à Área do inquilino está '
    'liberado.\n\nEndereço: $enderecoSite/inquilino\nLogin (CPF/CNPJ): '
    '${senha.login}\nSenha provisória: ${senha.senha}\n\nNo primeiro acesso '
    'você vai criar a sua senha. Lá você encontra boletos, pagamentos, '
    'contrato, vistoria, chamados de manutenção e nossos avisos.';
