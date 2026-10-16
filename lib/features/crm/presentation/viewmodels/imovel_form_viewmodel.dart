import '../../../../core/arquivos/arquivo_repository.dart';
import '../../../../core/errors/domain_exception.dart';
import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/contato.dart';
import '../../domain/entities/imovel.dart';
import '../../domain/usecases/contato_usecases.dart';
import '../../domain/usecases/imovel_usecases.dart';

class ImovelFormViewModel extends ViewModel {
  ImovelFormViewModel(this._listarContatos, this._salvar, this._enviarAnexo) {
    _carregar();
  }

  final ListarContatos _listarContatos;
  final SalvarImovel _salvar;
  final EnviarAnexo _enviarAnexo;

  /// Arquivos sendo enviados do computador.
  bool enviando = false;

  /// Contatos disponíveis para vincular como proprietário.
  List<Contato> contatos = const [];

  Future<void> _carregar() async {
    contatos = await _listarContatos();
    notificar();
  }

  Future<bool> salvar(Imovel imovel) => executar(() => _salvar(imovel));

  /// Envia os arquivos escolhidos e devolve os anexos criados; os que
  /// falharem ficam descritos em [erro] (os demais seguem).
  Future<List<Anexo>> enviarAnexos(
    AnexoTipo tipo,
    List<ArquivoEscolhido> arquivos, {
    String titulo = '',
  }) async {
    enviando = true;
    erro = null;
    notificar();
    final anexos = <Anexo>[];
    final falhas = <String>[];
    for (final a in arquivos) {
      try {
        anexos.add(
          await _enviarAnexo(
            tipo,
            a,
            titulo: arquivos.length == 1 ? titulo : '',
          ),
        );
      } on DomainException catch (e) {
        falhas.add(e.mensagem);
      }
    }
    enviando = false;
    erro = falhas.isEmpty ? null : falhas.join('\n');
    notificar();
    return anexos;
  }
}
