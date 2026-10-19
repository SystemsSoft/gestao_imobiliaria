import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/configuracao_site.dart';
import '../viewmodels/site_viewmodels.dart';

/// Textos, contatos, funcionalidades e atendimento do site público.
class ConfiguracaoSiteTab extends StatefulWidget {
  const ConfiguracaoSiteTab({super.key});

  @override
  State<ConfiguracaoSiteTab> createState() => _ConfiguracaoSiteTabState();
}

class _ConfiguracaoSiteTabState extends State<ConfiguracaoSiteTab> {
  final _vm = sl<ConfiguracaoSiteViewModel>();
  final _t = {
    for (final k in [
      'titulo',
      'subtitulo',
      'textoSobre',
      'chamadaAnuncie',
      'mensagemObrigado',
      'whatsapp',
      'telefone',
      'email',
      'endereco',
      'horario',
      'instagram',
      'facebook',
      'metaDescricao',
    ])
      k: TextEditingController(),
  };
  ConfiguracaoSite? _c;

  @override
  void dispose() {
    for (final c in _t.values) {
      c.dispose();
    }
    _vm.dispose();
    super.dispose();
  }

  void _preencher(ConfiguracaoSite c) {
    _c = c;
    final valores = {
      'titulo': c.titulo,
      'subtitulo': c.subtitulo,
      'textoSobre': c.textoSobre,
      'chamadaAnuncie': c.chamadaAnuncie,
      'mensagemObrigado': c.mensagemObrigado,
      'whatsapp': c.whatsapp,
      'telefone': c.telefone,
      'email': c.email,
      'endereco': c.endereco,
      'horario': c.horario,
      'instagram': c.instagram,
      'facebook': c.facebook,
      'metaDescricao': c.metaDescricao,
    };
    for (final e in valores.entries) {
      _t[e.key]!.text = e.value;
    }
  }

  String _v(String k) => _t[k]!.text.trim();

  ConfiguracaoSite get _editado => _c!.copyWith(
    titulo: _v('titulo'),
    subtitulo: _v('subtitulo'),
    textoSobre: _v('textoSobre'),
    chamadaAnuncie: _v('chamadaAnuncie'),
    mensagemObrigado: _v('mensagemObrigado'),
    whatsapp: _v('whatsapp'),
    telefone: _v('telefone'),
    email: _v('email'),
    endereco: _v('endereco'),
    horario: _v('horario'),
    instagram: _v('instagram'),
    facebook: _v('facebook'),
    metaDescricao: _v('metaDescricao'),
  );

  Future<void> _salvar() async {
    final ok = await _vm.salvar(_editado);
    if (!mounted) return;
    if (ok) _preencher(_vm.config);
    mostrarMensagem(
      context,
      ok ? 'Site atualizado.' : (_vm.erro ?? 'Não foi possível salvar.'),
    );
  }

  void _mudar(ConfiguracaoSite Function(ConfiguracaoSite) f) =>
      setState(() => _c = f(_editado));

