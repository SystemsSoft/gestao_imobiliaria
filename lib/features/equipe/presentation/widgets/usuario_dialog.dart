import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/id.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/equipe_enums.dart';
import '../../domain/entities/permissoes.dart';
import '../../domain/entities/usuario_sistema.dart';

/// Cria ou edita um usuário. Retorna o usuário preenchido ou null.
Future<UsuarioSistema?> mostrarUsuarioDialog(
  BuildContext context, {
  UsuarioSistema? usuario,
}) => showDialog(
  context: context,
  builder: (_) => _UsuarioDialog(usuario: usuario),
);

class _UsuarioDialog extends StatefulWidget {
  const _UsuarioDialog({this.usuario});

  final UsuarioSistema? usuario;

  @override
  State<_UsuarioDialog> createState() => _UsuarioDialogState();
}

class _UsuarioDialogState extends State<_UsuarioDialog> {
  UsuarioSistema? get _u => widget.usuario;
  late final _nome = TextEditingController(text: _u?.nome);
  late final _email = TextEditingController(text: _u?.email);
  late final _telefone = TextEditingController(text: _u?.telefone);
  late final _creci = TextEditingController(text: _u?.creci);
  late PerfilAcesso _perfil = _u?.perfil ?? PerfilAcesso.corretor;
  late bool _atendeFila = _u?.atendeNaFila ?? true;
  late bool _ativo = _u?.ativo ?? true;

  @override
  void dispose() {
    for (final c in [_nome, _email, _telefone, _creci]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: Text(_u == null ? 'Novo usuário' : 'Editar usuário'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              AppTextField(
                label: 'Nome completo *',
                controller: _nome,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'E-mail (login) *',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              FieldRow(
                children: [
                  AppTextField(
                    label: 'Telefone',
                    controller: _telefone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [phoneFormatter],
                  ),
                  AppTextField(label: 'CRECI', controller: _creci),
                ],
              ),
              const SizedBox(height: 12),
              AppDropdown<PerfilAcesso>(
                label: 'Perfil de acesso',
                value: _perfil,
                items: PerfilAcesso.values,
                labelOf: (p) => '${p.label} • ${p.descricao}',
                onChanged: (v) => setState(() {
                  _perfil = v ?? _perfil;
                  if (_u == null) {
                    _atendeFila = _perfil == PerfilAcesso.corretor;
                  }
                }),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _u != null && _perfil != _u!.perfil
                      ? 'Ao trocar o perfil, as permissões padrão dele serão aplicadas.'
                      : 'As permissões podem ser ajustadas depois, na aba Permissões.',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
              AppSwitch(
                label: 'Atende na fila de corretores',
                value: _atendeFila,
                onChanged: (v) => setState(() => _atendeFila = v),
              ),
              if (_u != null)
                AppSwitch(
                  label: 'Usuário ativo',
                  value: _ativo,
                  onChanged: (v) => setState(() => _ativo = v),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.navyDark,
          ),
          onPressed: () {
            final mudouPerfil = _u == null || _perfil != _u!.perfil;
            Navigator.pop(
              context,
              UsuarioSistema(
                id: _u?.id ?? gerarId(),
                nome: _nome.text.trim(),
                email: _email.text.trim(),
                perfil: _perfil,
                permissoes: mudouPerfil
                    ? Permissoes.perfil(_perfil)
                    : _u!.permissoes,
                criadoEm: _u?.criadoEm ?? DateTime.now(),
                ativo: _ativo,
                telefone: _telefone.text,
                creci: _creci.text.trim(),
                atendeNaFila: _atendeFila,
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
