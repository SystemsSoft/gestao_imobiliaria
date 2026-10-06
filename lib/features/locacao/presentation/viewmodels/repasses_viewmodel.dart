import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/enums.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../../crm/domain/usecases/imovel_usecases.dart';
import '../../domain/entities/cobranca.dart';
import '../../domain/entities/contrato_locacao.dart';
import '../../domain/entities/despesa.dart';
import '../../domain/entities/documentos.dart';
import '../../domain/entities/linha_repasse.dart';
import '../../domain/entities/locacao_enums.dart';
import '../../domain/repositories/repasse_repository.dart';
import '../../domain/usecases/cobranca_usecases.dart';
import '../../domain/usecases/contrato_usecases.dart';
import '../../domain/usecases/despesa_usecases.dart';
import '../../domain/usecases/imprimir_documentos.dart';
import '../../domain/usecases/repasse_usecases.dart';

class GrupoRepasse {
  const GrupoRepasse(this.beneficiario, this.linhas);

  final Contato beneficiario;
  final List<LinhaRepasse> linhas;

  double get totalLiquido => linhas.fold(0, (s, l) => s + l.liquido);
}

class RepassesViewModel extends ViewModel {
  RepassesViewModel(
    ObservarCobrancas observarCobrancas,
    ObservarContratos observarContratos,
    ObservarDespesas observarDespesas,
    ObservarContatos observarContatos,
    ObservarImoveis observarImoveis,
    ObservarRepassesRealizados observarRealizados,
    this._marcar,
    this._calcular,
    this._imprimir,
  ) {
    competencia = competenciaDe(DateTime.now());
    observar(observarCobrancas(), (l) {
      _cobrancas = l;
      carregado = true;
    });
    observar(observarContratos(), (l) => _contratos = l);
    observar(observarDespesas(), (l) => _despesas = l);
    observar(observarContatos(), (l) => _contatos = l);
    observar(observarImoveis(), (l) => _imoveis = l);
    observar(observarRealizados(), (m) => _realizados = m);
  }

  final MarcarRepasse _marcar;
  final CalcularRepasse _calcular;
  final ImprimirDemonstrativoRepasse _imprimir;

  List<Cobranca> _cobrancas = const [];
  List<ContratoLocacao> _contratos = const [];
  List<Despesa> _despesas = const [];
  List<Contato> _contatos = const [];
  List<Imovel> _imoveis = const [];
  Map<String, DateTime> _realizados = const {};
  bool carregado = false;
  late DateTime competencia;

  void mudarCompetencia(DateTime c) {
    competencia = competenciaDe(c);
    notificar();
  }

  bool _pj(String id) =>
      contatoPorId(_contatos, id)?.tipoPessoa == TipoPessoa.juridica;

  String imovelDoContrato(ContratoLocacao c) {
    final i = _imoveis.where((i) => i.id == c.imovelId).firstOrNull;
    return i == null ? '' : '${i.codigo} • ${i.titulo}';
  }

  /// Linhas de repasse das cobranças pagas na competência, por beneficiário.
  List<GrupoRepasse> get grupos {
    final porBeneficiario = <String, List<LinhaRepasse>>{};
    for (final c in _cobrancas) {
      if (c.competencia != competencia || c.status != StatusCobranca.paga) {
        continue;
      }
      final k = _contratos.where((k) => k.id == c.contratoId).firstOrNull;
      if (k == null) continue;
      for (final l in _calcular(
        cobranca: c,
        contrato: k,
        despesas: _despesas,
        locatarioPessoaJuridica: _pj(k.locatarioId),
        beneficiarioPessoaJuridica: _pj,
      )) {
        porBeneficiario.putIfAbsent(l.beneficiario.contatoId, () => []).add(l);
      }
    }
    return [
      for (final e in porBeneficiario.entries)
        if (contatoPorId(_contatos, e.key) case final b?)
          GrupoRepasse(b, e.value),
    ]..sort((a, b) => a.beneficiario.nome.compareTo(b.beneficiario.nome));
  }

  DateTime? realizadoEm(LinhaRepasse l) =>
      _realizados[chaveRepasse(l.cobranca.id, l.beneficiario.contatoId)];

  double get totalAPagar => grupos
      .expand((g) => g.linhas)
      .where((l) => realizadoEm(l) == null)
      .fold(0, (s, l) => s + l.liquido);

  Future<bool> marcar(LinhaRepasse l, bool realizado) => executar(
    () => _marcar(
      l.cobranca.id,
      l.beneficiario.contatoId,
      realizado ? DateTime.now() : null,
    ),
  );

  Future<bool> marcarTodos(GrupoRepasse g) => executar(() async {
    for (final l in g.linhas) {
      if (realizadoEm(l) == null) {
        await _marcar(l.cobranca.id, l.beneficiario.contatoId, DateTime.now());
      }
    }
  });

  Future<bool> imprimir(GrupoRepasse g) => executar(
    () => _imprimir(
      DemonstrativoRepasse(
        beneficiario: g.beneficiario,
        competencia: competencia,
        linhas: g.linhas,
        imovelPorContrato: {
          for (final l in g.linhas) l.contrato.id: imovelDoContrato(l.contrato),
        },
      ),
    ),
  );
}
