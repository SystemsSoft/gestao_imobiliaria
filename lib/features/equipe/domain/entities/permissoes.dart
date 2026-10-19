import 'equipe_enums.dart';

/// Permissões de um usuário: ações por módulo e permissões especiais.
class Permissoes {
  const Permissoes({this.modulos = const {}, this.especiais = const {}});

  final Map<ModuloSistema, Set<AcaoPermissao>> modulos;
  final Set<PermissaoEspecial> especiais;

  bool pode(ModuloSistema m, AcaoPermissao a) =>
      modulos[m]?.contains(a) ?? false;
  bool temEspecial(PermissaoEspecial e) => especiais.contains(e);

  /// Quantidade de ações liberadas em todos os módulos.
  int get totalAcoes => modulos.values.fold(0, (s, a) => s + a.length);

  Permissoes comAcao(ModuloSistema m, AcaoPermissao a, bool liberada) {
    final atual = {...?modulos[m]};
    if (liberada) {
      atual.add(a);
      // Criar, editar e excluir exigem poder ver o módulo.
      if (a != AcaoPermissao.visualizar) atual.add(AcaoPermissao.visualizar);
    } else {
      atual.remove(a);
      if (a == AcaoPermissao.visualizar) atual.clear();
    }
    return Permissoes(modulos: {...modulos, m: atual}, especiais: especiais);
  }

  Permissoes comModulo(ModuloSistema m, Set<AcaoPermissao> acoes) =>
      Permissoes(modulos: {...modulos, m: acoes}, especiais: especiais);

  Permissoes comEspecial(PermissaoEspecial e, bool liberada) => Permissoes(
    modulos: modulos,
    especiais: liberada ? {...especiais, e} : ({...especiais}..remove(e)),
  );

  static const _todas = {
    AcaoPermissao.visualizar,
    AcaoPermissao.criar,
    AcaoPermissao.editar,
    AcaoPermissao.excluir,
  };
  static const _leitura = {AcaoPermissao.visualizar};
  static const _operar = {
    AcaoPermissao.visualizar,
    AcaoPermissao.criar,
    AcaoPermissao.editar,
  };

  /// Permissões sugeridas para cada perfil (podem ser ajustadas depois).
  factory Permissoes.perfil(PerfilAcesso perfil) => switch (perfil) {
    PerfilAcesso.administrador => Permissoes(
      modulos: {for (final m in ModuloSistema.values) m: _todas},
      especiais: PermissaoEspecial.values.toSet(),
    ),
    PerfilAcesso.gerente => Permissoes(
      modulos: {
        for (final m in ModuloSistema.values)
          m: m == ModuloSistema.equipeSeguranca ? _leitura : _todas,
      },
      especiais: {
        PermissaoEspecial.verValoresFinanceiros,
        PermissaoEspecial.exportarDados,
        PermissaoEspecial.verComissoesDeTodos,
      },
    ),
    PerfilAcesso.corretor => const Permissoes(
      modulos: {
        ModuloSistema.cadastrosCrm: _operar,
        ModuloSistema.vendas: _operar,
        ModuloSistema.locacao: _operar,
        ModuloSistema.auditorias: _operar,
        ModuloSistema.contratosRelatorios: _leitura,
        ModuloSistema.site: _leitura,
      },
    ),
    PerfilAcesso.financeiro => const Permissoes(
      modulos: {
        ModuloSistema.financeiro: _todas,
        ModuloSistema.fiscal: _todas,
        ModuloSistema.vendas: _leitura,
        ModuloSistema.locacao: _leitura,
        ModuloSistema.cadastrosCrm: _leitura,
      },
      especiais: {
        PermissaoEspecial.verValoresFinanceiros,
        PermissaoEspecial.exportarDados,
      },
    ),
    PerfilAcesso.atendente => const Permissoes(
      modulos: {
        ModuloSistema.cadastrosCrm: _operar,
        ModuloSistema.locacao: _leitura,
        ModuloSistema.site: _operar,
      },
    ),
  };
}
