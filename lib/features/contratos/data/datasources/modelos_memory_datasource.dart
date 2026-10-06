import '../../../../core/data/memory_collection.dart';
import '../../domain/entities/modelo_contrato.dart';
import 'catalogo_modelos_prontos.dart';

/// Meus modelos em memória. Começa com um modelo de locação e um de venda
/// (cópias editáveis dos modelos prontos), usados na impressão dos contratos.
class ModelosMemoryDataSource {
  ModelosMemoryDataSource() {
    for (final id in [idProntoLocacaoResidencial, idProntoCompraVenda]) {
      final p = catalogoModelosProntos.firstWhere((m) => m.id == id);
      modelos.upsert(
        p.comoRascunho().copyWith(
          id: id == idProntoLocacaoResidencial
              ? 'padrao-locacao'
              : 'padrao-venda',
          nome: '${p.nome} (padrão)',
          atualizadoEm: DateTime(2026),
        ),
      );
    }
  }

  final modelos = MemoryCollection<ModeloContrato>((e) => e.id);
}
