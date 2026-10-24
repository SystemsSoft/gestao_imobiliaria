import '../../../../core/config/empresa_info.dart';
import 'modelo_contrato.dart';

/// Campo do sistema que pode ser usado no texto do modelo.
class CampoModelo {
  const CampoModelo(this.chave, this.descricao, this.grupo, this.exemplo);

  final String chave;
  final String descricao;
  final String grupo;

  /// Valor usado na visualização do modelo.
  final String exemplo;

  String get marcador => '{{$chave}}';
}

const _qualificacaoExemplo =
    'Maria da Silva, brasileira, casada, professora, CPF 123.456.789-09, '
    'residente em Rua das Flores, 100, Icaraí, Niterói/RJ';

const _qualificacao2Exemplo =
    'João Pereira, brasileiro, solteiro, engenheiro, CPF 987.654.321-00, '
    'residente em Av. Central, 500, Centro, Niterói/RJ';

const _enderecoExemplo =
    'Rua Miguel de Frias, 120, apto 302, Icaraí, Niterói/RJ, CEP 24220-001';

const _empresa = [
  CampoModelo(
    'empresa_nome',
    'Nome da imobiliária/corretor',
    'Imobiliária',
    'Imobiliária Exemplo',
  ),
  CampoModelo('empresa_creci', 'CRECI', 'Imobiliária', 'CRECI 00000 UF'),
  CampoModelo(
    'empresa_documento',
    'CNPJ/CPF da imobiliária',
    'Imobiliária',
    '11.222.333/0001-81',
  ),
  CampoModelo(
    'empresa_endereco',
    'Endereço da imobiliária',
    'Imobiliária',
    'Rua Moreira César, 100, Icaraí, Niterói/RJ',
  ),
  CampoModelo(
    'empresa_telefone',
    'Telefone da imobiliária',
    'Imobiliária',
    '(21) 99999-0000',
  ),
  CampoModelo(
    'empresa_email',
    'E-mail da imobiliária',
    'Imobiliária',
    'contato@imobiliaria.com.br',
  ),
  CampoModelo(
    'cidade_data',
    'Cidade e data por extenso',
    'Contrato',
    'Niterói, 5 de janeiro de 2027.',
  ),
  CampoModelo('numero_contrato', 'Número do contrato', 'Contrato', 'LOC-0001'),
  CampoModelo(
    'clausulas_adicionais',
    'Cláusulas adicionais do contrato',
    'Contrato',
    'Não há.',
  ),
];

const _imovel = [
  CampoModelo('imovel_tipo', 'Tipo do imóvel', 'Imóvel', 'Apartamento'),
  CampoModelo(
    'imovel_endereco',
    'Endereço completo do imóvel',
    'Imóvel',
    _enderecoExemplo,
  ),
];

const camposLocacao = [
  ..._empresa,
  ..._imovel,
  CampoModelo(
    'locador_nome',
    'Nome do(s) locador(es)',
    'Partes',
    'Maria da Silva',
  ),
  CampoModelo(
    'locador_qualificacao',
    'Qualificação do(s) locador(es)',
    'Partes',
    _qualificacaoExemplo,
  ),
  CampoModelo('locatario_nome', 'Nome do locatário', 'Partes', 'João Pereira'),
  CampoModelo(
    'locatario_qualificacao',
    'Qualificação do locatário',
    'Partes',
    _qualificacao2Exemplo,
  ),
  CampoModelo(
    'fiador_qualificacao',
    'Qualificação do fiador',
    'Partes',
    'Não há.',
  ),
  CampoModelo(
    'finalidade',
    'Residencial ou comercial',
    'Imóvel',
    'residencial',
  ),
  CampoModelo('valor_aluguel', r'Valor do aluguel (R$)', 'Valores', '3.200,00'),
  CampoModelo(
    'valor_aluguel_extenso',
    'Aluguel por extenso',
    'Valores',
    'três mil e duzentos reais',
  ),
  CampoModelo('dia_vencimento', 'Dia do vencimento', 'Prazos', '10'),
  CampoModelo('data_inicio', 'Início da locação', 'Prazos', '05/01/2027'),
  CampoModelo('data_fim', 'Término da locação', 'Prazos', '04/07/2029'),
  CampoModelo('prazo_meses', 'Prazo em meses', 'Prazos', '30'),
  CampoModelo(
    'indice_reajuste',
    'Índice de reajuste',
    'Valores',
    'IGP-M (FGV)',
  ),
  CampoModelo('garantia', 'Modalidade de garantia', 'Garantia', 'Fiador'),
  CampoModelo('valor_garantia', 'Valor da garantia (caução)', 'Garantia', ''),
  CampoModelo('multa_atraso', 'Multa por atraso (%)', 'Valores', '10'),
  CampoModelo('juros_mes', 'Juros de mora ao mês (%)', 'Valores', '1'),
  CampoModelo(
    'taxa_administracao',
    'Taxa de administração (%)',
    'Valores',
    '10',
  ),
];

