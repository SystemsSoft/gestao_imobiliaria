import '../../../../core/data/memory_collection.dart';
import '../../domain/entities/modelo_contrato.dart';
import 'modelos_padrao.dart';

/// Modelos de contrato em memória, já com um modelo padrão de cada tipo.
class ModelosMemoryDataSource {
  ModelosMemoryDataSource() {
    modelos
      ..upsert(
        const ModeloContrato(
          id: 'padrao-locacao',
          nome: 'Locação residencial (padrão)',
          tipo: TipoModelo.locacao,
          texto: modeloLocacaoResidencial,
        ),
      )
      ..upsert(
        const ModeloContrato(
          id: 'padrao-venda',
          nome: 'Promessa de compra e venda (padrão)',
          tipo: TipoModelo.venda,
          texto: modeloCompraVenda,
        ),
      );
  }

  final modelos = MemoryCollection<ModeloContrato>((e) => e.id);
}