  Widget _chave(String rotulo, bool valor, ConfiguracaoSite Function(bool) f) =>
      AppSwitch(
        label: rotulo,
        value: valor,
        onChanged: (v) => _mudar((_) => f(v)),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        if (!_vm.carregado) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_c == null) _preencher(_vm.config);
        final c = _c!;
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: goldFab(
            icon: Icons.save_outlined,
            label: 'Salvar site',
            onPressed: _salvar,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  _situacao(c),
                  FormSection(
                    title: 'Conteúdo da página',
                    icon: Icons.article_outlined,
                    children: [
                      AppTextField(
                        label: 'Título da página inicial',
                        controller: _t['titulo'],
                      ),
                      AppTextField(
                        label: 'Subtítulo',
                        controller: _t['subtitulo'],
                        maxLines: 2,
                      ),
                      AppTextField(
                        label: 'Quem somos',
                        controller: _t['textoSobre'],
                        maxLines: 5,
                      ),
                      AppTextField(
                        label: 'Chamada "Anuncie seu imóvel"',
                        controller: _t['chamadaAnuncie'],
                        maxLines: 2,
                      ),
                      AppTextField(
                        label: 'Mensagem após o envio do formulário',
                        controller: _t['mensagemObrigado'],
                        maxLines: 2,
                      ),
                    ],
                  ),
                  FormSection(
                    title: 'Contatos e redes sociais',
                    icon: Icons.contact_phone_outlined,
                    children: [
                      const Text(
                        'Em branco, o site usa os dados da imobiliária '
                        '(Personalização).',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      FieldRow(
                        children: [
                          AppTextField(
                            label: 'WhatsApp',
                            hint: '(21) 99999-0000',
                            controller: _t['whatsapp'],
                            keyboardType: TextInputType.phone,
                          ),
                          AppTextField(
                            label: 'Telefone',
                            controller: _t['telefone'],
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                      FieldRow(
                        children: [
                          AppTextField(
                            label: 'E-mail',
                            controller: _t['email'],
                            keyboardType: TextInputType.emailAddress,
                          ),
                          AppTextField(
                            label: 'Horário de atendimento',
                            controller: _t['horario'],
                          ),
                        ],
                      ),
                      AppTextField(
                        label: 'Endereço',
                        controller: _t['endereco'],
                      ),
                      FieldRow(
                        children: [
                          AppTextField(
                            label: 'Instagram',
                            hint: 'https://instagram.com/...',
                            controller: _t['instagram'],
                            keyboardType: TextInputType.url,
                          ),
                          AppTextField(
                            label: 'Facebook',
                            hint: 'https://facebook.com/...',
                            controller: _t['facebook'],
                            keyboardType: TextInputType.url,
                          ),
                        ],
                      ),
                    ],
                  ),
                  FormSection(
                    title: 'Funcionalidades do site',
                    icon: Icons.tune,
                    children: [
                      _chave(
                        'Busca de imóveis na página inicial',
                        c.mostrarBusca,
                        (v) => c.copyWith(mostrarBusca: v),
                      ),
                      _chave(
                        'Imóveis em destaque',
                        c.mostrarDestaques,
                        (v) => c.copyWith(mostrarDestaques: v),
                      ),
                      _chave(
                        'Seção "Quem somos"',
                        c.mostrarSobre,
                        (v) => c.copyWith(mostrarSobre: v),
                      ),
                      _chave(
                        'Formulário de contato na página inicial',
                        c.mostrarContato,
                        (v) => c.copyWith(mostrarContato: v),
                      ),
                      _chave(
                        'Página "Anuncie seu imóvel" (captação)',
                        c.mostrarAnuncie,
                        (v) => c.copyWith(mostrarAnuncie: v),
                      ),
                      _chave(
                        'Agendamento de visita pelo site',
                        c.permitirAgendarVisita,
                        (v) => c.copyWith(permitirAgendarVisita: v),
                      ),
                      _chave(
                        'Botão flutuante do WhatsApp',
                        c.botaoWhatsapp,
                        (v) => c.copyWith(botaoWhatsapp: v),
                      ),
                      _chave(
                        'Mostrar valores (desligado: "Consulte")',
                        c.mostrarValores,
                        (v) => c.copyWith(mostrarValores: v),
                      ),
                      _chave(
                        'Área do inquilino (boletos, contrato, chamados)',
                        c.mostrarAreaInquilino,
                        (v) => c.copyWith(mostrarAreaInquilino: v),
                      ),
                      _chave(
                        'Área do proprietário (repasses e auditorias)',
                        c.mostrarAreaProprietario,
                        (v) => c.copyWith(mostrarAreaProprietario: v),
                      ),
                    ],
                  ),
                  FormSection(
                    title: 'Atendimento dos leads',
                    icon: Icons.support_agent,
                    children: [
                      const Text(
                        'Todo lead vira um contato no CRM (origem "Site"). '
                        'Escolha o que mais acontece quando ele chega:',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      _chave(
                        'Encaminhar ao próximo corretor da fila de atendimento',
                        c.distribuirNaFila,
                        (v) => c.copyWith(distribuirNaFila: v),
                      ),
                      _chave(
                        'Criar tarefa de retorno na Central de Relacionamento',
                        c.criarTarefa,
                        (v) => c.copyWith(criarTarefa: v),
                      ),
                    ],
                  ),
                  FormSection(
                    title: 'Google e redes (SEO)',
                    icon: Icons.travel_explore,
                    children: [
                      AppTextField(
                        label: 'Descrição para buscadores',
                        hint:
                            'Ex.: Imóveis à venda e para alugar em Niterói...',
                        controller: _t['metaDescricao'],
                        maxLines: 2,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _situacao(ConfiguracaoSite c) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: (c.noAr ? Colors.greenAccent : Colors.orangeAccent).withValues(
        alpha: 0.08,
      ),
      border: Border.all(
        color: (c.noAr ? Colors.greenAccent : Colors.orangeAccent).withValues(
          alpha: 0.4,
        ),
      ),
    ),
    child: Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              c.noAr ? Icons.public : Icons.public_off,
              color: c.noAr ? Colors.greenAccent : Colors.orangeAccent,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.noAr ? 'Site no ar' : 'Site em manutenção',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  _vm.enderecoSite,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: c.noAr,
              activeThumbColor: AppColors.gold,
              onChanged: (v) => _mudar((e) => e.copyWith(noAr: v)),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(_vm.enderecoSite),
                webOnlyWindowName: '_blank',
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Abrir site'),
            ),
          ],
        ),
      ],
    ),
  );
}
