/// Modelo de contrato com campos no formato {{campo}}.
class ModeloContrato {
  const ModeloContrato({
    required this.id,
    required this.nome,
    required this.texto,
  });

  final String id;
  final String nome;
  final String texto;
}

/// Campos aceitos nos modelos de contrato, com descrição.
const camposModeloContrato = {
  'numero_contrato': 'Número do contrato',
  'locador_nome': 'Nome do(s) locador(es)',
  'locador_qualificacao': 'Nome, documento e endereço do(s) locador(es)',
  'locatario_nome': 'Nome do locatário',
  'locatario_qualificacao': 'Nome, documento e endereço do locatário',
  'fiador_qualificacao': 'Nome, documento e endereço do fiador',
  'imovel_tipo': 'Tipo do imóvel',
  'imovel_endereco': 'Endereço completo do imóvel',
  'finalidade': 'Residencial ou comercial',
  'valor_aluguel': r'Valor do aluguel (R$)',
  'valor_aluguel_extenso': 'Valor do aluguel por extenso',
  'dia_vencimento': 'Dia do vencimento',
  'data_inicio': 'Início da locação',
  'data_fim': 'Término da locação',
  'prazo_meses': 'Prazo em meses',
  'indice_reajuste': 'Índice de reajuste',
  'garantia': 'Modalidade de garantia',
  'valor_garantia': 'Valor da garantia (caução)',
  'multa_atraso': 'Multa por atraso (%)',
  'juros_mes': 'Juros de mora ao mês (%)',
  'taxa_administracao': 'Taxa de administração (%)',
  'clausulas_adicionais': 'Cláusulas adicionais do contrato',
  'empresa_nome': 'Nome da imobiliária/corretor',
  'empresa_creci': 'CRECI',
  'cidade_data': 'Cidade e data por extenso',
};
