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

const modeloLocacaoComercial = '''
CONTRATO DE LOCAÇÃO COMERCIAL Nº {{numero_contrato}}

LOCADOR(ES): {{locador_qualificacao}}.

LOCATÁRIO: {{locatario_qualificacao}}.

FIADOR: {{fiador_qualificacao}}

ADMINISTRADORA: {{empresa_nome}}, {{empresa_creci}}.

As partes celebram o presente contrato de locação não residencial, regido pela Lei nº 8.245/1991.

CLÁUSULA 1ª – DO OBJETO. O LOCADOR dá em locação ao LOCATÁRIO o imóvel ({{imovel_tipo}}) situado em {{imovel_endereco}}, destinado exclusivamente à atividade comercial do LOCATÁRIO, vedada a mudança de ramo sem autorização por escrito.

CLÁUSULA 2ª – DO PRAZO. A locação terá prazo de {{prazo_meses}} meses, de {{data_inicio}} a {{data_fim}}.

CLÁUSULA 3ª – DO ALUGUEL. O aluguel mensal é de R\$ {{valor_aluguel}} ({{valor_aluguel_extenso}}), com vencimento todo dia {{dia_vencimento}}, reajustado a cada 12 meses pelo {{indice_reajuste}}.

CLÁUSULA 4ª – DOS ENCARGOS. Correm por conta do LOCATÁRIO as despesas de condomínio, consumo, IPTU, taxas e seguro contra incêndio do imóvel, bem como licenças e alvarás necessários à atividade.

CLÁUSULA 5ª – DO ATRASO. O atraso no pagamento sujeita o LOCATÁRIO à multa de {{multa_atraso}}% e juros de {{juros_mes}}% ao mês, pro rata die.

CLÁUSULA 6ª – DA GARANTIA. Modalidade de garantia: {{garantia}} {{valor_garantia}}.

CLÁUSULA 7ª – DA DEVOLUÇÃO. Findo o contrato, o imóvel será devolvido no estado em que foi recebido, respondendo o LOCATÁRIO pelos reparos decorrentes do uso. A rescisão antecipada sujeita o LOCATÁRIO à multa de {{multa_rescisoria_alugueis}} aluguéis, proporcional ao período restante.

CLÁUSULA 8ª – DO AVISO PRÉVIO. A denúncia do contrato por qualquer das partes após o prazo exige aviso por escrito com {{prazo_aviso_dias}} dias de antecedência.

CLÁUSULA 9ª – DISPOSIÇÕES ADICIONAIS. {{clausulas_adicionais}}

CLÁUSULA 10ª – DO FORO. Fica eleito o foro da comarca de {{foro_cidade}} para dirimir quaisquer dúvidas deste contrato.

E, por estarem justas e contratadas, as partes assinam o presente em 2 (duas) vias, na presença de duas testemunhas.

{{cidade_data}}
''';

const modeloTemporada = '''
CONTRATO DE LOCAÇÃO POR TEMPORADA Nº {{numero_contrato}}

LOCADOR: {{locador_qualificacao}}.

HÓSPEDE: {{hospede_qualificacao}}.

INTERMEDIADORA: {{empresa_nome}}, {{empresa_creci}}.

As partes celebram contrato de locação por temporada, nos termos dos arts. 48 a 50 da Lei nº 8.245/1991.

CLÁUSULA 1ª – DO OBJETO. O LOCADOR cede ao HÓSPEDE, para fins de moradia temporária, o imóvel ({{imovel_tipo}}) situado em {{imovel_endereco}}.

CLÁUSULA 2ª – DO PERÍODO. A hospedagem inicia em {{check_in}}, às {{horario_entrada}}, e termina em {{check_out}}, às {{horario_saida}}, totalizando {{noites}} noite(s), para até {{numero_hospedes}} pessoa(s).

CLÁUSULA 3ª – DO VALOR. A diária é de R\$ {{valor_diaria}}, acrescida de taxa de limpeza de R\$ {{taxa_limpeza}}, totalizando R\$ {{valor_total}} ({{valor_total_extenso}}), a pagar da seguinte forma: {{forma_pagamento}}.

CLÁUSULA 4ª – DA CAUÇÃO. O HÓSPEDE entrega caução de R\$ {{caucao}}, devolvida em até 3 (três) dias após a saída, descontados eventuais danos ou débitos.

CLÁUSULA 5ª – DAS REGRAS. O HÓSPEDE obriga-se a respeitar o regulamento do condomínio e o horário de silêncio, não ultrapassar o número de hóspedes e não promover festas ou eventos sem autorização.

CLÁUSULA 6ª – DO CANCELAMENTO. Em caso de cancelamento pelo HÓSPEDE com menos de {{prazo_cancelamento_dias}} dias de antecedência, não haverá devolução do sinal.

CLÁUSULA 7ª – DA DEVOLUÇÃO. O imóvel será entregue limpo e nas condições em que foi recebido, conforme vistoria de entrada.

CLÁUSULA 8ª – DISPOSIÇÕES ADICIONAIS. {{clausulas_adicionais}}

CLÁUSULA 9ª – DO FORO. Fica eleito o foro da comarca de situação do imóvel.

{{cidade_data}}
''';

