/// Modelos iniciais de contrato.
const modeloLocacaoResidencial = '''
CONTRATO DE LOCAÇÃO RESIDENCIAL Nº {{numero_contrato}}

LOCADOR(ES): {{locador_qualificacao}}.

LOCATÁRIO: {{locatario_qualificacao}}.

FIADOR: {{fiador_qualificacao}}

ADMINISTRADORA: {{empresa_nome}}, {{empresa_creci}}.

As partes acima qualificadas celebram o presente contrato de locação, regido pela Lei nº 8.245/1991, mediante as cláusulas a seguir.

CLÁUSULA 1ª – DO OBJETO. O LOCADOR dá em locação ao LOCATÁRIO o imóvel ({{imovel_tipo}}) situado em {{imovel_endereco}}, destinado exclusivamente a uso {{finalidade}}.

CLÁUSULA 2ª – DO PRAZO. A locação terá prazo de {{prazo_meses}} meses, com início em {{data_inicio}} e término em {{data_fim}}, data em que o LOCATÁRIO se obriga a restituir o imóvel livre e desocupado, nas condições em que o recebeu.

CLÁUSULA 3ª – DO ALUGUEL. O aluguel mensal é de R\$ {{valor_aluguel}} ({{valor_aluguel_extenso}}), com vencimento todo dia {{dia_vencimento}} de cada mês, pago por boleto, PIX ou outro meio indicado pela ADMINISTRADORA.

CLÁUSULA 4ª – DO REAJUSTE. O aluguel será reajustado a cada 12 (doze) meses pela variação acumulada do {{indice_reajuste}} ou, na sua falta, por outro índice oficial que o substitua.

CLÁUSULA 5ª – DOS ENCARGOS. Além do aluguel, caberá ao LOCATÁRIO o pagamento das despesas ordinárias de condomínio, consumo de água, luz e gás, taxa de lixo e IPTU, salvo disposição em contrário. As despesas extraordinárias de condomínio serão de responsabilidade do LOCADOR.

CLÁUSULA 6ª – DO ATRASO. O pagamento após o vencimento acarretará multa de {{multa_atraso}}% sobre o valor devido, acrescida de juros de mora de {{juros_mes}}% ao mês, calculados pro rata die.

CLÁUSULA 7ª – DA GARANTIA. Em garantia das obrigações deste contrato, fica estabelecida a modalidade {{garantia}} {{valor_garantia}}.

CLÁUSULA 8ª – DA CONSERVAÇÃO. O LOCATÁRIO declara receber o imóvel em perfeito estado, conforme laudo de vistoria anexo, obrigando-se a conservá-lo e devolvê-lo nas mesmas condições, ressalvado o desgaste natural pelo uso normal.

CLÁUSULA 9ª – DAS BENFEITORIAS. Nenhuma obra ou modificação poderá ser feita sem autorização prévia e por escrito do LOCADOR. As benfeitorias realizadas sem autorização não serão indenizadas.

CLÁUSULA 10ª – DA RESCISÃO. A devolução do imóvel antes do término do prazo sujeitará o LOCATÁRIO ao pagamento de multa equivalente a 3 (três) aluguéis, proporcional ao tempo restante do contrato, conforme o art. 4º da Lei nº 8.245/1991.

CLÁUSULA 11ª – DA ADMINISTRAÇÃO. O LOCADOR autoriza a ADMINISTRADORA a receber os aluguéis e encargos e a dar quitação, mediante remuneração de {{taxa_administracao}}% sobre os valores recebidos.

CLÁUSULA 12ª – DISPOSIÇÕES ADICIONAIS. {{clausulas_adicionais}}

CLÁUSULA 13ª – DO FORO. Fica eleito o foro da comarca de situação do imóvel para dirimir quaisquer dúvidas oriundas deste contrato.

E por estarem justas e contratadas, as partes assinam o presente instrumento em 2 (duas) vias de igual teor, na presença de duas testemunhas.

{{cidade_data}}
''';

const modeloCompraVenda = '''
INSTRUMENTO PARTICULAR DE PROMESSA DE COMPRA E VENDA DE IMÓVEL Nº {{numero_contrato}}

PROMITENTE(S) VENDEDOR(ES): {{vendedor_qualificacao}}.

PROMITENTE(S) COMPRADOR(ES): {{comprador_qualificacao}}.

INTERVENIENTE: {{empresa_nome}}, {{empresa_creci}}, na qualidade de corretor intermediador.

As partes acima qualificadas celebram o presente instrumento particular de promessa de compra e venda, que se regerá pelas cláusulas seguintes e pelas disposições do Código Civil.

CLÁUSULA 1ª – DO OBJETO. O(s) VENDEDOR(ES), legítimo(s) proprietário(s) do imóvel ({{imovel_tipo}}) situado em {{imovel_endereco}}, matrícula nº {{imovel_matricula}}, inscrição municipal {{imovel_inscricao}}, promete(m) vendê-lo ao(s) COMPRADOR(ES), livre e desembaraçado de quaisquer ônus, dívidas ou pendências.

CLÁUSULA 2ª – DO PREÇO. O preço certo e ajustado da venda é de R\$ {{valor_venda}} ({{valor_venda_extenso}}), a ser pago da seguinte forma: {{condicoes_pagamento}}

CLÁUSULA 3ª – DO ATRASO. O atraso no pagamento de qualquer parcela sujeitará o(s) COMPRADOR(ES) à multa de {{multa_atraso}}% sobre o valor em atraso, acrescida de juros de mora de {{juros_mes}}% ao mês, calculados pro rata die. O atraso superior a 90 (noventa) dias autoriza a rescisão deste contrato, mediante notificação prévia.

CLÁUSULA 4ª – DOS TÍTULOS. Para representar as parcelas, o(s) COMPRADOR(ES) poderá(ão) emitir notas promissórias em favor de {{credor}}, que serão devolvidas à medida que forem quitadas, sem que isso caracterize novação.

CLÁUSULA 5ª – DA POSSE. A posse do imóvel será transmitida ao(s) COMPRADOR(ES) na data de assinatura deste instrumento, passando a correr por sua conta, a partir de então, todos os tributos, taxas e despesas de condomínio incidentes sobre o imóvel.

CLÁUSULA 6ª – DA ESCRITURA. A escritura definitiva de compra e venda será outorgada após a quitação integral do preço, correndo por conta do(s) COMPRADOR(ES) as despesas de ITBI, escritura e registro.

CLÁUSULA 7ª – DA CORRETAGEM. A comissão de corretagem de {{comissao_percentual}}% sobre o preço de venda é devida ao INTERVENIENTE e considera-se ganha com a assinatura deste instrumento.

CLÁUSULA 8ª – DA IRREVOGABILIDADE. O presente contrato é celebrado em caráter irrevogável e irretratável, obrigando as partes, seus herdeiros e sucessores, ressalvadas as hipóteses de inadimplemento aqui previstas.

CLÁUSULA 9ª – DISPOSIÇÕES ADICIONAIS. {{clausulas_adicionais}}

CLÁUSULA 10ª – DO FORO. Fica eleito o foro da comarca de situação do imóvel para dirimir quaisquer dúvidas oriundas deste contrato.

E, por estarem justas e contratadas, as partes assinam o presente instrumento em 2 (duas) vias de igual teor, na presença de duas testemunhas.

{{cidade_data}}
''';
