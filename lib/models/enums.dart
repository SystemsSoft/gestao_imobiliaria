enum Finalidade {
  venda('Venda', 'Compra'),
  locacao('Locação', 'Locação'),
  temporada('Temporada', 'Temporada');

  const Finalidade(this.label, this.perfilLabel);
  final String label;
  final String perfilLabel;
}

enum TipoImovel {
  apartamento('Apartamento'),
  casa('Casa'),
  casaCondominio('Casa de condomínio'),
  cobertura('Cobertura'),
  kitnet('Kitnet / Studio'),
  flat('Flat'),
  sala('Sala comercial'),
  loja('Loja'),
  galpao('Galpão'),
  predio('Prédio comercial'),
  terreno('Terreno / Lote'),
  sitio('Sítio / Chácara'),
  fazenda('Fazenda'),
  outro('Outro');

  const TipoImovel(this.label);
  final String label;
}

enum StatusImovel {
  disponivel('Disponível'),
  reservado('Reservado'),
  alugado('Alugado'),
  vendido('Vendido'),
  inativo('Inativo');

  const StatusImovel(this.label);
  final String label;
}

enum Mobiliado {
  nao('Não mobiliado'),
  semi('Semimobiliado'),
  sim('Mobiliado');

  const Mobiliado(this.label);
  final String label;
}

enum AnexoTipo {
  foto('Foto'),
  video('Vídeo'),
  arquivo('Arquivo'),
  link('Link');

  const AnexoTipo(this.label);
  final String label;
}

enum TipoPessoa {
  fisica('Pessoa Física'),
  juridica('Pessoa Jurídica');

  const TipoPessoa(this.label);
  final String label;
}

enum PapelContato {
  lead('Lead / Interessado'),
  comprador('Comprador'),
  locatario('Locatário'),
  proprietario('Proprietário'),
  fiador('Fiador'),
  parceiro('Parceiro / Corretor'),
  fornecedor('Fornecedor');

  const PapelContato(this.label);
  final String label;
}

enum OrigemContato {
  site('Site'),
  portal('Portais imobiliários'),
  indicacao('Indicação'),
  placa('Placa / Faixada'),
  instagram('Instagram'),
  facebook('Facebook'),
  whatsapp('WhatsApp'),
  google('Google'),
  evento('Evento / Feira'),
  outro('Outro');

  const OrigemContato(this.label);
  final String label;
}

enum EtapaFunil {
  novo('Novo contato'),
  contato('Em contato'),
  visita('Visita agendada'),
  proposta('Proposta'),
  negociacao('Negociação'),
  fechado('Negócio fechado'),
  perdido('Perdido');

  const EtapaFunil(this.label);
  final String label;
}

enum TipoEvento {
  anotacao('Anotação'),
  lembrete('Lembrete'),
  recado('Recado'),
  visita('Visita'),
  ligacao('Ligação'),
  reuniao('Reunião');

  const TipoEvento(this.label);
  final String label;
}

enum Prioridade {
  baixa('Baixa'),
  normal('Normal'),
  alta('Alta');

  const Prioridade(this.label);
  final String label;
}