const camposVenda = [
  ..._empresa,
  ..._imovel,
  CampoModelo(
    'vendedor_nome',
    'Nome do(s) vendedor(es)',
    'Partes',
    'Maria da Silva',
  ),
  CampoModelo(
    'vendedor_qualificacao',
    'Qualificação do(s) vendedor(es)',
    'Partes',
    _qualificacaoExemplo,
  ),
  CampoModelo(
    'comprador_nome',
    'Nome do(s) comprador(es)',
    'Partes',
    'João Pereira',
  ),
  CampoModelo(
    'comprador_qualificacao',
    'Qualificação do(s) comprador(es)',
    'Partes',
    _qualificacao2Exemplo,
  ),
  CampoModelo('imovel_matricula', 'Matrícula do imóvel', 'Imóvel', '12.345'),
  CampoModelo(
    'imovel_inscricao',
    'Inscrição municipal (IPTU)',
    'Imóvel',
    '01.234.567-8',
  ),
  CampoModelo('data_venda', 'Data da venda', 'Contrato', '05/01/2027'),
  CampoModelo('valor_venda', r'Preço total (R$)', 'Valores', '450.000,00'),
  CampoModelo(
    'valor_venda_extenso',
    'Preço total por extenso',
    'Valores',
    'quatrocentos e cinquenta mil reais',
  ),
  CampoModelo('valor_entrada', r'Entrada/sinal (R$)', 'Pagamento', '90.000,00'),
  CampoModelo(
    'valor_entrada_extenso',
    'Entrada por extenso',
    'Pagamento',
    'noventa mil reais',
  ),
  CampoModelo(
    'forma_pagamento',
    'À vista, bancário ou próprio',
    'Pagamento',
    'Financiamento próprio',
  ),
  CampoModelo(
    'condicoes_pagamento',
    'Descrição das condições de pagamento',
    'Pagamento',
    'a) R\$ 90.000,00 de entrada; b) o saldo em 48 parcelas mensais de R\$ 8.500,00.',
  ),
  CampoModelo(
    'valor_financiado',
    r'Saldo financiado (R$)',
    'Pagamento',
    '360.000,00',
  ),
  CampoModelo('numero_parcelas', 'Quantidade de parcelas', 'Pagamento', '48'),
  CampoModelo(
    'valor_parcela',
    r'Valor da 1ª parcela (R$)',
    'Pagamento',
    '8.500,00',
  ),
  CampoModelo(
    'taxa_juros',
    'Juros do financiamento (% a.m.)',
    'Pagamento',
    '0,9',
  ),
  CampoModelo(
    'sistema_amortizacao',
    'Price, SAC ou sem juros',
    'Pagamento',
    'Tabela Price',
  ),
  CampoModelo(
    'primeiro_vencimento',
    'Vencimento da 1ª parcela',
    'Pagamento',
    '10/02/2027',
  ),
  CampoModelo(
    'credor',
    'Quem recebe as parcelas',
    'Pagamento',
    'Maria da Silva',
  ),
  CampoModelo('multa_atraso', 'Multa por atraso (%)', 'Valores', '2'),
  CampoModelo('juros_mes', 'Juros de mora ao mês (%)', 'Valores', '1'),
  CampoModelo(
    'comissao_percentual',
    'Comissão de corretagem (%)',
    'Valores',
    '6',
  ),
];

const camposTemporada = [
  ..._empresa,
  ..._imovel,
  CampoModelo(
    'locador_qualificacao',
    'Qualificação do proprietário',
    'Partes',
    _qualificacaoExemplo,
  ),
  CampoModelo('hospede_nome', 'Nome do hóspede', 'Partes', 'João Pereira'),
  CampoModelo(
    'hospede_qualificacao',
    'Qualificação do hóspede',
    'Partes',
    _qualificacao2Exemplo,
  ),
  CampoModelo('check_in', 'Data de entrada', 'Prazos', '10/02/2027'),
  CampoModelo('check_out', 'Data de saída', 'Prazos', '15/02/2027'),
  CampoModelo('noites', 'Quantidade de noites', 'Prazos', '5'),
  CampoModelo('numero_hospedes', 'Número de hóspedes', 'Partes', '4'),
  CampoModelo('valor_diaria', r'Valor da diária (R$)', 'Valores', '650,00'),
  CampoModelo('taxa_limpeza', r'Taxa de limpeza (R$)', 'Valores', '150,00'),
  CampoModelo(
    'valor_total',
    r'Valor total da estadia (R$)',
    'Valores',
    '3.400,00',
  ),
  CampoModelo(
    'valor_total_extenso',
    'Total por extenso',
    'Valores',
    'três mil e quatrocentos reais',
  ),
  CampoModelo('caucao', r'Caução (R$)', 'Garantia', '1.000,00'),
  CampoModelo(
    'forma_pagamento',
    'Forma de pagamento',
    'Valores',
    '30% de sinal e o restante no check-in',
  ),
];

