import '../../../../core/arquivos/arquivo_repository.dart';
import '../../../../core/errors/domain_exception.dart';
import '../../../../core/utils/id.dart';
import '../../../portal_inquilino/domain/entities/portal.dart';
import '../entities/auditoria.dart';
import '../repositories/auditoria_repository.dart';

/// Nova auditoria (ainda não salva) com o checklist do modelo escolhido.
Auditoria novaAuditoria({
  required String imovelId,
  String? contratoId,
  String? corretorId,
  ModeloChecklist? modelo,
  TipoAuditoria tipo = TipoAuditoria.periodica,
  DateTime? dataAgendada,
}) => Auditoria(
  id: gerarId(),
  imovelId: imovelId,
  contratoId: contratoId,
  corretorId: corretorId,
  tipo: tipo,
  dataAgendada: dataAgendada,
  itens: [
    for (final i in modelo?.itens ?? const <ItemModelo>[])
      ItemAuditoria(id: gerarId(), area: i.area, item: i.item),
  ],
);

/// Envia a foto/vídeo e anexa à auditoria (opcionalmente a um item).
class AnexarMidiaAuditoria {
  const AnexarMidiaAuditoria(this._repo, this._arquivos);
  final AuditoriaRepository _repo;
  final ArquivoRepository _arquivos;

  Future<Auditoria> call(
    Auditoria a, {
    required ArquivoEscolhido arquivo,
    required TipoMidia tipo,
    String titulo = '',
    String? itemId,
  }) async {
    if (a.concluida) {
      throw const DomainException('Reabra a auditoria para anexar mídias.');
    }
    final categoria = tipo == TipoMidia.video
        ? CategoriaArquivo.video
        : CategoriaArquivo.foto;
    categoria.validar(arquivo.nome, arquivo.tamanho);
    final enviado = await _arquivos.enviar(
      bytes: await arquivo.ler(),
      nome: arquivo.nome,
      categoria: categoria,
    );
    return _repo.salvarMidia(
      a.id,
      midiaId: gerarId(),
      referencia: enviado.referencia,
      tipo: tipo,
      titulo: titulo.trim(),
      itemId: itemId,
    );
  }
}

/// Confere o que o servidor também exige antes de concluir (avisa logo).
void validarConclusao(Auditoria a) {
  if (a.itens.isEmpty) {
    throw const DomainException('Inclua ao menos um item no checklist.');
  }
  final pendentes = a.contar(EstadoItem.pendente);
  if (pendentes > 0) {
    throw DomainException(
      'Avalie todos os itens do checklist ($pendentes sem avaliação).',
    );
  }
  if (a.nota == null) {
    throw const DomainException('Dê a nota de conservação (1 a 5).');
  }
}

/// Texto pronto para mandar ao proprietário (WhatsApp/e-mail) com o acesso.
String mensagemDeAcessoProprietario({
  required String nome,
  required String enderecoSite,
  required SenhaProvisoria senha,
}) =>
    'Olá, ${nome.split(' ').first}! Seu acesso à Área do proprietário está '
    'liberado.\n\nEndereço: $enderecoSite/proprietario\nLogin (CPF/CNPJ): '
    '${senha.login}\nSenha provisória: ${senha.senha}\n\nNo primeiro acesso '
    'você vai criar a sua senha. Lá você acompanha seus imóveis, repasses, '
    'manutenções e os relatórios das auditorias (com fotos, vídeos e a '
    'transcrição do que foi dito na visita).';
