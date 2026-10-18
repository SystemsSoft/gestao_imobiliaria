import '../../../../core/arquivos/arquivo_repository.dart';
import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../../crm/domain/usecases/imovel_usecases.dart';
import '../../../locacao/domain/entities/contrato_locacao.dart';
import '../../../locacao/domain/entities/locacao_enums.dart';
import '../../../locacao/domain/usecases/contrato_usecases.dart';
import '../../../manutencao/domain/entities/manutencao.dart';
import '../../../manutencao/domain/usecases/manutencao_usecases.dart';
import '../../domain/entities/portal.dart';
import '../../domain/repositories/portal_repository.dart';
import '../../domain/usecases/portal_usecases.dart';

/// Linha da lista: contrato, locatário, imóvel e situação do acesso.
typedef ContratoNoPortal = ({
  ContratoLocacao contrato,
  Contato? locatario,
  Imovel? imovel,
  AcessoInquilino? acesso,
});

/// Lista de contratos com o acesso de cada inquilino ao portal.
class PortalInquilinoViewModel extends ViewModel {
  PortalInquilinoViewModel(
    ObservarContratos observarContratos,
    ObservarContatos observarContatos,
    ObservarImoveis observarImoveis,
    this._portal,
    this._enviarComunicado,
  ) {
    observar(observarContratos(), (l) {
      _contratos = l;
      carregado = true;
    });
    observar(
      observarContatos(),
      (l) => _contatos = {for (final c in l) c.id: c},
    );
    observar(observarImoveis(), (l) => _imoveis = {for (final i in l) i.id: i});
    recarregarAcessos();
  }

  final PortalInquilinoRepository _portal;
  final EnviarComunicado _enviarComunicado;
  List<ContratoLocacao> _contratos = const [];
  Map<String, Contato> _contatos = const {};
  Map<String, Imovel> _imoveis = const {};
  Map<String, AcessoInquilino> _acessos = const {};
  bool carregado = false;
  bool somenteAtivos = true;
  String _busca = '';

  Future<void> recarregarAcessos() => executar(() async {
    _acessos = {for (final a in await _portal.acessos()) a.contatoId: a};
  });

  int get comAcesso =>
      linhas.where((l) => l.acesso != null && l.acesso!.ativo).length;

  List<ContratoNoPortal> get linhas {
    final q = _busca.toLowerCase();
    final lista = [
      for (final c in _contratos)
        if (!somenteAtivos || c.status == StatusContrato.ativo)
          (
            contrato: c,
            locatario: _contatos[c.locatarioId],
            imovel: _imoveis[c.imovelId],
            acesso: _acessos[c.locatarioId],
          ),
    ];
    return lista.where((l) {
      if (q.isEmpty) return true;
      return [
        l.contrato.numero,
        l.locatario?.nome ?? '',
        l.imovel?.titulo ?? '',
        l.imovel?.codigo ?? '',
      ].any((t) => t.toLowerCase().contains(q));
    }).toList()..sort((a, b) => b.contrato.numero.compareTo(a.contrato.numero));
  }

  void buscar(String q) {
    _busca = q.trim();
    notificar();
  }

  void mostrarEncerrados(bool sim) {
    somenteAtivos = !sim;
    notificar();
  }

  Future<bool> comunicadoGeral(String titulo, String mensagem) =>
      executar(() => _enviarComunicado(titulo: titulo, mensagem: mensagem));
}

/// Tudo do portal de um contrato: acesso, documentos, envios do
/// inquilino, chamados e avisos.
class PortalContratoViewModel extends ViewModel {
  PortalContratoViewModel(
    this.contrato,
    this._portal,
    this._publicar,
    this._enviarComunicado,
    ObservarManutencoes observarManutencoes,
  ) {
    observar(
      observarManutencoes(ContextoManutencao.locacao),
      (l) =>
          chamados = l.where((m) => m.contratoId == contrato.id).toList()
            ..sort((a, b) => b.criadaEm.compareTo(a.criadaEm)),
    );
    recarregar();
  }

  final ContratoLocacao contrato;
  final PortalInquilinoRepository _portal;
  final PublicarDocumentoContrato _publicar;
  final EnviarComunicado _enviarComunicado;

  AcessoInquilino? acesso;
  List<ArquivoContrato> arquivos = const [];
  List<ComunicadoInquilino> comunicados = const [];
  List<Manutencao> chamados = const [];
  bool carregado = false;

  /// Senha provisória recém-gerada (mostrada uma vez).
  SenhaProvisoria? senhaGerada;

  List<ArquivoContrato> get documentos =>
      arquivos.where((a) => !a.doInquilino).toList();

  /// Fotos e vídeos do estado do imóvel e anexos dos chamados.
  List<ArquivoContrato> get enviadosPeloInquilino =>
      arquivos.where((a) => a.doInquilino).toList();

  Future<void> recarregar() async {
    await executar(() async {
      final todos = await _portal.acessos();
      acesso = todos
          .where((a) => a.contatoId == contrato.locatarioId)
          .firstOrNull;
      arquivos = await _portal.arquivos(contratoId: contrato.id);
      comunicados = await _portal.comunicados(contratoId: contrato.id);
    });
    carregado = true;
    notificar();
  }

  Future<bool> liberarAcesso() => executar(() async {
    senhaGerada = await _portal.liberarAcesso(contrato.locatarioId);
    acesso = (await _portal.acessos())
        .where((a) => a.contatoId == contrato.locatarioId)
        .firstOrNull;
  });

  Future<bool> revogarAcesso() => executar(() async {
    await _portal.revogarAcesso(contrato.locatarioId);
    acesso = null;
  });

  Future<bool> publicar({
    required TipoArquivoContrato tipo,
    required String titulo,
    required ArquivoEscolhido arquivo,
  }) => executar(() async {
    await _publicar(
      contratoId: contrato.id,
      tipo: tipo,
      titulo: titulo,
      arquivo: arquivo,
    );
    await _recarregarListas();
  });

  Future<bool> alternarVisibilidade(ArquivoContrato a) => executar(() async {
    await _portal.salvarArquivo(a.comVisibilidade(!a.visivelInquilino));
    await _recarregarListas();
  });

  Future<bool> removerArquivo(ArquivoContrato a) => executar(() async {
    await _portal.removerArquivo(a.id);
    await _recarregarListas();
  });

  Future<bool> enviarComunicado(String titulo, String mensagem) =>
      executar(() async {
        await _enviarComunicado(
          contratoId: contrato.id,
          titulo: titulo,
          mensagem: mensagem,
        );
        await _recarregarListas();
      });

  Future<bool> removerComunicado(ComunicadoInquilino c) => executar(() async {
    await _portal.removerComunicado(c.id);
    await _recarregarListas();
  });

  Future<void> _recarregarListas() async {
    arquivos = await _portal.arquivos(contratoId: contrato.id);
    comunicados = await _portal.comunicados(contratoId: contrato.id);
  }
}
