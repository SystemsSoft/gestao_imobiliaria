import '../../../../core/api/json.dart';
import '../../domain/entities/manutencao.dart';

Map<String, Object?> manutencaoParaJson(Manutencao m) => {
  'contexto': m.contexto.name,
  'imovelId': m.imovelId,
  'tipo': m.tipo.name,
  'tipoOutro': m.tipoOutro,
  'descricao': m.descricao,
  'status': m.status.name,
  'dataPrevista': escreverData(m.dataPrevista),
  'diario': [
    for (final r in m.diario)
      {
        'id': r.id,
        'data': escreverData(r.data),
        'profissional': r.profissional,
        'servico': r.servico,
        'material': r.material,
        'valorMaterial': r.valorMaterial,
        'valorMaoDeObra': r.valorMaoDeObra,
        'valorTaxa': r.valorTaxa,
      },
  ],
};

Manutencao manutencaoDeJson(Map<String, dynamic> j) => Manutencao(
  id: j['id'] as String,
  contexto: lerEnum(
    ContextoManutencao.values,
    j['contexto'],
    ContextoManutencao.locacao,
  ),
  imovelId: lerTexto(j['imovelId']),
  tipo: lerEnum(TipoManutencao.values, j['tipo'], TipoManutencao.outros),
  tipoOutro: lerTexto(j['tipoOutro']),
  descricao: lerTexto(j['descricao']),
  status: lerEnum(
    StatusManutencao.values,
    j['status'],
    StatusManutencao.pendente,
  ),
  dataPrevista: lerData(j['dataPrevista']),
  criadaEm: lerData(j['criadoEm']) ?? DateTime.now(),
  diario: [
    for (final r in (j['diario'] as List?) ?? const [])
      RegistroDiario(
        id: r['id'] as String,
        data: lerData(r['data'])!,
        profissional: lerTexto(r['profissional']),
        servico: lerTexto(r['servico']),
        material: lerTexto(r['material']),
        valorMaterial: lerDouble(r['valorMaterial']) ?? 0,
        valorMaoDeObra: lerDouble(r['valorMaoDeObra']) ?? 0,
        valorTaxa: lerDouble(r['valorTaxa']) ?? 0,
      ),
  ],
);