const camposAdministracao = [
  ..._empresa,
  ..._imovel,
  CampoModelo(
    'proprietario_nome',
    'Nome do proprietário',
    'Partes',
    'Maria da Silva',
  ),
  CampoModelo(
    'proprietario_qualificacao',
    'Qualificação do proprietário',
    'Partes',
    _qualificacaoExemplo,
  ),
  CampoModelo(
    'taxa_administracao',
    'Taxa de administração (%)',
    'Valores',
    '10',
  ),
  CampoModelo(
    'taxa_intermediacao',
    'Taxa de intermediação (%)',
    'Valores',
    '100',
  ),
  CampoModelo('prazo_meses', 'Prazo em meses', 'Prazos', '24'),
  CampoModelo('data_inicio', 'Início da administração', 'Prazos', '05/01/2027'),
  CampoModelo('dia_repasse', 'Dia do repasse ao proprietário', 'Prazos', '10'),
];

const camposAutorizacao = [
  ..._empresa,
  ..._imovel,
  CampoModelo(
    'proprietario_nome',
    'Nome do proprietário',
    'Partes',
    'Maria da Silva',
  ),
  CampoModelo(
    'proprietario_qualificacao',
    'Qualificação do proprietário',
    'Partes',
    _qualificacaoExemplo,
  ),
  CampoModelo('imovel_matricula', 'Matrícula do imóvel', 'Imóvel', '12.345'),
  CampoModelo(
    'valor_pretendido',
    r'Preço pretendido (R$)',
    'Valores',
    '450.000,00',
  ),
  CampoModelo(
    'valor_pretendido_extenso',
    'Preço por extenso',
    'Valores',
    'quatrocentos e cinquenta mil reais',
  ),
  CampoModelo(
    'comissao_percentual',
    'Comissão de corretagem (%)',
    'Valores',
    '6',
  ),
  CampoModelo('prazo_dias', 'Prazo da autorização (dias)', 'Prazos', '90'),
  CampoModelo('data_inicio', 'Início da autorização', 'Prazos', '05/01/2027'),
  CampoModelo('data_fim', 'Fim da autorização', 'Prazos', '05/04/2027'),
];

const camposOutros = [
  ..._empresa,
  ..._imovel,
  CampoModelo(
    'parte_a_qualificacao',
    'Qualificação da 1ª parte',
    'Partes',
    _qualificacaoExemplo,
  ),
  CampoModelo(
    'parte_b_qualificacao',
    'Qualificação da 2ª parte',
    'Partes',
    _qualificacao2Exemplo,
  ),
  CampoModelo(
    'objeto',
    'Objeto do documento',
    'Contrato',
    'distrato do contrato de locação nº LOC-0001',
  ),
  CampoModelo('data', 'Data', 'Contrato', '05/01/2027'),
  CampoModelo('valor', r'Valor (R$)', 'Valores', '5.000,00'),
  CampoModelo(
    'valor_extenso',
    'Valor por extenso',
    'Valores',
    'cinco mil reais',
  ),
];

List<CampoModelo> camposModelo(TipoModelo tipo) => switch (tipo) {
  TipoModelo.locacao => camposLocacao,
  TipoModelo.venda => camposVenda,
  TipoModelo.temporada => camposTemporada,
  TipoModelo.administracao => camposAdministracao,
  TipoModelo.autorizacao => camposAutorizacao,
  TipoModelo.outros => camposOutros,
};

/// Descrição por chave, para validação e legenda.
Map<String, String> camposDoModelo(TipoModelo tipo) => {
  for (final c in camposModelo(tipo)) c.chave: c.descricao,
};

/// Valores dos campos {{empresa_...}}, vindos da Personalização.
Map<String, String> valoresEmpresa() {
  final e = EmpresaInfo.atual;
  return {
    'empresa_nome': e.nome,
    'empresa_creci': e.creci,
    'empresa_documento': e.documento,
    'empresa_endereco': e.endereco,
    'empresa_telefone': e.telefone,
    'empresa_email': e.email,
  };
}
