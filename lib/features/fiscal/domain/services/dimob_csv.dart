import '../entities/dimob.dart';

/// Dados da DIMOB em CSV (separador ;) para conferência ou digitação no
/// programa da Receita. Não é o arquivo de transmissão oficial.
class DimobCsv {
  const DimobCsv();

  String _n(double v) => v.toStringAsFixed(2).replaceAll('.', ',');
  String _t(String s) => s.replaceAll(';', ',').replaceAll('\n', ' ');

  String gerar(DeclaracaoDimob d) {
    final b = StringBuffer()
      ..writeln('DIMOB;ano-calendario;${d.ano}')
      ..writeln(
        'DECLARANTE;${_t(d.declarante.nome)};${d.declarante.documento};'
        '${_t(d.declarante.responsavelNome)};${d.declarante.responsavelCpf};'
        '${d.declarante.retificadora ? 'RETIFICADORA ${d.declarante.numeroRecibo}' : 'ORIGINAL'}',
      )
      ..writeln()
      ..writeln(
        'LOCACAO;contrato;data_contrato;locadores;documentos_locadores;locatario;'
        'documento_locatario;tipo_imovel;endereco;mes;aluguel_recebido;encargos_mora;comissao;irrf',
      );
    for (final l in d.locacoes) {
      for (var m = 0; m < 12; m++) {
        if (l.aluguel[m] == 0 &&
            l.encargos[m] == 0 &&
            l.comissao[m] == 0 &&
            l.irrf[m] == 0) {
          continue;
        }
        b.writeln(
          [
            'LOCACAO',
            l.numero,
            _data(l.dataContrato),
            _t(l.locadores.map((p) => p.nome).join(' | ')),
            l.locadores.map((p) => p.documento).join(' | '),
            _t(l.locatario.nome),
            l.locatario.documento,
            l.imovel.tipo,
            _t(l.imovel.endereco),
            '${m + 1}/${d.ano}',
            _n(l.aluguel[m]),
            _n(l.encargos[m]),
            _n(l.comissao[m]),
            _n(l.irrf[m]),
          ].join(';'),
        );
      }
    }
    b
      ..writeln()
      ..writeln(
        'VENDA;contrato;data_contrato;vendedores;documentos_vendedores;compradores;'
        'documentos_compradores;tipo_imovel;endereco;valor_operacao;mes;valor_recebido;presumido',
      );
    for (final v in d.vendas) {
      for (var m = 0; m < 12; m++) {
        if (v.recebido[m] == 0) continue;
        b.writeln(
          [
            'VENDA',
            v.numero,
            _data(v.dataContrato),
            _t(v.vendedores.map((p) => p.nome).join(' | ')),
            v.vendedores.map((p) => p.documento).join(' | '),
            _t(v.compradores.map((p) => p.nome).join(' | ')),
            v.compradores.map((p) => p.documento).join(' | '),
            v.imovel.tipo,
            _t(v.imovel.endereco),
            _n(v.valorOperacao),
            '${m + 1}/${d.ano}',
            _n(v.recebido[m]),
            v.presumido ? 'SIM' : 'NAO',
          ].join(';'),
        );
      }
    }
    return b.toString();
  }

  String _data(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