const modeloAdministracao = '''
CONTRATO DE ADMINISTRAÇÃO DE IMÓVEL Nº {{numero_contrato}}

PROPRIETÁRIO: {{proprietario_qualificacao}}.

ADMINISTRADORA: {{empresa_nome}}, {{empresa_creci}}.

As partes celebram contrato de administração do imóvel descrito abaixo, que se regerá pelas cláusulas seguintes.

CLÁUSULA 1ª – DO OBJETO. O PROPRIETÁRIO confia à ADMINISTRADORA a administração do imóvel ({{imovel_tipo}}) situado em {{imovel_endereco}}, para locação a terceiros.

CLÁUSULA 2ª – DOS PODERES. A ADMINISTRADORA poderá divulgar o imóvel, selecionar interessados, celebrar contratos de locação, receber aluguéis e encargos, dar quitação, cobrar judicial ou extrajudicialmente e contratar reparos de urgência até o limite de R\$ {{limite_reparos}}.

CLÁUSULA 3ª – DO PRAZO. O contrato vigora por {{prazo_meses}} meses a partir de {{data_inicio}}, renovando-se por igual período, salvo aviso por escrito com 30 dias de antecedência.

CLÁUSULA 4ª – DA REMUNERAÇÃO. A ADMINISTRADORA receberá {{taxa_administracao}}% sobre os valores recebidos e {{taxa_intermediacao}}% do primeiro aluguel a título de intermediação.

CLÁUSULA 5ª – DO REPASSE. O repasse ao PROPRIETÁRIO será feito até o dia {{dia_repasse}} de cada mês, descontadas a remuneração e as despesas a seu cargo, acompanhado de demonstrativo.

CLÁUSULA 6ª – DAS OBRIGAÇÕES DO PROPRIETÁRIO. O PROPRIETÁRIO declara ser legítimo dono do imóvel, mantê-lo livre de ônus e fornecer a documentação necessária.

CLÁUSULA 7ª – DISPOSIÇÕES ADICIONAIS. {{clausulas_adicionais}}

CLÁUSULA 8ª – DO FORO. Fica eleito o foro da comarca de situação do imóvel.

{{cidade_data}}
''';

