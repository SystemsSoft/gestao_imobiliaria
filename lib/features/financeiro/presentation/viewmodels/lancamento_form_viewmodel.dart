import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../domain/entities/indice_mensal.dart';
import '../../domain/entities/lancamento.dart';
import '../../domain/usecases/financeiro_usecases.dart';
import '../../domain/usecases/lancamento_usecases.dart';

class LancamentoFormViewModel extends ViewModel {
  LancamentoFormViewModel(
    this._listarContatos,
    this._obterConfig,
    this._salvar,
  ) {
    _carregar();
  }

  final ListarContatos _listarContatos;
  final ObterConfiguracaoFinanceira _obterConfig;
  final SalvarLancamento _salvar;

  List<Contato> contatos = const [];
  ConfiguracaoFinanceira config = const ConfiguracaoFinanceira();
  bool carregado = false;

  Future<void> _carregar() async {
    contatos = await _listarContatos();
    config = await _obterConfig();
    carregado = true;
    notificar();
  }

  String nome(String? id) =>
      contatos.where((c) => c.id == id).firstOrNull?.nome ?? '';

  Future<bool> salvar(Lancamento l, {int repetir = 1}) =>
      executar(() => _salvar(l, repetir: repetir));
}
