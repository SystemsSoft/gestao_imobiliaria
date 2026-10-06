import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/contato.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/imovel.dart';
import '../../domain/entities/match_result.dart';
import '../../domain/usecases/contato_usecases.dart';
import '../../domain/usecases/imovel_usecases.dart';
import '../../domain/usecases/sugerir_negocios.dart';

class CruzamentoViewModel extends ViewModel {
  CruzamentoViewModel(
    ObservarContatos observarContatos,
    ObservarImoveis observarImoveis,
    this._sugerir,
  ) {
    observar(observarContatos(), (l) => _contatos = l);
    observar(observarImoveis(), (l) => _imoveis = l);
  }

  final SugerirNegocios _sugerir;
  List<Contato> _contatos = const [];
  List<Imovel> _imoveis = const [];

  bool porContato = true;

  void alternarVisao(bool contato) {
    porContato = contato;
    notificar();
  }

  List<({Contato contato, List<MatchResult> matches})> get porContatos => [
    for (final c in _contatos.where((c) => c.perfil != null))
      (contato: c, matches: _sugerir.paraContato(c, _imoveis)),
  ];

  List<({Imovel imovel, List<MatchResult> matches})> get porImoveis => [
    for (final i in _imoveis.where((i) => i.status == StatusImovel.disponivel))
      (imovel: i, matches: _sugerir.paraImovel(i, _contatos)),
  ];
}
