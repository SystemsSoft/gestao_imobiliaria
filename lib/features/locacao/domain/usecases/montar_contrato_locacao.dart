import '../../../../core/config/empresa_info.dart';
import '../../../contratos/domain/entities/campos_modelo.dart';
import '../../../../core/utils/extenso.dart';
import '../../../../core/utils/formatters.dart';
import '../../../contratos/domain/entities/contrato_documento.dart';
import '../../../contratos/domain/entities/modelo_contrato.dart';
import '../../../contratos/domain/usecases/modelo_usecases.dart';
import '../../../contratos/domain/usecases/qualificacao.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../entities/contrato_locacao.dart';

/// Preenche um modelo de locação com os dados do contrato.
class MontarContratoLocacao {
  const MontarContratoLocacao([this._preencher = const PreencherModelo()]);
  final PreencherModelo _preencher;

  ContratoDocumento call({
    required ModeloContrato modelo,
    required ContratoLocacao contrato,
    required Contato? Function(String id) contato,
    required Imovel? imovel,
    DateTime? data,
  }) {
    final locadores = [
      for (final b in contrato.beneficiarios) ?contato(b.contatoId),
    ];
    final locatario = contato(contrato.locatarioId);
    final fiador = contrato.fiadorId == null
        ? null
        : contato(contrato.fiadorId!);

    return _preencher(
      modelo: modelo,
      valores: {
        'numero_contrato': contrato.numero,
        'locador_nome': locadores.map((c) => c.nome).join(', '),
        'locador_qualificacao': locadores.map(qualificacaoContato).join('; '),
        'locatario_nome': locatario?.nome ?? '',
        'locatario_qualificacao': locatario == null
            ? ''
            : qualificacaoContato(locatario),
        'fiador_qualificacao': fiador == null
            ? 'Não há.'
            : qualificacaoContato(fiador),
        'imovel_tipo': imovel?.tipo.label ?? '',
        'imovel_endereco': imovel == null ? '' : enderecoCompleto(imovel),
        'finalidade': contrato.finalidade.label.toLowerCase(),
        'valor_aluguel': moneyToText(contrato.valorAluguel),
        'valor_aluguel_extenso': valorPorExtenso(contrato.valorAluguel),
        'dia_vencimento': '${contrato.diaVencimento}',
        'data_inicio': formatDate(contrato.dataInicio),
        'data_fim': formatDate(contrato.dataFim),
        'prazo_meses': '${contrato.prazoMeses}',
        'indice_reajuste': contrato.indiceReajuste.label,
        'garantia': contrato.garantia.label,
        'valor_garantia': contrato.valorGarantia == null
            ? ''
            : 'no valor de ${formatMoney(contrato.valorGarantia)} '
                  '(${valorPorExtenso(contrato.valorGarantia!)})',
        'multa_atraso': decimalToText(contrato.multaAtraso),
        'juros_mes': decimalToText(contrato.jurosMes),
        'taxa_administracao': decimalToText(contrato.taxaAdministracao),
        'clausulas_adicionais': contrato.clausulasAdicionais.isEmpty
            ? 'Não há.'
            : contrato.clausulasAdicionais,
        ...valoresEmpresa(),
        'cidade_data': cidadeData(imovel?.cidade ?? '', data ?? DateTime.now()),
      },
      assinaturas: [
        for (final l in locadores) 'LOCADOR: ${l.nome}',
        if (locatario != null) 'LOCATÁRIO: ${locatario.nome}',
        if (fiador != null) 'FIADOR: ${fiador.nome}',
        'ADMINISTRADORA: ${EmpresaInfo.nome}',
        'TESTEMUNHA 1',
        'TESTEMUNHA 2',
      ],
    );
  }
}
