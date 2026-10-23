import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_imobiliaria/core/api/sessao_api.dart';
import 'package:gestao_imobiliaria/core/arquivos/arquivo_repository.dart';
import 'package:gestao_imobiliaria/core/arquivos/arquivo_repository_api.dart';
import 'package:gestao_imobiliaria/core/arquivos/arquivo_repository_memoria.dart';
import 'package:gestao_imobiliaria/core/errors/domain_exception.dart';
import 'package:gestao_imobiliaria/features/crm/domain/entities/enums.dart';
import 'package:gestao_imobiliaria/features/crm/domain/usecases/imovel_usecases.dart';

import '../apoio/servidor_falso.dart';

final _png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);

ArquivoEscolhido _escolhido(String nome, {int? tamanho}) => ArquivoEscolhido(
  nome: nome,
  tamanho: tamanho ?? _png.length,
  ler: () async => _png,
);

void main() {
  late ServidorFalso servidor;
  late SessaoApi sessao;

  setUp(() {
    servidor = ServidorFalso();
    sessao = SessaoApi()..iniciar(token: 't', usuarioId: 'u', sessaoId: 's');
  });

  test('envia com o token e já guarda o link para exibir', () async {
    final repo = ArquivoRepositoryApi(servidor.cliente(sessao: sessao));
    final a = await repo.enviar(
      bytes: _png,
      nome: 'fachada.png',
      categoria: CategoriaArquivo.foto,
    );
    expect(servidor.ultimoToken, 'Bearer t');
    expect(servidor.arquivos[a.id], {
      'nome': 'fachada.png',
      'categoria': 'foto',
    });
    expect(a.referencia, 'arquivo:${a.id}');

    final link = await repo.endereco(a.referencia);
    expect(link!.toString(), startsWith('http://servidor/api/v1/arquivos/'));
    expect(servidor.requisicoes, hasLength(1)); // link veio no envio
  });

  test('links pedidos juntos vão numa requisição só', () async {
    final api = servidor.cliente(sessao: sessao);
    final enviados = [
      for (final n in ['a.png', 'b.png'])
        await ArquivoRepositoryApi(
          api,
        ).enviar(bytes: _png, nome: n, categoria: CategoriaArquivo.foto),
    ];
    servidor.requisicoes.clear();

    final repo = ArquivoRepositoryApi(api); // sem cache
    final links = await Future.wait([
      for (final e in enviados) repo.endereco(e.referencia),
      repo.endereco('arquivo:00000000-0000-4000-8000-999999999999'),
      repo.endereco('https://exemplo.com/foto.jpg'),
    ]);
    expect(servidor.requisicoes, ['POST /api/v1/arquivos/links']);
    expect(links[0]!.path, endsWith('${enviados[0].id}/conteudo'));
    expect(links[2], isNull); // apagado no servidor
    expect(links[3].toString(), 'https://exemplo.com/foto.jpg');

    await repo.endereco(enviados[1].referencia);
    expect(servidor.requisicoes, hasLength(1)); // reaproveitado
  });

  test('formato e tamanho conferidos antes de enviar', () async {
    final repo = ArquivoRepositoryApi(servidor.cliente(sessao: sessao));
    await expectLater(
      repo.enviar(
        bytes: _png,
        nome: 'virus.exe',
        categoria: CategoriaArquivo.arquivo,
      ),
      throwsA(
        isA<DomainException>().having(
          (e) => e.mensagem,
          'mensagem',
          startsWith('Formato não aceito para arquivos'),
        ),
      ),
    );
    expect(
      () => CategoriaArquivo.video.validar('tour.mp4', 301 * 1024 * 1024),
      throwsA(isA<DomainException>()),
    );
    expect(servidor.requisicoes, isEmpty);
  });

  test('anexo enviado: título do nome do arquivo; link vira arquivo', () async {
    final enviar = EnviarAnexo(ArquivoRepositoryMemoria());
    final foto = await enviar(AnexoTipo.foto, _escolhido('Sala ampla.png'));
    expect((foto.tipo, foto.titulo), (AnexoTipo.foto, 'Sala ampla'));
    expect(foto.url, startsWith(prefixoArquivo));

    final doc = await enviar(
      AnexoTipo.link,
      _escolhido('matricula.pdf'),
      titulo: 'Matrícula',
    );
    expect((doc.tipo, doc.titulo), (AnexoTipo.arquivo, 'Matrícula'));

    await expectLater(
      enviar(AnexoTipo.foto, _escolhido('grande.png', tamanho: 16 << 20)),
      throwsA(isA<DomainException>()),
    );
  });
}
