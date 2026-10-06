import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../domain/entities/reserva.dart';
import 'cores_reserva.dart';

/// Linha do tempo do mês com um imóvel por linha e uma barra por reserva.
/// A barra começa na metade do dia de check-in e termina na metade do dia
/// de check-out.
class LinhaDoTempoView extends StatelessWidget {
  const LinhaDoTempoView({
    super.key,
    required this.ano,
    required this.mes,
    required this.imoveis,
    required this.reservasDe,
    required this.hoje,
    required this.nomeHospede,
    required this.onReserva,
    required this.onDiaLivre,
  });

  final int ano;
  final int mes;
  final List<Imovel> imoveis;
  final List<Reserva> Function(String imovelId) reservasDe;
  final DateTime hoje;
  final String Function(Reserva) nomeHospede;
  final ValueChanged<Reserva> onReserva;
  final void Function(String imovelId, DateTime dia) onDiaLivre;

  static const _larguraDia = 40.0;
  static const _altura = 52.0;
  static const _larguraRotulo = 150.0;

  @override
  Widget build(BuildContext context) {
    final dias = DateTime(ano, mes + 1, 0).day;
    final largura = dias * _larguraDia;
    final inicioMes = DateTime(ano, mes);
    const semana = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

    final rotulos = Column(
      children: [
        const SizedBox(height: 40),
        for (final i in imoveis)
          Container(
            height: _altura,
            width: _larguraRotulo,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i.codigo,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                Text(
                  i.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );

    final grade = SizedBox(
      width: largura,
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                for (var d = 1; d <= dias; d++)
                  Container(
                    width: _larguraDia,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: DateTime(ano, mes, d) == hoje
                          ? AppColors.gold.withValues(alpha: 0.2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          semana[DateTime(ano, mes, d).weekday % 7],
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          '$d',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          for (final i in imoveis) _linha(i, dias, inicioMes),
        ],
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        rotulos,
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: grade,
          ),
        ),
      ],
    );
  }

  Widget _linha(Imovel i, int dias, DateTime inicioMes) {
    final fimMes = DateTime(ano, mes + 1);
    return SizedBox(
      height: _altura,
      child: Stack(
        children: [
          // Fundo: células clicáveis para criar reservas em dias livres.
          Row(
            children: [
              for (var d = 1; d <= dias; d++)
                GestureDetector(
                  onTap: () => onDiaLivre(i.id, DateTime(ano, mes, d)),
                  child: Container(
                    width: _larguraDia,
                    height: _altura,
                    decoration: BoxDecoration(
                      color: DateTime(ano, mes, d) == hoje
                          ? AppColors.gold.withValues(alpha: 0.08)
                          : null,
                      border: Border(
                        left: BorderSide(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (final r in reservasDe(i.id))
            if (r.checkIn.isBefore(fimMes) && r.checkOut.isAfter(inicioMes))
              _barra(r, inicioMes, fimMes),
        ],
      ),
    );
  }

  Widget _barra(Reserva r, DateTime inicioMes, DateTime fimMes) {
    final de = r.checkIn.isBefore(inicioMes) ? inicioMes : r.checkIn;
    final ate = r.checkOut.isAfter(fimMes) ? fimMes : r.checkOut;
    // Começa/termina na metade do dia, exceto quando a reserva é cortada pelo mês.
    final inicioMeio = !r.checkIn.isBefore(inicioMes);
    final fimMeio = !r.checkOut.isAfter(fimMes);
    final esquerda =
        de.difference(inicioMes).inDays * _larguraDia +
        (inicioMeio ? _larguraDia / 2 : 0);
    final direita =
        ate.difference(inicioMes).inDays * _larguraDia +
        (fimMeio ? _larguraDia / 2 : 0);
    final largura = (direita - esquerda).clamp(
      _larguraDia / 2,
      double.infinity,
    );
    final cor = corDaReserva(r, hoje);
    return Positioned(
      left: esquerda,
      top: 8,
      width: largura,
      height: _altura - 16,
      child: Tooltip(
        message: '${nomeHospede(r)} • ${r.noites} noite(s)',
        child: GestureDetector(
          onTap: () => onReserva(r),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              nomeHospede(r),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.navyDark,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
