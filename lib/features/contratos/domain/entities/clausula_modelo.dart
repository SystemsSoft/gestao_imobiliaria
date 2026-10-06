/// Cláusula pronta que pode ser inserida em qualquer modelo.
class ClausulaModelo {
  const ClausulaModelo(this.titulo, this.texto);

  final String titulo;

  /// Texto com o título já incluído; "N" é trocado pelo número da cláusula.
  final String texto;
}

const biblioteca = <ClausulaModelo>[
  ClausulaModelo(
    'Multa e juros por atraso',
    'CLÁUSULA Nª – DO ATRASO. O pagamento após o vencimento acarretará multa de {{multa_atraso}}% sobre o valor devido, acrescida de juros de mora de {{juros_mes}}% ao mês, calculados pro rata die.',
  ),
  ClausulaModelo(
    'Reajuste anual',
    'CLÁUSULA Nª – DO REAJUSTE. O valor será reajustado a cada 12 (doze) meses pela variação acumulada do índice contratado ou, na sua falta, por outro índice oficial que o substitua.',
  ),
  ClausulaModelo(
    'Conservação do imóvel',
    'CLÁUSULA Nª – DA CONSERVAÇÃO. O ocupante declara receber o imóvel em perfeito estado, conforme vistoria, obrigando-se a conservá-lo e devolvê-lo nas mesmas condições, ressalvado o desgaste natural pelo uso normal.',
  ),
  ClausulaModelo(
    'Benfeitorias',
    'CLÁUSULA Nª – DAS BENFEITORIAS. Nenhuma obra ou modificação poderá ser feita sem autorização prévia e por escrito do proprietário. As benfeitorias realizadas sem autorização não serão indenizadas.',
  ),
  ClausulaModelo(
    'Animais de estimação',
    'CLÁUSULA Nª – DOS ANIMAIS. É permitida a permanência de animais de estimação de pequeno porte, ficando o responsável obrigado a observar o regulamento do condomínio e a reparar eventuais danos.',
  ),
  ClausulaModelo(
    'Rescisão antecipada',
    'CLÁUSULA Nª – DA RESCISÃO. A devolução antecipada do imóvel sujeitará a parte a multa equivalente a 3 (três) aluguéis, proporcional ao tempo restante do contrato, conforme o art. 4º da Lei nº 8.245/1991.',
  ),
  ClausulaModelo(
    'Aviso prévio',
    'CLÁUSULA Nª – DO AVISO PRÉVIO. Qualquer das partes poderá encerrar a relação mediante aviso por escrito com antecedência mínima de 30 (trinta) dias.',
  ),
  ClausulaModelo(
    'Garantia por caução',
    'CLÁUSULA Nª – DA CAUÇÃO. Como garantia das obrigações, o ocupante entrega a caução indicada neste contrato, que será devolvida, sem correção, em até 30 (trinta) dias após a entrega das chaves e a quitação de todos os débitos.',
  ),
  ClausulaModelo(
    'Confidencialidade e LGPD',
    'CLÁUSULA Nª – DA PROTEÇÃO DE DADOS. As partes autorizam o tratamento dos dados pessoais constantes deste instrumento para a execução do contrato e o cumprimento de obrigações legais, nos termos da Lei nº 13.709/2018.',
  ),
  ClausulaModelo(
    'Comissão de corretagem',
    'CLÁUSULA Nª – DA CORRETAGEM. A comissão de corretagem de {{comissao_percentual}}% é devida ao corretor e considera-se ganha com a assinatura deste instrumento.',
  ),
  ClausulaModelo(
    'Vistoria e entrega das chaves',
    'CLÁUSULA Nª – DA VISTORIA. A entrega das chaves será precedida de vistoria assinada pelas partes, cujo laudo integra este contrato.',
  ),
  ClausulaModelo(
    'Foro',
    'CLÁUSULA Nª – DO FORO. Fica eleito o foro da comarca de situação do imóvel para dirimir quaisquer dúvidas oriundas deste instrumento.',
  ),
  ClausulaModelo(
    'Assinatura e testemunhas',
    'E, por estarem justas e contratadas, as partes assinam o presente instrumento em 2 (duas) vias de igual teor, na presença de duas testemunhas.',
  ),
];
