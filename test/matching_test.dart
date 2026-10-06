import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/models/contato.dart';
import 'package:marceloimob_gestao/models/enums.dart';
import 'package:marceloimob_gestao/models/imovel.dart';
import 'package:marceloimob_gestao/services/matching.dart';
import 'package:marceloimob_gestao/utils/formatters.dart';

Imovel _imovel({
  Set<Finalidade> finalidades = const {Finalidade.venda},
  StatusImovel status = StatusImovel.disponivel,
  double valor = 500000,
  int quartos = 3,
  String bairro = 'Centro',
}) => Imovel(
  id: 'i1',
  codigo: 'IM-0001',
  titulo: 'Apto',
  finalidades: finalidades,
  status: status,
  valorVenda: valor,
  quartos: quartos,
  bairro: bairro,
  cidade: 'Niterói',
);

Contato _contato(PerfilInteresse? perfil) =>
    Contato(id: 'c1', nome: 'Ana', criadoEm: DateTime(2026), perfil: perfil);

void main() {
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
    expect(m, isNotNull);
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

  test(
    'ignora imóvel indisponível, finalidade diferente e contato sem perfil',
    () {
      const perfil = PerfilInteresse();
      expect(
        avaliarMatch(_contato(perfil), _imovel(status: StatusImovel.vendido)),
        isNull,
      );
      expect(
        avaliarMatch(
          _contato(perfil),
          _imovel(finalidades: {Finalidade.locacao}),
        ),
        isNull,
      );
      expect(avaliarMatch(_contato(null), _imovel()), isNull);
    },
  );

  test('máscaras e conversões', () {
    expect(parseMoney('1.234,56'), 1234.56);
    expect(moneyToText(1234.56), '1.234,56');
    expect(
      cpfCnpjFormatter
          .formatEditUpdate(
            TextEditingValue.empty,
            const TextEditingValue(text: '12345678901'),
          )
          .text,
      '123.456.789-01',
    );
    expect(
      phoneFormatter
          .formatEditUpdate(
            TextEditingValue.empty,
            const TextEditingValue(text: '21987654321'),
          )
          .text,
      '(21) 98765-4321',
    );
  });
}
