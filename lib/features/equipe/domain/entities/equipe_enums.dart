enum PerfilAcesso {
  administrador(
    'Administrador',
    'Acesso total, inclusive usuários e permissões',
  ),
  gerente('Gerente', 'Todos os módulos, sem administrar usuários'),
  corretor('Corretor', 'Cadastros, vendas e locação'),
  financeiro('Financeiro', 'Financeiro, fiscal e consultas'),
  atendente('Atendente', 'Cadastros e atendimento');

  const PerfilAcesso(this.label, this.descricao);
  final String label;
  final String descricao;
}

/// Módulos do menu lateral.
enum ModuloSistema {
  cadastrosCrm('Cadastros e CRM'),
  locacao('Administração de Locação'),
  vendas('Administração de Vendas'),
  financeiro('Financeiro'),
  fiscal('Fiscal'),
  contratosRelatorios('Contratos e Relatórios'),
  equipeSeguranca('Equipe e Segurança'),
  personalizacao('Personalização'),
  site('Site e Leads');

  const ModuloSistema(this.label);
  final String label;
}

enum AcaoPermissao {
  visualizar('Ver'),
  criar('Criar'),
  editar('Editar'),
  excluir('Excluir');

  const AcaoPermissao(this.label);
  final String label;
}

enum PermissaoEspecial {
  verValoresFinanceiros(
    'Ver valores financeiros',
    'Saldos, receitas, despesas e fluxo de caixa',
  ),
  exportarDados(
    'Exportar e imprimir dados',
    'Relatórios, PDFs e cópia de dados',
  ),
  verComissoesDeTodos(
    'Ver comissões de todos',
    'Sem isso, o corretor vê só as próprias comissões',
  ),
  gerenciarUsuarios(
    'Gerenciar usuários',
    'Criar usuários, alterar permissões e encerrar sessões',
  );

  const PermissaoEspecial(this.label, this.descricao);
  final String label;
  final String descricao;
}

enum TipoAtividade {
  login('Entrada no sistema'),
  logout('Saída do sistema'),
  criacao('Criação'),
  edicao('Edição'),
  exclusao('Exclusão'),
  permissao('Permissões'),
  atendimento('Atendimento'),
  comissao('Comissão'),
  chat('Chat');

  const TipoAtividade(this.label);
  final String label;
}

enum StatusFila {
  disponivel('Disponível'),
  emAtendimento('Em atendimento'),
  ausente('Ausente');

  const StatusFila(this.label);
  final String label;
}

enum OrigemAtendimento {
  plantao('Plantão'),
  telefone('Telefone'),
  whatsapp('WhatsApp'),
  portal('Portal imobiliário'),
  site('Site'),
  indicacao('Indicação');

  const OrigemAtendimento(this.label);
  final String label;
}

enum TipoComissao {
  venda('Venda', true),
  locacao('Locação', true),
  captacao('Captação', true),
  bonus('Bônus', false),
  ajuste('Ajuste', false);

  const TipoComissao(this.label, this.porPercentual);
  final String label;

  /// Calculada por percentual sobre uma base; as demais têm valor livre.
  final bool porPercentual;
}

enum StatusComissao {
  pendente('A aprovar'),
  aprovada('A pagar'),
  paga('Paga'),
  cancelada('Cancelada');

  const StatusComissao(this.label);
  final String label;
}

double arredondar(double v) => (v * 100).roundToDouble() / 100;
