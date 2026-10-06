import 'package:flutter/material.dart';

import '../../data/crm_store.dart';
import '../../models/catalog.dart';
import '../../models/contato.dart';
import '../../models/enums.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/form_widgets.dart';

class ContatoFormScreen extends StatefulWidget {
  const ContatoFormScreen({super.key, this.contato});

  final Contato? contato;

  @override
  State<ContatoFormScreen> createState() => _ContatoFormScreenState();
}

class _ContatoFormScreenState extends State<ContatoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _store = CrmStore.instance;

  late final String _id;
  late final DateTime _criadoEm;

  // Dados pessoais
  late TipoPessoa _tipoPessoa = widget.contato?.tipoPessoa ?? TipoPessoa.fisica;
  late Set<PapelContato> _papeis = {
    ...(widget.contato?.papeis ?? {PapelContato.lead}),
  };
  late final _nome = TextEditingController(text: widget.contato?.nome);
  late final _documento = TextEditingController(
    text: widget.contato?.documento,
  );
  late final _rg = TextEditingController(text: widget.contato?.rg);
  late DateTime? _dataNascimento = widget.contato?.dataNascimento;
  late String? _estadoCivil = widget.contato?.estadoCivil;
  late final _profissao = TextEditingController(
    text: widget.contato?.profissao,
  );
  late final _nacionalidade = TextEditingController(
    text: widget.contato?.nacionalidade ?? 'Brasileira',
  );

  // Contato
  late final _telefone = TextEditingController(text: widget.contato?.telefone);
  late final _celular = TextEditingController(text: widget.contato?.celular);
  late final _email = TextEditingController(text: widget.contato?.email);
  late bool _aceitaContato = widget.contato?.aceitaContato ?? true;

  // Endereço
  late final _cep = TextEditingController(text: widget.contato?.cep);
  late final _logradouro = TextEditingController(
    text: widget.contato?.logradouro,
  );
  late final _numero = TextEditingController(text: widget.contato?.numero);
  late final _complemento = TextEditingController(
    text: widget.contato?.complemento,
  );
  late final _bairro = TextEditingController(text: widget.contato?.bairro);
  late final _cidade = TextEditingController(text: widget.contato?.cidade);
  late String? _uf = (widget.contato?.uf.isEmpty ?? true)
      ? null
      : widget.contato!.uf;

  // CRM
  late OrigemContato _origem = widget.contato?.origem ?? OrigemContato.site;
  late EtapaFunil _etapa = widget.contato?.etapa ?? EtapaFunil.novo;
  late final _corretor = TextEditingController(
    text: widget.contato?.corretorResponsavel,
  );
  late final _renda = TextEditingController(
    text: moneyToText(widget.contato?.rendaMensal),
  );
  late final _observacoes = TextEditingController(
    text: widget.contato?.observacoes,
  );

  // Dados bancários
  late final _banco = TextEditingController(text: widget.contato?.banco);
  late final _agencia = TextEditingController(text: widget.contato?.agencia);
  late final _conta = TextEditingController(text: widget.contato?.conta);
  late final _pix = TextEditingController(text: widget.contato?.pix);

  // Perfil de interesse
  late bool _temPerfil = widget.contato?.perfil != null;
  late Finalidade _pFinalidade =
      widget.contato?.perfil?.finalidade ?? Finalidade.venda;
  late Set<TipoImovel> _pTipos = {...(widget.contato?.perfil?.tipos ?? {})};
  late final _pCidade = TextEditingController(
    text: widget.contato?.perfil?.cidade,
  );
  late final _pBairros = TextEditingController(
    text: widget.contato?.perfil?.bairros,
  );
  late final _pValorMin = TextEditingController(
    text: moneyToText(widget.contato?.perfil?.valorMin),
  );
  late final _pValorMax = TextEditingController(
    text: moneyToText(widget.contato?.perfil?.valorMax),
  );
  late final _pQuartos = TextEditingController(
    text: intToText(widget.contato?.perfil?.quartosMin),
  );
  late final _pSuites = TextEditingController(
    text: intToText(widget.contato?.perfil?.suitesMin),
  );
  late final _pVagas = TextEditingController(
    text: intToText(widget.contato?.perfil?.vagasMin),
  );
  late final _pArea = TextEditingController(
    text: decimalToText(widget.contato?.perfil?.areaMin),
  );
  late Set<String> _pComodidades = {
    ...(widget.contato?.perfil?.comodidades ?? {}),
  };
  late final _pObs = TextEditingController(
    text: widget.contato?.perfil?.observacoes,
  );

  @override
  void initState() {
    super.initState();
    _id = widget.contato?.id ?? _store.novoId();
    _criadoEm = widget.contato?.criadoEm ?? DateTime.now();
  }

  @override
  void dispose() {
    for (final c in [
      _nome,
      _documento,
      _rg,
      _profissao,
      _nacionalidade,
      _telefone,
      _celular,
      _email,
      _cep,
      _logradouro,
      _numero,
      _complemento,
      _bairro,
      _cidade,
      _corretor,
      _renda,
      _observacoes,
      _banco,
      _agencia,
      _conta,
      _pix,
      _pCidade,
      _pBairros,
      _pValorMin,
      _pValorMax,
      _pQuartos,
      _pSuites,
      _pVagas,
      _pArea,
      _pObs,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrija os campos destacados.')),
      );
      return;
    }
    final pf = _tipoPessoa == TipoPessoa.fisica;
    _store.salvarContato(
      Contato(
        id: _id,
        criadoEm: _criadoEm,
        nome: _nome.text.trim(),
        tipoPessoa: _tipoPessoa,
        papeis: _papeis,
        documento: _documento.text,
        rg: pf ? _rg.text.trim() : '',
        dataNascimento: _dataNascimento,
        estadoCivil: pf ? _estadoCivil : null,
        profissao: pf ? _profissao.text.trim() : '',
        nacionalidade: pf ? _nacionalidade.text.trim() : '',
        telefone: _telefone.text,
        celular: _celular.text,
        email: _email.text.trim(),
        aceitaContato: _aceitaContato,
        cep: _cep.text,
        logradouro: _logradouro.text.trim(),
        numero: _numero.text.trim(),
        complemento: _complemento.text.trim(),
        bairro: _bairro.text.trim(),
        cidade: _cidade.text.trim(),
        uf: _uf ?? '',
        origem: _origem,
        etapa: _etapa,
        corretorResponsavel: _corretor.text.trim(),
        rendaMensal: parseMoney(_renda.text),
        observacoes: _observacoes.text.trim(),
        banco: _banco.text.trim(),
        agencia: _agencia.text.trim(),
        conta: _conta.text.trim(),
        pix: _pix.text.trim(),
        perfil: _temPerfil
            ? PerfilInteresse(
                finalidade: _pFinalidade,
                tipos: _pTipos,
                cidade: _pCidade.text.trim(),
                bairros: _pBairros.text.trim(),
                valorMin: parseMoney(_pValorMin.text),
                valorMax: parseMoney(_pValorMax.text),
                quartosMin: parseInt(_pQuartos.text) ?? 0,
                suitesMin: parseInt(_pSuites.text) ?? 0,
                vagasMin: parseInt(_pVagas.text) ?? 0,
                areaMin: parseDecimal(_pArea.text),
                comodidades: _pComodidades,
                observacoes: _pObs.text.trim(),
              )
            : null,
      ),
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Contato salvo.')));
  }

  @override
  Widget build(BuildContext context) {
    final pf = _tipoPessoa == TipoPessoa.fisica;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.gold,
        title: Text(widget.contato == null ? 'Novo contato' : 'Editar contato'),
        actions: [
          TextButton.icon(
            onPressed: _salvar,
            icon: const Icon(Icons.check),
            label: const Text('SALVAR'),
            style: TextButton.styleFrom(foregroundColor: AppColors.gold),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FormSection(
                  title: 'Dados do contato',
                  icon: Icons.person_outline,
                  children: [
                    SegmentedButton<TipoPessoa>(
                      segments: [
                        for (final t in TipoPessoa.values)
                          ButtonSegment(value: t, label: Text(t.label)),
                      ],
                      selected: {_tipoPessoa},
                      onSelectionChanged: (s) =>
                          setState(() => _tipoPessoa = s.first),
                    ),
                    ChipMultiSelect<PapelContato>(
                      title: 'Perfil do contato',
                      options: PapelContato.values,
                      selected: _papeis,
                      labelOf: (e) => e.label,
                      onChanged: (v) => setState(() => _papeis = v),
                    ),
                    AppTextField(
                      label: pf
                          ? 'Nome completo *'
                          : 'Razão social / Nome fantasia *',
                      controller: _nome,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o nome'
                          : null,
                    ),
                    FieldRow(
                      children: [
                        AppTextField(
                          label: pf ? 'CPF' : 'CNPJ',
                          controller: _documento,
                          keyboardType: TextInputType.number,
                          inputFormatters: [cpfCnpjFormatter],
                        ),
                        if (pf) AppTextField(label: 'RG', controller: _rg),
                        DateField(
                          label: pf ? 'Data de nascimento' : 'Data de fundação',
                          value: _dataNascimento,
                          onChanged: (d) => setState(() => _dataNascimento = d),
                        ),
                      ],
                    ),
                    if (pf)
                      FieldRow(
                        children: [
                          AppDropdown<String>(
                            label: 'Estado civil',
                            value: _estadoCivil,
                            items: estadosCivis,
                            onChanged: (v) => setState(() => _estadoCivil = v),
                          ),
                          AppTextField(
                            label: 'Profissão',
                            controller: _profissao,
                          ),
                          AppTextField(
                            label: 'Nacionalidade',
                            controller: _nacionalidade,
                          ),
                        ],
                      ),
                  ],
                ),
                FormSection(
                  title: 'Telefones e e-mail',
                  icon: Icons.phone_outlined,
                  children: [
                    FieldRow(
                      children: [
                        AppTextField(
                          label: 'Telefone',
                          controller: _telefone,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [phoneFormatter],
                        ),
                        AppTextField(
                          label: 'Celular / WhatsApp',
                          controller: _celular,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [phoneFormatter],
                        ),
                      ],
                    ),
                    AppTextField(
                      label: 'E-mail',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return null;
                        return (t.contains('@') && t.contains('.'))
                            ? null
                            : 'E-mail inválido';
                      },
                    ),
                    AppSwitch(
                      label:
                          'Autoriza receber contato (e-mail, WhatsApp, ligações)',
                      value: _aceitaContato,
                      onChanged: (v) => setState(() => _aceitaContato = v),
                    ),
                  ],
                ),
                FormSection(
                  title: 'Endereço',
                  icon: Icons.home_outlined,
                  children: [
                    FieldRow(
                      flex: const [1, 3, 1],
                      children: [
                        AppTextField(
                          label: 'CEP',
                          controller: _cep,
                          keyboardType: TextInputType.number,
                          inputFormatters: [cepFormatter],
                        ),
                        AppTextField(
                          label: 'Logradouro',
                          controller: _logradouro,
                        ),
                        AppTextField(label: 'Número', controller: _numero),
                      ],
                    ),
                    FieldRow(
                      children: [
                        AppTextField(
                          label: 'Complemento',
                          controller: _complemento,
                        ),
                        AppTextField(label: 'Bairro', controller: _bairro),
                      ],
                    ),
                    FieldRow(
                      flex: const [3, 1],
                      children: [
                        AppTextField(label: 'Cidade', controller: _cidade),
                        AppDropdown<String>(
                          label: 'UF',
                          value: _uf,
                          items: estadosBrasil,
                          onChanged: (v) => setState(() => _uf = v),
                        ),
                      ],
                    ),
                  ],
                ),
                FormSection(
                  title: 'CRM e atendimento',
                  icon: Icons.handshake_outlined,
                  children: [
                    FieldRow(
                      children: [
                        AppDropdown<OrigemContato>(
                          label: 'Origem do contato',
                          value: _origem,
                          items: OrigemContato.values,
                          labelOf: (e) => e.label,
                          onChanged: (v) =>
                              setState(() => _origem = v ?? _origem),
                        ),
                        AppDropdown<EtapaFunil>(
                          label: 'Etapa do funil',
                          value: _etapa,
                          items: EtapaFunil.values,
                          labelOf: (e) => e.label,
                          onChanged: (v) =>
                              setState(() => _etapa = v ?? _etapa),
                        ),
                      ],
                    ),
                    FieldRow(
                      children: [
                        AppTextField(
                          label: 'Corretor responsável',
                          controller: _corretor,
                        ),
                        AppTextField.money(
                          label: 'Renda mensal',
                          controller: _renda,
                        ),
                      ],
                    ),
                    AppTextField(
                      label: 'Observações',
                      controller: _observacoes,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
                if (_papeis.contains(PapelContato.proprietario))
                  FormSection(
                    title: 'Dados bancários (repasse ao proprietário)',
                    icon: Icons.account_balance_outlined,
                    children: [
                      FieldRow(
                        children: [
                          AppTextField(label: 'Banco', controller: _banco),
                          AppTextField(label: 'Agência', controller: _agencia),
                          AppTextField(label: 'Conta', controller: _conta),
                        ],
                      ),
                      AppTextField(label: 'Chave PIX', controller: _pix),
                    ],
                  ),
                FormSection(
                  title: 'Perfil de interesse',
                  icon: Icons.manage_search,
                  children: [
                    AppSwitch(
                      label:
                          'Este contato procura um imóvel (habilita o cruzamento de perfil)',
                      value: _temPerfil,
                      onChanged: (v) => setState(() => _temPerfil = v),
                    ),
                    if (_temPerfil) ...[
                      AppDropdown<Finalidade>(
                        label: 'Deseja',
                        value: _pFinalidade,
                        items: Finalidade.values,
                        labelOf: (e) => e.perfilLabel,
                        onChanged: (v) =>
                            setState(() => _pFinalidade = v ?? _pFinalidade),
                      ),
                      ChipMultiSelect<TipoImovel>(
                        title: 'Tipos de imóvel (vazio = qualquer)',
                        options: TipoImovel.values,
                        selected: _pTipos,
                        labelOf: (e) => e.label,
                        onChanged: (v) => setState(() => _pTipos = v),
                      ),
                      FieldRow(
                        children: [
                          AppTextField(label: 'Cidade', controller: _pCidade),
                          AppTextField(
                            label: 'Bairros',
                            hint: 'Separe por vírgula',
                            controller: _pBairros,
                          ),
                        ],
                      ),
                      FieldRow(
                        children: [
                          AppTextField.money(
                            label: 'Valor mínimo',
                            controller: _pValorMin,
                          ),
                          AppTextField.money(
                            label: 'Valor máximo',
                            controller: _pValorMax,
                          ),
                        ],
                      ),
                      FieldRow(
                        children: [
                          AppTextField.integer(
                            label: 'Quartos (mín.)',
                            controller: _pQuartos,
                          ),
                          AppTextField.integer(
                            label: 'Suítes (mín.)',
                            controller: _pSuites,
                          ),
                          AppTextField.integer(
                            label: 'Vagas (mín.)',
                            controller: _pVagas,
                          ),
                          AppTextField.decimal(
                            label: 'Área mín.',
                            controller: _pArea,
                            suffixText: 'm²',
                          ),
                        ],
                      ),
                      ChipMultiSelect<String>(
                        title: 'Comodidades desejadas',
                        options: comodidadesPadrao,
                        selected: _pComodidades,
                        onChanged: (v) => setState(() => _pComodidades = v),
                      ),
                      AppTextField(
                        label: 'Observações do perfil',
                        controller: _pObs,
                        maxLines: 2,
                      ),
                    ],
                  ],
                ),
                FilledButton.icon(
                  onPressed: _salvar,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navyDark,
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text(
                    'SALVAR CONTATO',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
