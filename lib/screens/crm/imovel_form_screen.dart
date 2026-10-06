import 'package:flutter/material.dart';

import '../../data/crm_store.dart';
import '../../models/catalog.dart';
import '../../models/enums.dart';
import '../../models/imovel.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/form_widgets.dart';

class ImovelFormScreen extends StatefulWidget {
  const ImovelFormScreen({super.key, this.imovel});

  final Imovel? imovel;

  @override
  State<ImovelFormScreen> createState() => _ImovelFormScreenState();
}

class _ImovelFormScreenState extends State<ImovelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _store = CrmStore.instance;

  late final String _id;
  late final String _codigo;
  late final TextEditingController _codigoCtrl;

  // Identificação
  late final _titulo = TextEditingController(text: widget.imovel?.titulo);
  late Set<Finalidade> _finalidades = {
    ...(widget.imovel?.finalidades ?? {Finalidade.venda}),
  };
  late TipoImovel _tipo = widget.imovel?.tipo ?? TipoImovel.apartamento;
  late StatusImovel _status = widget.imovel?.status ?? StatusImovel.disponivel;
  late String? _proprietarioId = widget.imovel?.proprietarioId;

  // Localização
  late final _cep = TextEditingController(text: widget.imovel?.cep);
  late final _logradouro = TextEditingController(
    text: widget.imovel?.logradouro,
  );
  late final _numero = TextEditingController(text: widget.imovel?.numero);
  late final _complemento = TextEditingController(
    text: widget.imovel?.complemento,
  );
  late final _bairro = TextEditingController(text: widget.imovel?.bairro);
  late final _cidade = TextEditingController(text: widget.imovel?.cidade);
  late String? _uf = (widget.imovel?.uf.isEmpty ?? true)
      ? null
      : widget.imovel!.uf;
  late final _condominioNome = TextEditingController(
    text: widget.imovel?.condominioNome,
  );
  late final _referencia = TextEditingController(
    text: widget.imovel?.referencia,
  );
  late bool _exibirEndereco = widget.imovel?.exibirEnderecoSite ?? true;

  // Valores
  late final _valorVenda = TextEditingController(
    text: moneyToText(widget.imovel?.valorVenda),
  );
  late final _valorLocacao = TextEditingController(
    text: moneyToText(widget.imovel?.valorLocacao),
  );
  late final _valorTemporada = TextEditingController(
    text: moneyToText(widget.imovel?.valorTemporada),
  );
  late final _valorCondominio = TextEditingController(
    text: moneyToText(widget.imovel?.valorCondominio),
  );
  late final _valorIptu = TextEditingController(
    text: moneyToText(widget.imovel?.valorIptu),
  );
  late final _comissao = TextEditingController(
    text: decimalToText(widget.imovel?.comissao),
  );
  late bool _aceitaFinanciamento = widget.imovel?.aceitaFinanciamento ?? false;
  late bool _aceitaPermuta = widget.imovel?.aceitaPermuta ?? false;

  // Características
  late final _quartos = TextEditingController(
    text: intToText(widget.imovel?.quartos),
  );
  late final _suites = TextEditingController(
    text: intToText(widget.imovel?.suites),
  );
  late final _banheiros = TextEditingController(
    text: intToText(widget.imovel?.banheiros),
  );
  late final _vagas = TextEditingController(
    text: intToText(widget.imovel?.vagas),
  );
  late final _andar = TextEditingController(
    text: intToText(widget.imovel?.andar),
  );
  late final _ano = TextEditingController(
    text: intToText(widget.imovel?.anoConstrucao),
  );
  late final _areaUtil = TextEditingController(
    text: decimalToText(widget.imovel?.areaUtil),
  );
  late final _areaTotal = TextEditingController(
    text: decimalToText(widget.imovel?.areaTotal),
  );
  late final _areaTerreno = TextEditingController(
    text: decimalToText(widget.imovel?.areaTerreno),
  );
  late Mobiliado _mobiliado = widget.imovel?.mobiliado ?? Mobiliado.nao;

  // Comodidades e características personalizadas
  late Set<String> _comodidades = {...(widget.imovel?.comodidades ?? {})};
  late final List<CaracteristicaPersonalizada> _personalizadas = [
    ...(widget.imovel?.personalizadas ?? []),
  ];
  final _persNome = TextEditingController();
  final _persValor = TextEditingController();

  // Descrição
  late final _descricao = TextEditingController(text: widget.imovel?.descricao);
  late final _obsInternas = TextEditingController(
    text: widget.imovel?.observacoesInternas,
  );

  // Captação e dados legais
  late final _captador = TextEditingController(text: widget.imovel?.captador);
  late DateTime? _dataCaptacao = widget.imovel?.dataCaptacao;
  late final _matricula = TextEditingController(text: widget.imovel?.matricula);
  late final _inscricao = TextEditingController(
    text: widget.imovel?.inscricaoMunicipal,
  );
  late final _localChaves = TextEditingController(
    text: widget.imovel?.localChaves,
  );
  late bool _exclusividade = widget.imovel?.exclusividade ?? false;

  // Anexos
  late final List<Anexo> _anexos = [...(widget.imovel?.anexos ?? [])];
  AnexoTipo _anexoTipo = AnexoTipo.foto;
  final _anexoTitulo = TextEditingController();
  final _anexoUrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _id = widget.imovel?.id ?? _store.novoId();
    _codigo = widget.imovel?.codigo ?? _store.proximoCodigo();
    _codigoCtrl = TextEditingController(text: _codigo);
  }

  @override
  void dispose() {
    for (final c in [
      _codigoCtrl,
      _titulo,
      _cep,
      _logradouro,
      _numero,
      _complemento,
      _bairro,
      _cidade,
      _condominioNome,
      _referencia,
      _valorVenda,
      _valorLocacao,
      _valorTemporada,
      _valorCondominio,
      _valorIptu,
      _comissao,
      _quartos,
      _suites,
      _banheiros,
      _vagas,
      _andar,
      _ano,
      _areaUtil,
      _areaTotal,
      _areaTerreno,
      _persNome,
      _persValor,
      _descricao,
      _obsInternas,
      _captador,
      _matricula,
      _inscricao,
      _localChaves,
      _anexoTitulo,
      _anexoUrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPersonalizada() {
    final nome = _persNome.text.trim();
    if (nome.isEmpty) return;
    setState(() {
      _personalizadas.add(
        CaracteristicaPersonalizada(nome: nome, valor: _persValor.text.trim()),
      );
      _persNome.clear();
      _persValor.clear();
    });
  }

  void _addAnexo() {
    final url = _anexoUrl.text.trim();
    if (url.isEmpty) return;
    final titulo = _anexoTitulo.text.trim();
    setState(() {
      _anexos.add(
        Anexo(
          tipo: _anexoTipo,
          titulo: titulo.isEmpty ? _anexoTipo.label : titulo,
          url: url,
        ),
      );
      _anexoTitulo.clear();
      _anexoUrl.clear();
    });
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrija os campos destacados.')),
      );
      return;
    }
    if (_finalidades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos uma finalidade.')),
      );
      return;
    }
    _store.salvarImovel(
      Imovel(
        id: _id,
        codigo: _codigo,
        titulo: _titulo.text.trim(),
        finalidades: _finalidades,
        tipo: _tipo,
        status: _status,
        proprietarioId: _proprietarioId,
        cep: _cep.text,
        logradouro: _logradouro.text.trim(),
        numero: _numero.text.trim(),
        complemento: _complemento.text.trim(),
        bairro: _bairro.text.trim(),
        cidade: _cidade.text.trim(),
        uf: _uf ?? '',
        referencia: _referencia.text.trim(),
        condominioNome: _condominioNome.text.trim(),
        exibirEnderecoSite: _exibirEndereco,
        valorVenda: _finalidades.contains(Finalidade.venda)
            ? parseMoney(_valorVenda.text)
            : null,
        valorLocacao: _finalidades.contains(Finalidade.locacao)
            ? parseMoney(_valorLocacao.text)
            : null,
        valorTemporada: _finalidades.contains(Finalidade.temporada)
            ? parseMoney(_valorTemporada.text)
            : null,
        valorCondominio: parseMoney(_valorCondominio.text),
        valorIptu: parseMoney(_valorIptu.text),
        comissao: parseDecimal(_comissao.text),
        aceitaFinanciamento: _aceitaFinanciamento,
        aceitaPermuta: _aceitaPermuta,
        quartos: parseInt(_quartos.text) ?? 0,
        suites: parseInt(_suites.text) ?? 0,
        banheiros: parseInt(_banheiros.text) ?? 0,
        vagas: parseInt(_vagas.text) ?? 0,
        andar: parseInt(_andar.text),
        anoConstrucao: parseInt(_ano.text),
        areaUtil: parseDecimal(_areaUtil.text),
        areaTotal: parseDecimal(_areaTotal.text),
        areaTerreno: parseDecimal(_areaTerreno.text),
        mobiliado: _mobiliado,
        comodidades: _comodidades,
        personalizadas: _personalizadas,
        descricao: _descricao.text.trim(),
        observacoesInternas: _obsInternas.text.trim(),
        captador: _captador.text.trim(),
        dataCaptacao: _dataCaptacao,
        matricula: _matricula.text.trim(),
        inscricaoMunicipal: _inscricao.text.trim(),
        localChaves: _localChaves.text.trim(),
        exclusividade: _exclusividade,
        anexos: _anexos,
      ),
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Imóvel salvo.')));
  }

  IconData _iconeAnexo(AnexoTipo t) => switch (t) {
    AnexoTipo.foto => Icons.photo_outlined,
    AnexoTipo.video => Icons.videocam_outlined,
    AnexoTipo.arquivo => Icons.attach_file,
    AnexoTipo.link => Icons.link,
  };

  @override
  Widget build(BuildContext context) {
    final contatos = _store.contatos;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.gold,
        title: Text(widget.imovel == null ? 'Novo imóvel' : 'Editar imóvel'),
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
                  title: 'Identificação',
                  icon: Icons.badge_outlined,
                  children: [
                    FieldRow(
                      flex: const [1, 3],
                      children: [
                        AppTextField(
                          label: 'Código',
                          controller: _codigoCtrl,
                          readOnly: true,
                        ),
                        AppTextField(
                          label: 'Título do anúncio *',
                          controller: _titulo,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Informe o título'
                              : null,
                        ),
                      ],
                    ),
                    ChipMultiSelect<Finalidade>(
                      title: 'Finalidade *',
                      options: Finalidade.values,
                      selected: _finalidades,
                      labelOf: (e) => e.label,
                      onChanged: (v) => setState(() => _finalidades = v),
                    ),
                    FieldRow(
                      children: [
                        AppDropdown<TipoImovel>(
                          label: 'Tipo do imóvel',
                          value: _tipo,
                          items: TipoImovel.values,
                          labelOf: (e) => e.label,
                          onChanged: (v) => setState(() => _tipo = v ?? _tipo),
                        ),
                        AppDropdown<StatusImovel>(
                          label: 'Situação',
                          value: _status,
                          items: StatusImovel.values,
                          labelOf: (e) => e.label,
                          onChanged: (v) =>
                              setState(() => _status = v ?? _status),
                        ),
                      ],
                    ),
                    AppDropdown<String?>(
                      label: 'Proprietário',
                      value: contatos.any((c) => c.id == _proprietarioId)
                          ? _proprietarioId
                          : null,
                      items: [null, ...contatos.map((c) => c.id)],
                      labelOf: (id) => id == null
                          ? 'Nenhum (cadastre em Contatos)'
                          : contatos.firstWhere((c) => c.id == id).nome,
                      onChanged: (v) => setState(() => _proprietarioId = v),
                    ),
                  ],
                ),
                FormSection(
                  title: 'Localização',
                  icon: Icons.place_outlined,
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
                    FieldRow(
                      children: [
                        AppTextField(
                          label: 'Condomínio / Edifício',
                          controller: _condominioNome,
                        ),
                        AppTextField(
                          label: 'Ponto de referência',
                          controller: _referencia,
                        ),
                      ],
                    ),
                    AppSwitch(
                      label: 'Exibir endereço completo no site e portais',
                      value: _exibirEndereco,
                      onChanged: (v) => setState(() => _exibirEndereco = v),
                    ),
                  ],
                ),
                FormSection(
                  title: 'Valores e condições',
                  icon: Icons.attach_money,
                  children: [
                    if (_finalidades.contains(Finalidade.venda))
                      AppTextField.money(
                        label: 'Valor de venda',
                        controller: _valorVenda,
                      ),
                    if (_finalidades.contains(Finalidade.locacao))
                      AppTextField.money(
                        label: 'Valor do aluguel (mensal)',
                        controller: _valorLocacao,
                      ),
                    if (_finalidades.contains(Finalidade.temporada))
                      AppTextField.money(
                        label: 'Valor da diária (temporada)',
                        controller: _valorTemporada,
                      ),
                    FieldRow(
                      children: [
                        AppTextField.money(
                          label: 'Condomínio (mensal)',
                          controller: _valorCondominio,
                        ),
                        AppTextField.money(
                          label: 'IPTU (anual)',
                          controller: _valorIptu,
                        ),
                        AppTextField.decimal(
                          label: 'Comissão',
                          controller: _comissao,
                          suffixText: '%',
                        ),
                      ],
                    ),
                    AppSwitch(
                      label: 'Aceita financiamento',
                      value: _aceitaFinanciamento,
                      onChanged: (v) =>
                          setState(() => _aceitaFinanciamento = v),
                    ),
                    AppSwitch(
                      label: 'Aceita permuta',
                      value: _aceitaPermuta,
                      onChanged: (v) => setState(() => _aceitaPermuta = v),
                    ),
                  ],
                ),
                FormSection(
                  title: 'Características do imóvel',
                  icon: Icons.bed_outlined,
                  children: [
                    FieldRow(
                      children: [
                        AppTextField.integer(
                          label: 'Quartos',
                          controller: _quartos,
                        ),
                        AppTextField.integer(
                          label: 'Suítes',
                          controller: _suites,
                        ),
                        AppTextField.integer(
                          label: 'Banheiros',
                          controller: _banheiros,
                        ),
                        AppTextField.integer(
                          label: 'Vagas',
                          controller: _vagas,
                        ),
                      ],
                    ),
                    FieldRow(
                      children: [
                        AppTextField.decimal(
                          label: 'Área útil',
                          controller: _areaUtil,
                          suffixText: 'm²',
                        ),
                        AppTextField.decimal(
                          label: 'Área total',
                          controller: _areaTotal,
                          suffixText: 'm²',
                        ),
                        AppTextField.decimal(
                          label: 'Área do terreno',
                          controller: _areaTerreno,
                          suffixText: 'm²',
                        ),
                      ],
                    ),
                    FieldRow(
                      children: [
                        AppTextField.integer(
                          label: 'Andar',
                          controller: _andar,
                        ),
                        AppTextField.integer(
                          label: 'Ano de construção',
                          controller: _ano,
                        ),
                        AppDropdown<Mobiliado>(
                          label: 'Mobília',
                          value: _mobiliado,
                          items: Mobiliado.values,
                          labelOf: (e) => e.label,
                          onChanged: (v) =>
                              setState(() => _mobiliado = v ?? _mobiliado),
                        ),
                      ],
                    ),
                  ],
                ),
                FormSection(
                  title: 'Comodidades e características personalizadas',
                  icon: Icons.checklist,
                  children: [
                    ChipMultiSelect<String>(
                      title: 'Comodidades',
                      options: comodidadesPadrao,
                      selected: _comodidades,
                      onChanged: (v) => setState(() => _comodidades = v),
                    ),
                    const Divider(),
                    const Text(
                      'Características personalizadas (além das padrão)',
                      style: TextStyle(color: Colors.white70),
                    ),
                    FieldRow(
                      flex: const [2, 2],
                      children: [
                        AppTextField(
                          label: 'Característica',
                          hint: 'Ex.: Pé-direito',
                          controller: _persNome,
                        ),
                        AppTextField(
                          label: 'Valor (opcional)',
                          hint: 'Ex.: 4 m',
                          controller: _persValor,
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _addPersonalizada,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar característica'),
                      ),
                    ),
                    for (var i = 0; i < _personalizadas.length; i++)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.star_outline,
                          color: AppColors.gold,
                        ),
                        title: Text(_personalizadas[i].nome),
                        subtitle: _personalizadas[i].valor.isEmpty
                            ? null
                            : Text(_personalizadas[i].valor),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              setState(() => _personalizadas.removeAt(i)),
                        ),
                      ),
                  ],
                ),
                FormSection(
                  title: 'Descrição',
                  icon: Icons.notes,
                  children: [
                    AppTextField(
                      label: 'Descrição para divulgação',
                      controller: _descricao,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    AppTextField(
                      label: 'Observações internas (não aparecem no anúncio)',
                      controller: _obsInternas,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
                FormSection(
                  title: 'Captação e dados legais',
                  icon: Icons.gavel_outlined,
                  children: [
                    FieldRow(
                      children: [
                        AppTextField(
                          label: 'Corretor captador',
                          controller: _captador,
                        ),
                        DateField(
                          label: 'Data da captação',
                          value: _dataCaptacao,
                          onChanged: (d) => setState(() => _dataCaptacao = d),
                        ),
                      ],
                    ),
                    FieldRow(
                      children: [
                        AppTextField(
                          label: 'Matrícula do imóvel',
                          controller: _matricula,
                        ),
                        AppTextField(
                          label: 'Inscrição municipal (IPTU)',
                          controller: _inscricao,
                        ),
                      ],
                    ),
                    AppTextField(
                      label: 'Localização das chaves',
                      hint: 'Ex.: Portaria, escritório, proprietário',
                      controller: _localChaves,
                    ),
                    AppSwitch(
                      label: 'Imóvel com exclusividade',
                      value: _exclusividade,
                      onChanged: (v) => setState(() => _exclusividade = v),
                    ),
                  ],
                ),
                FormSection(
                  title: 'Anexos: fotos, vídeos e arquivos',
                  icon: Icons.perm_media_outlined,
                  children: [
                    FieldRow(
                      flex: const [1, 2, 3],
                      children: [
                        AppDropdown<AnexoTipo>(
                          label: 'Tipo',
                          value: _anexoTipo,
                          items: AnexoTipo.values,
                          labelOf: (e) => e.label,
                          onChanged: (v) =>
                              setState(() => _anexoTipo = v ?? _anexoTipo),
                        ),
                        AppTextField(label: 'Título', controller: _anexoTitulo),
                        AppTextField(
                          label: 'Link (URL)',
                          hint: 'https://...',
                          controller: _anexoUrl,
                          keyboardType: TextInputType.url,
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _addAnexo,
                        icon: const Icon(Icons.add_link),
                        label: const Text('Adicionar anexo'),
                      ),
                    ),
                    if (_anexos.isEmpty)
                      const Text(
                        'Nenhum anexo adicionado.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    for (var i = 0; i < _anexos.length; i++)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          _iconeAnexo(_anexos[i].tipo),
                          color: AppColors.gold,
                        ),
                        title: Text(_anexos[i].titulo),
                        subtitle: Text(
                          _anexos[i].url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => setState(() => _anexos.removeAt(i)),
                        ),
                      ),
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
                    'SALVAR IMÓVEL',
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
