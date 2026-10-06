var _seq = 0;

/// Identificador único local (será substituído pelo id do backend).
String gerarId() => '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';
