import '../entities/campos_modelo.dart';
import '../entities/modelo_contrato.dart';
import '../entities/parametro_modelo.dart';

final _marcador = RegExp(r'\{\{(\w+)\}\}');

class AnaliseModelo {
  const AnaliseModelo({
    required this.usados,
    required this.desconhecidos,
    required this.parametrosNaoUsados,
    required this.palavras,
    required this.clausulas,
  });

  /// Chaves distintas usadas no texto.
  final Set<String> usados;

  /// Campos que não existem no sistema nem nos parâmetros do modelo.
  final Set<String> desconhecidos;

  /// Parâmetros criados mas não usados no texto.
  final List<ParametroModelo> parametrosNaoUsados;
  final int palavras;
  final int clausulas;

  bool get valido => desconhecidos.isEmpty;
}

/// Ferramentas do editor de modelos: análise, visualização e utilidades.
class EditorModeloService {
  const EditorModeloService();

  AnaliseModelo analisar(
    String texto,
    TipoModelo tipo,
    List<ParametroModelo> parametros,
  ) {
    final validos = {
      ...camposDoModelo(tipo).keys,
      ...parametros.map((p) => p.chave),
    };
    final usados = _marcador.allMatches(texto).map((m) => m.group(1)!).toSet();
    return AnaliseModelo(
      usados: usados,
      desconhecidos: usados.difference(validos),
      parametrosNaoUsados: parametros
          .where((p) => !usados.contains(p.chave))
          .toList(),
      palavras: texto.trim().isEmpty
          ? 0
          : texto.trim().split(RegExp(r'\s+')).length,
      clausulas: RegExp(r'CLÁUSULA\s+\d+ª').allMatches(texto).length,
    );
  }

  /// Texto com os campos trocados por valores de exemplo (campos do sistema)
  /// e pelo valor padrão (parâmetros). Campos desconhecidos ficam como estão.
  String previa(
    String texto,
    TipoModelo tipo,
    List<ParametroModelo> parametros,
  ) {
    final valores = {
      for (final c in camposModelo(tipo)) c.chave: c.exemplo,
      for (final p in parametros)
        p.chave: p.valorPadrao.isEmpty ? '[${p.rotulo}]' : p.valorPadrao,
    };
    return texto.replaceAllMapped(
      _marcador,
      (m) => valores[m.group(1)] ?? m.group(0)!,
    );
  }

  /// Renumera "CLÁUSULA 1ª", "CLÁUSULA 2ª"... na ordem em que aparecem.
  String renumerarClausulas(String texto) {
    var n = 0;
    return texto.replaceAllMapped(
      RegExp(r'CLÁUSULA\s+(\d+|N)ª'),
      (_) => 'CLÁUSULA ${++n}ª',
    );
  }

  /// Próximo número de cláusula a usar.
  int proximaClausula(String texto) =>
      RegExp(r'CLÁUSULA\s+\d+ª').allMatches(texto).length + 1;

  /// Cláusula da biblioteca com o número já aplicado.
  String clausulaNumerada(String modelo, String textoAtual) => modelo
      .replaceAll('CLÁUSULA Nª', 'CLÁUSULA ${proximaClausula(textoAtual)}ª');

  /// Converte um rótulo em chave válida: "Foro da cidade" → "foro_da_cidade".
  String chaveDoRotulo(String rotulo) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const para = 'aaaaaeeeeiiiiooooouuuucn';
    var s = rotulo.toLowerCase().trim();
    for (var i = 0; i < de.length; i++) {
      s = s.replaceAll(de[i], para[i]);
    }
    s = s
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (s.isEmpty) return '';
    return RegExp(r'^[a-z]').hasMatch(s) ? s : 'p_$s';
  }

  /// Mensagem de erro se o parâmetro não puder ser usado, ou null.
  String? validarParametro(
    ParametroModelo p,
    TipoModelo tipo,
    List<ParametroModelo> outros,
  ) {
    if (p.rotulo.trim().isEmpty) return 'Informe o nome do campo.';
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(p.chave)) {
      return 'A chave deve começar com letra minúscula e usar só letras, números e "_".';
    }
    if (camposDoModelo(tipo).containsKey(p.chave)) {
      return 'A chave "${p.chave}" já é um campo do sistema.';
    }
    if (outros.any((o) => o.chave == p.chave)) {
      return 'Já existe um parâmetro com a chave "${p.chave}".';
    }
    return null;
  }
}
