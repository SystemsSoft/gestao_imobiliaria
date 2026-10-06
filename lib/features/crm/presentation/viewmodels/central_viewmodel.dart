import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/contato.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/evento.dart';
import '../../domain/entities/imovel.dart';
import '../../domain/usecases/contato_usecases.dart';
import '../../domain/usecases/evento_usecases.dart';
import '../../domain/usecases/imovel_usecases.dart';
import '../../domain/usecases/sugerir_negocios.dart';

class SecaoAgenda {
  const SecaoAgenda(this.titulo, this.itens, this.tipo);

  final String titulo;
  final List<Evento> itens;
  final TipoSecao tipo;
}

enum TipoSecao { atrasados, hoje, proximos, semData, concluidos }

/// Central de Relacionamento: agenda unificada com notificações.
class CentralViewModel extends ViewModel {
  CentralViewModel(
    ObservarEventos observarEventos,
    ObservarContatos observarContatos,
    ObservarImoveis observarImoveis,
    this._sugerir,
    this._alternar,
    this._remover, {
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now {
    observar(observarEventos(), (l) {
      _eventos = l;
      carregado = true;
    });
    observar(observarContatos(), (l) => _contatos = l);
    observar(observarImoveis(), (l) => _imoveis = l);
  }

  final SugerirNegocios _sugerir;
  final AlternarConclusaoEvento _alternar;
  final RemoverEvento _remover;
  final DateTime Function() _agora;

  List<Evento> _eventos = const [];
  List<Contato> _contatos = const [];
  List<Imovel> _imoveis = const [];
  bool carregado = false;
  TipoEvento? filtroTipo;

  bool get vazio => _filtrados.isEmpty;

  List<Evento> get _filtrados => _eventos
      .where((e) => filtroTipo == null || e.tipo == filtroTipo)
      .toList();

  void filtrar(TipoEvento? tipo) {
    filtroTipo = tipo;
    notificar();
  }

  List<SecaoAgenda> get secoes {
    final agora = _agora();
    final inicioHoje = DateTime(agora.year, agora.month, agora.day);
    final fimHoje = inicioHoje.add(const Duration(days: 1));
    int porData(Evento a, Evento b) =>
        (a.dataHora ?? a.criadoEm).compareTo(b.dataHora ?? b.criadoEm);

    final abertos = _filtrados.where((e) => !e.concluido).toList();
    List<Evento> sel(bool Function(Evento) f) =>
        abertos.where(f).toList()..sort(porData);

    return [
      SecaoAgenda(
        'Atrasados',
        sel((e) => e.dataHora != null && e.dataHora!.isBefore(inicioHoje)),
        TipoSecao.atrasados,
      ),
      SecaoAgenda(
        'Hoje',
        sel(
          (e) =>
              e.dataHora != null &&
              !e.dataHora!.isBefore(inicioHoje) &&
              e.dataHora!.isBefore(fimHoje),
        ),
        TipoSecao.hoje,
      ),
      SecaoAgenda(
        'Próximos',
        sel((e) => e.dataHora != null && !e.dataHora!.isBefore(fimHoje)),
        TipoSecao.proximos,
      ),
      SecaoAgenda(
        'Anotações e itens sem data',
        sel((e) => e.dataHora == null),
        TipoSecao.semData,
      ),
      SecaoAgenda(
        'Concluídos',
        _filtrados.where((e) => e.concluido).toList()
          ..sort((a, b) => porData(b, a)),
        TipoSecao.concluidos,
      ),
    ].where((s) => s.itens.isNotEmpty).toList();
  }

  int _contar(TipoSecao t) =>
      secoes.where((s) => s.tipo == t).fold(0, (n, s) => n + s.itens.length);

  int get atrasados => _contar(TipoSecao.atrasados);
  int get paraHoje => _contar(TipoSecao.hoje);
  int get sugestoes => _sugerir.total(_contatos, _imoveis);

  String? nomeContato(String? id) =>
      _contatos.where((c) => c.id == id).firstOrNull?.nome;

  String? codigoImovel(String? id) =>
      _imoveis.where((i) => i.id == id).firstOrNull?.codigo;

  Future<void> alternarConcluido(Evento e) => executar(() => _alternar(e));

  Future<void> remover(String id) => executar(() => _remover(id));
}
