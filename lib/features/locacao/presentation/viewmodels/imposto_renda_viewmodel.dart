import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/enums.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../domain/entities/cobranca.dart';
import '../../domain/entities/contrato_locacao.dart';
import '../../domain/entities/despesa.dart';
import '../../domain/entities/documentos.dart';
import '../../domain/entities/ir_mensal.dart';
import '../../domain/usecases/cobranca_usecases.dart';
import '../../domain/usecases/contrato_usecases.dart';
import '../../domain/usecases/despesa_usecases.dart';
import '../../domain/usecases/imposto_renda.dart';
import '../../domain/usecases/imprimir_documentos.dart';

class ImpostoRendaViewModel extends ViewModel {
  ImpostoRendaViewModel(
    ObservarCobrancas observarCobrancas,
    ObservarContratos observarContratos,
    ObservarDespesas observarDespesas,
    ObservarContatos observarContatos,
    this._calcular,
    this._imprimir,
  ) {
    observar(observarCobrancas(), (l) => _cobrancas = l);
    observar(observarContratos(), (l) => _contratos = l);
    observar(observarDespesas(), (l) => _despesas = l);
    observar(observarContatos(), (l) {
      _contatos = l;
      carregado = true;
    });
  }

  final CalcularResumoIrAnual _calcular;
  final ImprimirInformeRendimentos _imprimir;

  List<Cobranca> _cobrancas = const [];
  List<ContratoLocacao> _contratos = const [];
  List<Despesa> _despesas = const [];
  List<Contato> _contatos = const [];
  bool carregado = false;
  int ano = DateTime.now().year;
  String? beneficiarioId;

  bool _pj(String id) =>
      contatoPorId(_contatos, id)?.tipoPessoa == TipoPessoa.juridica;

  /// Contatos que são beneficiários de algum contrato.
  List<Contato> get beneficiarios {
    final ids = {
      for (final c in _contratos)
        for (final b in c.beneficiarios) b.contatoId,
    };
    return _contatos.where((c) => ids.contains(c.id)).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
  }

  Contato? get beneficiario {
    final lista = beneficiarios;
    return lista.where((c) => c.id == beneficiarioId).firstOrNull ??
        lista.firstOrNull;
  }

  bool get beneficiarioPJ => beneficiario?.tipoPessoa == TipoPessoa.juridica;

  void mudarAno(int a) {
    ano = a;
    notificar();
  }

  void selecionar(String? id) {
    beneficiarioId = id;
    notificar();
  }

  List<IrMensal> get meses {
    final b = beneficiario;
    if (b == null) return const [];
    return _calcular(
      beneficiarioId: b.id,
      ano: ano,
      cobrancas: _cobrancas,
      contratos: _contratos,
      despesas: _despesas,
      pessoaJuridica: _pj,
    );
  }

  double total(double Function(IrMensal) campo) =>
      meses.fold(0, (s, m) => s + campo(m));

  Future<bool> imprimir() {
    final b = beneficiario;
    if (b == null) return Future.value(false);
    return executar(
      () => _imprimir(
        InformeRendimentos(beneficiario: b, ano: ano, meses: meses),
      ),
    );
  }
}