const modeloAutorizacaoVenda = '''
AUTORIZAÇÃO DE VENDA COM EXCLUSIVIDADE Nº {{numero_contrato}}

PROPRIETÁRIO: {{proprietario_qualificacao}}.

CORRETOR: {{empresa_nome}}, {{empresa_creci}}.

O PROPRIETÁRIO autoriza o CORRETOR a promover a venda do imóvel abaixo, nas condições seguintes.

CLÁUSULA 1ª – DO IMÓVEL. {{imovel_tipo}} situado em {{imovel_endereco}}, matrícula nº {{imovel_matricula}}.

CLÁUSULA 2ª – DO PREÇO. O preço pretendido é de R\$ {{valor_pretendido}} ({{valor_pretendido_extenso}}), podendo o CORRETOR negociar condições com anuência do PROPRIETÁRIO.

CLÁUSULA 3ª – DO PRAZO E DA EXCLUSIVIDADE. A autorização vale por {{prazo_dias}} dias, de {{data_inicio}} a {{data_fim}}, com exclusividade para o CORRETOR, vedada a intermediação por terceiros no período.

CLÁUSULA 4ª – DA COMISSÃO. A comissão de corretagem é de {{comissao_percentual}}% sobre o preço da venda, devida ainda que o negócio se concretize durante a vigência com comprador apresentado pelo CORRETOR ou em até {{prazo_protecao_dias}} dias após o término, com pessoa por ele apresentada.

CLÁUSULA 5ª – DAS OBRIGAÇÕES. O CORRETOR divulgará o imóvel e prestará contas das visitas e propostas. O PROPRIETÁRIO fornecerá a documentação e franqueará as visitas agendadas.

CLÁUSULA 6ª – DISPOSIÇÕES ADICIONAIS. {{clausulas_adicionais}}

{{cidade_data}}
''';

const modeloPropostaCompra = '''
PROPOSTA DE COMPRA DE IMÓVEL Nº {{numero_contrato}}

PROPONENTE: {{parte_b_qualificacao}}.

PROPRIETÁRIO: {{parte_a_qualificacao}}.

INTERMEDIAÇÃO: {{empresa_nome}}, {{empresa_creci}}.

O PROPONENTE oferece adquirir o imóvel ({{imovel_tipo}}) situado em {{imovel_endereco}}, pelo valor de R\$ {{valor}} ({{valor_extenso}}), nas condições abaixo.

1. FORMA DE PAGAMENTO: {{objeto}}.

2. VALIDADE DA PROPOSTA: {{validade_dias}} dias a contar de {{data}}.

3. SINAL: o PROPONENTE entrega, a título de sinal e princípio de pagamento, a quantia indicada na forma de pagamento, que será imputada ao preço.

4. A presente proposta, aceita pelo PROPRIETÁRIO, obriga as partes a celebrar o contrato de compra e venda em até {{prazo_contrato_dias}} dias.

{{cidade_data}}
''';

const modeloDistrato = '''
DISTRATO DE CONTRATO DE LOCAÇÃO Nº {{numero_contrato}}

LOCADOR: {{parte_a_qualificacao}}.

LOCATÁRIO: {{parte_b_qualificacao}}.

As partes resolvem, de comum acordo, encerrar o contrato referente ao {{objeto}}, relativo ao imóvel ({{imovel_tipo}}) situado em {{imovel_endereco}}.

CLÁUSULA 1ª – DA ENTREGA. O LOCATÁRIO entregou as chaves em {{data}}, após vistoria conjunta, declarando o LOCADOR receber o imóvel em condições de uso.

CLÁUSULA 2ª – DA QUITAÇÃO. As partes dão-se mútua quitação dos aluguéis e encargos vencidos até a data de entrega, ressalvados débitos de consumo ainda não apurados, de responsabilidade do LOCATÁRIO.

CLÁUSULA 3ª – DA MULTA. {{condicao_multa}}

CLÁUSULA 4ª – DA GARANTIA. A garantia prestada será liberada após a quitação de todos os débitos.

{{cidade_data}}
''';

const modeloReciboSinal = '''
RECIBO DE SINAL E PRINCÍPIO DE PAGAMENTO Nº {{numero_contrato}}

Recebi de {{parte_b_qualificacao}} a importância de R\$ {{valor}} ({{valor_extenso}}), a título de sinal e princípio de pagamento referente ao imóvel ({{imovel_tipo}}) situado em {{imovel_endereco}}, para {{objeto}}.

O valor será imputado ao preço do negócio. Em caso de desistência do pagador, o sinal poderá ser retido, e, em caso de desistência do recebedor, será devolvido em dobro, nos termos do art. 418 do Código Civil.

RECEBEDOR: {{parte_a_qualificacao}}.

INTERMEDIAÇÃO: {{empresa_nome}}, {{empresa_creci}}.

{{cidade_data}}
''';
