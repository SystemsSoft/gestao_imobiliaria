import 'modelo_contrato.dart';

const _comuns = {
  'numero_contrato': 'Número do contrato',
  'imovel_tipo': 'Tipo do imóvel',
  'imovel_endereco': 'Endereço completo do imóvel',
  'multa_atraso': 'Multa por atraso (%)',
  'juros_mes': 'Juros de mora ao mês (%)',
  'clausulas_adicionais': 'Cláusulas adicionais do contrato',
  'empresa_nome': 'Nome da imobiliária/corretor',
  'empresa_creci': 'CRECI',
  'cidade_data': 'Cidade e data por extenso',
};

const camposLocacao = {
  ..._comuns,
  'locador_nome': 'Nome do(s) locador(es)',
  'locador_qualificacao': 'Nome, documento e endereço do(s) locador(es)',
  'locatario_nome': 'Nome do locatário',
  'locatario_qualificacao': 'Nome, documento e endereço do locatário',
  'fiador_qualificacao': 'Nome, documento e endereço do fiador',
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
  'taxa_administracao': 'Taxa de administração (%)',
};

const camposVenda = {
  ..._comuns,
  'vendedor_nome': 'Nome do(s) vendedor(es)',
  'vendedor_qualificacao': 'Nome, documento e endereço do(s) vendedor(es)',
  'comprador_nome': 'Nome do(s) comprador(es)',
  'comprador_qualificacao': 'Nome, documento e endereço do(s) comprador(es)',
  'imovel_matricula': 'Matrícula do imóvel',
  'imovel_inscricao': 'Inscrição municipal (IPTU)',
  'data_venda': 'Data da venda',
  'valor_venda': r'Preço total (R$)',
  'valor_venda_extenso': 'Preço total por extenso',
  'valor_entrada': r'Valor da entrada/sinal (R$)',
  'valor_entrada_extenso': 'Entrada por extenso',
  'forma_pagamento': 'À vista, financiamento bancário ou próprio',
  'condicoes_pagamento': 'Descrição completa das condições de pagamento',
  'valor_financiado': r'Saldo financiado (R$)',
  'numero_parcelas': 'Quantidade de parcelas',
  'valor_parcela': r'Valor da 1ª parcela (R$)',
  'taxa_juros': 'Taxa de juros do financiamento (% a.m.)',
  'sistema_amortizacao': 'Price, SAC ou sem juros',
  'primeiro_vencimento': 'Vencimento da 1ª parcela',
  'credor': 'Quem recebe as parcelas',
  'comissao_percentual': 'Comissão de corretagem (%)',
};

Map<String, String> camposDoModelo(TipoModelo tipo) => switch (tipo) {
  TipoModelo.locacao => camposLocacao,
  TipoModelo.venda => camposVenda,
};
