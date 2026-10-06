import '../../../../core/presentation/view_model.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../domain/entities/equipe_enums.dart';
import '../../domain/entities/fila.dart';
import '../../domain/entities/usuario_sistema.dart';
import '../../domain/services/fila_service.dart';
import '../../domain/usecases/fila_usecases.dart';
import '../../domain/usecases/usuario_usecases.dart';

/// Fila de corretores para distribuir o atendimento por ordem.
class FilaViewModel extends ViewModel {
  FilaViewModel(
    ObservarFila observarFila,
    ObservarAtendimentos observarAtendimentos,
    ObservarUsuarios observarUsuarios,
    ObservarUsuarioAtual observarAtual,
    ObservarContatos observarContatos,
    this._gerenciar,
    this._chamar,
    this._finalizar,
    this._service, {
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now {
    observar(observarFila(), (l) {
      fila = l;
      carregado = true;
    });
    observar(observarAtendimentos(), (l) => _atendimentos = l);
    observar(observarUsuarios(), (l) => _usuarios = l);
    observar(observarAtual(), (id) => usuarioAtualId = id);
    observar(observarContatos(), (l) => contatos = l);
  }

  final GerenciarFila _gerenciar;
  final ChamarProximo _chamar;
  final FinalizarAtendimento _finalizar;
  final FilaService _service;
  final DateTime Function() _agora;

  List<ItemFila> fila = const [];
  List<Atendimento> _atendimentos = const [];
  List<UsuarioSistema> _usuarios = const [];
  List<Contato> contatos = const [];
  String? usuarioAtualId;
  bool carregado = false;

  DateTime get hoje => _agora();

  UsuarioSistema? usuario(String id) =>
      _usuarios.where((u) => u.id == id).firstOrNull;
  String nome(String id) => usuario(id)?.nome ?? 'Usuário removido';

  ItemFila? get proximo => _service.proximo(fila);

  /// Corretores que podem entrar na fila e ainda não estão nela.
  List<UsuarioSistema> get elegiveis =>
      _usuarios
          .where(
            (u) =>
                u.ativo &&
                u.atendeNaFila &&
                !fila.any((i) => i.usuarioId == u.id),
          )
          .toList()
        ..sort((a, b) => a.nome.compareTo(b.nome));

  List<Atendimento> get emAndamento =>
      _atendimentos.where((a) => a.emAndamento).toList()
        ..sort((a, b) => a.iniciadoEm.compareTo(b.iniciadoEm));

  List<Atendimento> get historico =>
      _atendimentos.where((a) => !a.emAndamento).toList()
        ..sort((a, b) => b.finalizadoEm!.compareTo(a.finalizadoEm!));

  /// Atendimentos do dia por corretor.
  int atendimentosHoje(String usuarioId) => _atendimentos
      .where(
        (a) =>
            a.corretorId == usuarioId &&
            a.iniciadoEm.year == hoje.year &&
            a.iniciadoEm.month == hoje.month &&
            a.iniciadoEm.day == hoje.day,
      )
      .length;

  int get atendimentosHojeTotal =>
      fila.fold(0, (s, i) => s + atendimentosHoje(i.usuarioId));

  String? nomeContato(String? id) =>
      contatos.where((c) => c.id == id).firstOrNull?.nome;

  Future<bool> entrar(String id) => executar(() => _gerenciar.entrar(id));
  Future<bool> sair(String id) => executar(() => _gerenciar.sair(id));
  Future<bool> mudarStatus(String id, StatusFila s) =>
      executar(() => _gerenciar.mudarStatus(id, s));
  Future<bool> pular(String id) => executar(() => _gerenciar.pular(id));
  Future<bool> mover(String id, int delta) =>
      executar(() => _gerenciar.mover(id, delta));

  Future<bool> chamar({
    required String cliente,
    required OrigemAtendimento origem,
    String? contatoId,
    String observacao = '',
  }) => executar(() async {
    await _chamar(
      clienteNome: cliente,
      origem: origem,
      contatoId: contatoId,
      observacao: observacao,
    );
  });

  Future<bool> finalizar(Atendimento a, String observacao) =>
      executar(() => _finalizar(a, observacao));
}
