import '../../../../core/errors/domain_exception.dart';
import '../entities/comissao_equipe.dart';
import '../entities/equipe_enums.dart';
import '../repositories/equipe_repositories.dart';
import '../services/resumo_comissoes_service.dart';
import 'usuario_usecases.dart';

class ObservarRegrasComissao {
  const ObservarRegrasComissao(this._repo);
  final ComissaoEquipeRepository _repo;

  Stream<List<RegraComissao>> call() => _repo.observarRegras();
}

class ObservarLancamentosComissao {
  const ObservarLancamentosComissao(this._repo);
  final ComissaoEquipeRepository _repo;

  Stream<List<LancamentoComissao>> call() => _repo.observarLancamentos();
}

class SalvarRegraComissao {
  const SalvarRegraComissao(this._repo, this._registrar);
  final ComissaoEquipeRepository _repo;
  final RegistrarAtividade _registrar;

  Future<void> call(RegraComissao r) async {
    for (final p in [
      r.percentualVenda,
      r.percentualLocacao,
      r.percentualCaptacao,
    ]) {
      if (p < 0 || p > 100) {
        throw const DomainException(
          'Os percentuais devem ficar entre 0 e 100.',
        );
      }
    }
    if (r.metaMensal < 0) throw const DomainException('Meta inválida.');
    await _repo.salvarRegra(r);
    await _registrar(
      TipoAtividade.comissao,
      'Alterou as regras de comissão',
      modulo: ModuloSistema.equipeSeguranca,
    );
  }
}

/// Valida e salva o lançamento. Para venda, locação e captação o valor é
/// base × percentual; bônus e ajuste têm valor livre.
class SalvarLancamentoComissao {
  const SalvarLancamentoComissao(this._repo, this._registrar);
  final ComissaoEquipeRepository _repo;
  final RegistrarAtividade _registrar;

  Future<LancamentoComissao> call(LancamentoComissao l) async {
    if (l.usuarioId.isEmpty) {
      throw const DomainException('Selecione o corretor.');
    }
    var valor = l.valor;
    if (l.tipo.porPercentual) {
      if (l.baseValor <= 0) {
        throw const DomainException('Informe a comissão de base.');
      }
      if (l.percentual <= 0 || l.percentual > 100) {
        throw const DomainException('O percentual deve ficar entre 0 e 100.');
      }
      valor = arredondar(l.baseValor * l.percentual / 100);
    } else if (valor == 0) {
      throw const DomainException('Informe o valor.');
    } else if (l.tipo == TipoComissao.bonus && valor < 0) {
      throw const DomainException(
        'O bônus deve ser positivo; use "Ajuste" para descontos.',
      );
    }
    final salvo = LancamentoComissao(
      id: l.id,
      usuarioId: l.usuarioId,
      tipo: l.tipo,
      competencia: DateTime(l.competencia.year, l.competencia.month),
      valor: valor,
      referencia: l.referencia,
      baseValor: l.baseValor,
      percentual: l.percentual,
      observacao: l.observacao,
      status: l.status,
      dataPagamento: l.dataPagamento,
    );
    await _repo.salvarLancamento(salvo);
    await _registrar(
      TipoAtividade.comissao,
      'Lançou comissão de ${salvo.tipo.label.toLowerCase()}'
      '${salvo.referencia.isEmpty ? '' : ' (${salvo.referencia})'}',
      modulo: ModuloSistema.equipeSeguranca,
    );
    return salvo;
  }
}

/// Fluxo da comissão: a aprovar → a pagar → paga. Também pode ser cancelada.
class AlterarStatusComissao {
  const AlterarStatusComissao(this._repo, this._registrar);
  final ComissaoEquipeRepository _repo;
  final RegistrarAtividade _registrar;

  Future<void> call(
    LancamentoComissao l,
    StatusComissao novo, {
    DateTime? dataPagamento,
  }) async {
    if (l.status == StatusComissao.paga && novo != StatusComissao.aprovada) {
      throw const DomainException(
        'Estorne o pagamento (volte para "A pagar") antes de alterar.',
      );
    }
    await _repo.salvarLancamento(
      l.copyWith(
        status: novo,
        dataPagamento: novo == StatusComissao.paga
            ? (dataPagamento ?? DateTime.now())
            : null,
        limparPagamento: novo != StatusComissao.paga,
      ),
    );
    await _registrar(
      TipoAtividade.comissao,
      'Comissão ${l.referencia.isEmpty ? l.tipo.label.toLowerCase() : l.referencia}: ${novo.label.toLowerCase()}',
      modulo: ModuloSistema.equipeSeguranca,
    );
  }
}

class RemoverLancamentoComissao {
  const RemoverLancamentoComissao(this._repo);
  final ComissaoEquipeRepository _repo;

  Future<void> call(LancamentoComissao l) {
    if (l.status == StatusComissao.paga) {
      throw const DomainException('Comissão paga não pode ser excluída.');
    }
    return _repo.removerLancamento(l.id);
  }
}

class ResumirComissoes {
  const ResumirComissoes([this._service = const ResumoComissoesService()]);
  final ResumoComissoesService _service;

  List<ResumoCorretor> call({
    required List<LancamentoComissao> lancamentos,
    required List<RegraComissao> regras,
    required DateTime competencia,
    required Iterable<String> usuarios,
  }) => _service.calcular(
    lancamentos: lancamentos,
    regras: regras,
    competencia: competencia,
    usuarios: usuarios,
  );
}
