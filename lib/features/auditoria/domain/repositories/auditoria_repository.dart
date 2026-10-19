import '../../../portal_inquilino/domain/entities/portal.dart';
import '../entities/auditoria.dart';

abstract interface class AuditoriaRepository {
  Future<List<Auditoria>> listar({String? imovelId, String? proprietarioId});
  Future<Auditoria> obter(String id);

  /// Cria ou atualiza (itens do checklist incluídos). Devolve como ficou.
  Future<Auditoria> salvar(Auditoria a);
  Future<void> remover(String id);

  Future<Auditoria> concluir(String id, {required bool publicar});
  Future<Auditoria> reabrir(String id);
  Future<Auditoria> publicar(String id, bool publicada);

  /// Itens com "Problema" viram pautas de manutenção.
  Future<({int criadas, Auditoria auditoria})> gerarManutencoes(String id);

  /// Link temporário do relatório imprimível.
  Future<Uri> linkRelatorio(String id);

  Future<Auditoria> salvarMidia(
    String auditoriaId, {
    required String midiaId,
    required String referencia,
    required TipoMidia tipo,
    String titulo = '',
    String? itemId,
  });
  Future<Auditoria> removerMidia(String auditoriaId, String midiaId);

  /// Põe o vídeo na fila de transcrição do servidor.
  Future<Auditoria> transcrever(String auditoriaId, String midiaId);

  Future<List<Pendencia>> pendencias({String? proprietarioId});
  Future<List<ResumoProprietario>> proprietarios();

  /// Libera a Área do proprietário ou gera nova senha provisória.
  Future<SenhaProvisoria> liberarAcesso(String contatoId);
  Future<void> revogarAcesso(String contatoId);

  Future<ConfiguracaoAuditoria> configuracao();
  Future<void> salvarConfiguracao(ConfiguracaoAuditoria c);

  Future<List<ModeloChecklist>> modelos();
  Future<void> salvarModelo(ModeloChecklist m);
  Future<void> removerModelo(String id);
}
