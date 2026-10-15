import '../../../../core/errors/domain_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../entities/reserva.dart';
import '../entities/reserva_enums.dart';
import '../repositories/reserva_repository.dart';
import '../services/calendario_temporada.dart';

class ObservarReservas {
  const ObservarReservas(this._repo);
  final ReservaRepository _repo;

  Stream<List<Reserva>> call() => _repo.observar();
}

/// Informa se o período está livre, listando as reservas em conflito.
class ConsultarDisponibilidade {
  const ConsultarDisponibilidade(
    this._repo, [
    this._calendario = const CalendarioTemporada(),
  ]);
  final ReservaRepository _repo;
  final CalendarioTemporada _calendario;

  Future<List<Reserva>> call({
    required String imovelId,
    required DateTime checkIn,
    required DateTime checkOut,
    String? ignorarId,
  }) async => _calendario.conflitos(
    await _repo.listar(),
    imovelId: imovelId,
    checkIn: checkIn,
    checkOut: checkOut,
    ignorarId: ignorarId,
  );
}

/// Valida e salva a reserva, impedindo datas sobrepostas no mesmo imóvel.
class SalvarReserva {
  const SalvarReserva(this._repo, this._disponibilidade);
  final ReservaRepository _repo;
  final ConsultarDisponibilidade _disponibilidade;

  Future<Reserva> call(Reserva r) async {
    if (r.imovelId.isEmpty) throw const DomainException('Selecione o imóvel.');
    if (!r.bloqueio && (r.hospedeId == null || r.hospedeId!.isEmpty)) {
      throw const DomainException('Selecione o hóspede.');
    }
    if (!r.checkOut.isAfter(r.checkIn)) {
      throw const DomainException('O check-out deve ser depois do check-in.');
    }
    if (!r.bloqueio) {
      if (r.hospedes < 1) {
        throw const DomainException('Informe o número de hóspedes.');
      }
      if (r.valorDiaria <= 0) {
        throw const DomainException('Informe o valor da diária.');
      }
      if (r.desconto > r.subtotal + r.taxaLimpeza) {
        throw const DomainException(
          'O desconto é maior que o valor da estadia.',
        );
      }
      if (r.valorPago > r.total) {
        throw const DomainException(
          'O valor pago é maior que o total da reserva.',
        );
      }
    }
    if (r.ocupa) {
      final conflitos = await _disponibilidade(
        imovelId: r.imovelId,
        checkIn: r.checkIn,
        checkOut: r.checkOut,
        ignorarId: r.id,
      );
      if (conflitos.isNotEmpty) {
        final c = conflitos.first;
        throw DomainException(
          'Período indisponível: conflita com '
          '${c.bloqueio ? 'um bloqueio' : 'a reserva ${c.numero}'} '
          '(${formatDate(c.checkIn)} a ${formatDate(c.checkOut)}).',
        );
      }
    }
    // O servidor repete a checagem de conflito (dois usuários ao mesmo tempo).
    return _repo.salvar(r);
  }
}

class RemoverReserva {
  const RemoverReserva(this._repo);
  final ReservaRepository _repo;

  Future<void> call(String id) => _repo.remover(id);
}

/// Confirma ou cancela. Reativar uma reserva cancelada exige o período livre.
class AlterarSituacaoReserva {
  const AlterarSituacaoReserva(this._repo, this._salvar);
  final ReservaRepository _repo;
  final SalvarReserva _salvar;

  Future<void> call(Reserva r, SituacaoReserva situacao) async {
    if (r.situacao == situacao) return;
    final nova = r.copyWith(situacao: situacao);
    if (situacao == SituacaoReserva.cancelada) {
      await _repo.salvar(nova);
    } else {
      await _salvar(nova);
    }
  }
}

/// Registra o pagamento do saldo restante.
class QuitarReserva {
  const QuitarReserva(this._repo);
  final ReservaRepository _repo;

  Future<void> call(Reserva r) {
    if (r.saldo <= 0) throw const DomainException('A reserva já está quitada.');
    return _repo.salvar(r.copyWith(valorPago: r.total));
  }
}
