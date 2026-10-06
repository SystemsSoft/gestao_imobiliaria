import '../../../../core/config/empresa_info.dart';
import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../domain/entities/venda.dart';
import '../../domain/entities/venda_enums.dart';
import '../../domain/usecases/imprimir_documentos_venda.dart';
import '../../domain/usecases/venda_usecases.dart';

class LinhaComissao {
  const LinhaComissao({
    required this.venda,
    required this.indice,
    required this.beneficiario,
    required this.valor,
  });

  final Venda venda;
  final int indice;
  final String beneficiario;
  final double valor;

  Participacao get participacao => venda.corretores[indice];
  bool get paga => participacao.pagaEm != null;
}

enum FiltroComissao {
  pendentes('Pendentes'),
  pagas('Pagas'),
  todas('Todas');

  const FiltroComissao(this.label);
  final String label;
}

/// Comissões de corretagem de todas as vendas.
class ComissoesViewModel extends ViewModel {
  ComissoesViewModel(
    ObservarVendas observarVendas,
    ObservarContatos observarContatos,
    this._marcar,
    this._recibo,
  ) {
    observar(observarVendas(), (l) {
      _vendas = l;
      carregado = true;
    });
    observar(observarContatos(), (l) => _contatos = l);
  }

  final MarcarComissaoPaga _marcar;
  final ImprimirReciboComissao _recibo;

  List<Venda> _vendas = const [];
  List<Contato> _contatos = const [];
  bool carregado = false;
  FiltroComissao filtro = FiltroComissao.pendentes;

  void filtrar(FiltroComissao f) {
    filtro = f;
    notificar();
  }

  List<LinhaComissao> get _todas => [
    for (final v in _vendas)
      if (v.comissaoPercentual > 0 && v.status != StatusVenda.distratada)
        for (var i = 0; i < v.corretores.length; i++)
          LinhaComissao(
            venda: v,
            indice: i,
            beneficiario: v.corretores[i].contatoId == null
                ? '${EmpresaInfo.nome} (imobiliária)'
                : _contatos
                          .where((c) => c.id == v.corretores[i].contatoId)
                          .firstOrNull
                          ?.nome ??
                      '—',
            valor: arredondar(
              v.valorComissao * v.corretores[i].percentual / 100,
            ),
          ),
  ];

  List<LinhaComissao> get linhas =>
      _todas
          .where(
            (l) => switch (filtro) {
              FiltroComissao.pendentes => !l.paga,
              FiltroComissao.pagas => l.paga,
              FiltroComissao.todas => true,
            },
          )
          .toList()
        ..sort((a, b) => b.venda.dataVenda.compareTo(a.venda.dataVenda));

  double get totalPendente =>
      _todas.where((l) => !l.paga).fold(0, (s, l) => s + l.valor);
  double get totalPago =>
      _todas.where((l) => l.paga).fold(0, (s, l) => s + l.valor);

  Future<bool> marcar(LinhaComissao l, bool paga) =>
      executar(() => _marcar(l.venda, l.indice, paga ? DateTime.now() : null));

  Future<bool> recibo(LinhaComissao l) =>
      executar(() => _recibo(l.venda, l.indice));
}
