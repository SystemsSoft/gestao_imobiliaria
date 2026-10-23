import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_imobiliaria/features/crm/domain/entities/contato.dart';
import 'package:gestao_imobiliaria/features/crm/domain/entities/enums.dart';
import 'package:gestao_imobiliaria/features/crm/domain/entities/imovel.dart';
import 'package:gestao_imobiliaria/features/crm/domain/usecases/sugerir_negocios.dart';

Imovel _imovel({
  Set<Finalidade> finalidades = const {Finalidade.venda},
  StatusImovel status = StatusImovel.disponivel,
  double valor = 500000,
}) => Imovel(
  id: 'i1',
  codigo: 'IM-0001',
  titulo: 'Apto',
  finalidades: finalidades,
  status: status,
  valorVenda: valor,
  quartos: 3,
  bairro: 'Centro',
  cidade: 'Niterói',
);

Contato _contato(PerfilInteresse? perfil) =>
    Contato(id: 'c1', nome: 'Ana', criadoEm: DateTime(2026), perfil: perfil);

void main() {
  const sugerir = SugerirNegocios();

  test('perfil compatível gera 100%', () {
    final m = avaliarMatch(
      _contato(
        const PerfilInteresse(
          tipos: {TipoImovel.apartamento},
          cidade: 'niteroi',
          bairros: 'centro, icarai',
          valorMin: 400000,
          valorMax: 600000,
          quartosMin: 2,
        ),
      ),
      _imovel(),
    );
    expect(m!.score, 100);
    expect(m.naoAtende, isEmpty);
  });

  test('valor fora da faixa reduz a pontuação', () {
    final m = avaliarMatch(
      _contato(const PerfilInteresse(valorMax: 300000, quartosMin: 2)),
      _imovel(),
    );
    expect(m!.score, lessThan(100));
    expect(m.naoAtende, isNotEmpty);
  });

  test('ignora indisponível, finalidade diferente e contato sem perfil', () {
    const p = PerfilInteresse();
    expect(
      avaliarMatch(_contato(p), _imovel(status: StatusImovel.vendido)),
      isNull,
    );
    expect(
      avaliarMatch(_contato(p), _imovel(finalidades: {Finalidade.locacao})),
      isNull,
    );
    expect(avaliarMatch(_contato(null), _imovel()), isNull);
  });

  test('paraContato filtra abaixo do mínimo e ordena', () {
    final c = _contato(
      const PerfilInteresse(valorMax: 100, tipos: {TipoImovel.casa}),
    );
    expect(sugerir.paraContato(c, [_imovel()]), isEmpty);
  });
}
