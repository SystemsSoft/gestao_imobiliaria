import 'dart:async';

import '../../../../core/config/empresa_info.dart';
import '../../../../core/data/memory_collection.dart';
import '../../domain/entities/atividade.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/comissao_equipe.dart';
import '../../domain/entities/equipe_enums.dart';
import '../../domain/entities/fila.dart';
import '../../domain/entities/permissoes.dart';
import '../../domain/entities/sessao.dart';
import '../../domain/entities/usuario_sistema.dart';

/// Equipe em memória, até existir um backend. Começa com o administrador
/// já conectado, para o sistema nunca ficar sem acesso.
class EquipeMemoryDataSource {
  EquipeMemoryDataSource() {
    final agora = DateTime.now();
    usuarios.upsert(
      UsuarioSistema(
        id: idAdministrador,
        nome: EmpresaInfo.nome,
        email: 'admin@imobiliaria.com.br',
        perfil: PerfilAcesso.administrador,
        permissoes: Permissoes.perfil(PerfilAcesso.administrador),
        criadoEm: agora,
      ),
    );
    sessoes.upsert(
      SessaoUsuario(
        id: 'sessao-admin',
        usuarioId: idAdministrador,
        inicio: agora,
        ultimaAtividade: agora,
        dispositivo: 'Navegador deste computador',
      ),
    );
    atividades.upsert(
      Atividade(
        id: 'login-admin',
        usuarioId: idAdministrador,
        tipo: TipoAtividade.login,
        descricao: 'Entrou no sistema',
        quando: agora,
      ),
    );
  }

  static const idAdministrador = 'admin';

  final usuarios = MemoryCollection<UsuarioSistema>((e) => e.id);
  final sessoes = MemoryCollection<SessaoUsuario>((e) => e.id);
  final atividades = MemoryCollection<Atividade>((e) => e.id);
  final atendimentos = MemoryCollection<Atendimento>((e) => e.id);
  final regras = MemoryCollection<RegraComissao>((e) => e.usuarioId);
  final lancamentos = MemoryCollection<LancamentoComissao>((e) => e.id);
  final mensagens = MemoryCollection<Mensagem>((e) => e.id);
  final configuracao = MemoryCollection<ConfiguracaoSeguranca>((_) => 'config');

  // Fila: lista ordenada com stream próprio.
  List<ItemFila> fila = [];
  final filaChanges = StreamController<List<ItemFila>>.broadcast();

  // Usuário atual.
  String? usuarioAtualId = idAdministrador;
  final usuarioAtualChanges = StreamController<String?>.broadcast();
}
