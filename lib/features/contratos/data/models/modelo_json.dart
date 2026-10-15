import '../../../../core/api/json.dart';
import '../../domain/entities/modelo_contrato.dart';
import '../../domain/entities/parametro_modelo.dart';

Map<String, Object?> modeloParaJson(ModeloContrato m) => {
  'nome': m.nome,
  'tipo': m.tipo.name,
  'texto': m.texto,
  'descricao': m.descricao,
  'parametros': [
    for (final p in m.parametros)
      {
        'chave': p.chave,
        'rotulo': p.rotulo,
        'tipo': p.tipo.name,
        'valorPadrao': p.valorPadrao,
        'descricao': p.descricao,
      },
  ],
  'baseId': m.baseId,
};

ModeloContrato modeloDeJson(Map<String, dynamic> j) => ModeloContrato(
  id: j['id'] as String,
  nome: lerTexto(j['nome']),
  tipo: lerEnum(TipoModelo.values, j['tipo'], TipoModelo.outros),
  texto: lerTexto(j['texto']),
  descricao: lerTexto(j['descricao']),
  parametros: [
    for (final p in (j['parametros'] as List?) ?? const [])
      ParametroModelo(
        chave: lerTexto(p['chave']),
        rotulo: lerTexto(p['rotulo']),
        tipo: lerEnum(TipoParametro.values, p['tipo'], TipoParametro.texto),
        valorPadrao: lerTexto(p['valorPadrao']),
        descricao: lerTexto(p['descricao']),
      ),
  ],
  baseId: j['baseId'] as String?,
  atualizadoEm: lerData(j['atualizadoEm']),
);
