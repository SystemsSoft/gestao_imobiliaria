import '../../../../core/api/json.dart';
import '../../domain/entities/reserva.dart';
import '../../domain/entities/reserva_enums.dart';

Map<String, Object?> reservaParaJson(Reserva r) => {
  'imovelId': r.imovelId,
  'hospedeId': r.hospedeId,
  'bloqueio': r.bloqueio,
  'motivoBloqueio': r.motivoBloqueio,
  'checkIn': escreverData(r.checkIn),
  'checkOut': escreverData(r.checkOut),
  'hospedes': r.hospedes,
  'valorDiaria': r.valorDiaria,
  'taxaLimpeza': r.taxaLimpeza,
  'desconto': r.desconto,
  'valorPago': r.valorPago,
  'situacao': r.situacao.name,
  'origem': r.origem.name,
  'observacoes': r.observacoes,
};

/// Noites, total e saldo vêm do servidor, mas são recalculados pela entidade.
Reserva reservaDeJson(Map<String, dynamic> j) => Reserva(
  id: j['id'] as String,
  numero: lerTexto(j['numero']),
  imovelId: lerTexto(j['imovelId']),
  hospedeId: j['hospedeId'] as String?,
  bloqueio: j['bloqueio'] as bool? ?? false,
  motivoBloqueio: lerTexto(j['motivoBloqueio']),
  checkIn: lerData(j['checkIn'])!,
  checkOut: lerData(j['checkOut'])!,
  hospedes: lerInt(j['hospedes'], 1),
  valorDiaria: lerDouble(j['valorDiaria']) ?? 0,
  taxaLimpeza: lerDouble(j['taxaLimpeza']) ?? 0,
  desconto: lerDouble(j['desconto']) ?? 0,
  valorPago: lerDouble(j['valorPago']) ?? 0,
  situacao: lerEnum(
    SituacaoReserva.values,
    j['situacao'],
    SituacaoReserva.confirmada,
  ),
  origem: lerEnum(OrigemReserva.values, j['origem'], OrigemReserva.direto),
  observacoes: lerTexto(j['observacoes']),
);
