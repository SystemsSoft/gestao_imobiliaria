import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/id.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/equipe_enums.dart';
import '../../domain/entities/permissoes.dart';
import '../../domain/entities/usuario_sistema.dart';

/// Cria ou edita um usuário. Retorna o usuário preenchido (e a senha
/// digitada, vazia = manter) ou null.
Future<({UsuarioSistema usuario, String senha})?> mostrarUsuarioDialog(
  BuildContext context, {
  UsuarioSistema? usuario,
  bool comLogin = false,
}) => showDialog(
  context: context,
  builder: (_) => _UsuarioDialog(usuario: usuario, comLogin: comLogin),
);

class _UsuarioDialog extends StatefulWidget {
  const _UsuarioDialog({this.usuario, this.comLogin = false});

  final UsuarioSistema? usuario;

  /// Com o servidor, o usuário entra com e-mail e senha.
  final bool comLogin;

  @override
  State<_UsuarioDialog> createState() => _UsuarioDialogState();
}

class _UsuarioDialogState extends State<_UsuarioDialog> {
  UsuarioSistema? get _u => widget.usuario;
  late final _nome = TextEditingController(text: _u?.nome);
  late final _login = TextEditingController(text: _u?.login);
  late final _email = TextEditingController(text: _u?.email);
  late final _telefone = TextEditingController(text: _u?.telefone);
  late final _creci = TextEditingController(text: _u?.creci);
  final _senha = TextEditingController();
  bool _senhaOculta = true;
  late PerfilAcesso _perfil = _u?.perfil ?? PerfilAcesso.corretor;
  late bool _atendeFila = _u?.atendeNaFila ?? true;
  late bool _ativo = _u?.ativo ?? true;

  @override
  void dispose() {
    for (final c in [_nome, _login, _email, _telefone, _creci, _senha]) {
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
              FieldRow(
                children: [
                  AppTextField(
                    label: 'Usuário (login) *',
                    hint: 'Ex.: Marcelo',
                    controller: _login,
                  ),
                  AppTextField(
                    label: 'E-mail (opcional)',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              if (widget.comLogin) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _senha,
                  obscureText: _senhaOculta,
                  decoration: InputDecoration(
                    labelText: _u == null
                        ? 'Senha de acesso * (mín. 8 caracteres)'
                        : 'Nova senha (em branco = manter a atual)',
                    suffixIcon: IconButton(
                      tooltip: _senhaOculta ? 'Mostrar' : 'Ocultar',
                      icon: Icon(
                        _senhaOculta ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _senhaOculta = !_senhaOculta),
                    ),
                  ),
                ),
              ],
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
            Navigator.pop(context, (
              usuario: UsuarioSistema(
                id: _u?.id ?? gerarId(),
                nome: _nome.text.trim(),
                login: aparar(_login.text),
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
              senha: aparar(_senha.text),
            ));
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
