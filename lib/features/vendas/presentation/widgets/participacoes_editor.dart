import 'package:flutter/material.dart';

import '../../../../core/config/empresa_info.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../domain/entities/venda.dart';

const _imobiliaria = '__imobiliaria__';

/// Linha editável de participação (pessoa + percentual).
class ParticipacaoEdit {
  ParticipacaoEdit({
    this.contatoId,
    this.imobiliaria = false,
    double? percentual,
    this.pagaEm,
  }) : percentual = TextEditingController(text: decimalToText(percentual));

  factory ParticipacaoEdit.de(Participacao p) => ParticipacaoEdit(
    contatoId: p.contatoId,
    imobiliaria: p.contatoId == null,
    percentual: p.percentual,
    pagaEm: p.pagaEm,
  );

  String? contatoId;
  bool imobiliaria;
  final TextEditingController percentual;
  final DateTime? pagaEm;

  double get valor => parseDecimal(percentual.text) ?? 0;

  Participacao toParticipacao() => Participacao(
    contatoId: imobiliaria ? null : contatoId,
    percentual: valor,
    pagaEm: pagaEm,
  );
}

/// Lista de participações com soma dos percentuais.
class ParticipacoesEditor extends StatelessWidget {
  const ParticipacoesEditor({
    super.key,
    required this.itens,
    required this.contatos,
    required this.onChanged,
    required this.rotulo,
    this.permitirImobiliaria = false,
  });

  final List<ParticipacaoEdit> itens;
  final List<Contato> contatos;
  final VoidCallback onChanged;
  final String rotulo;
  final bool permitirImobiliaria;

  @override
  Widget build(BuildContext context) {
    final soma = itens.fold<double>(0, (s, p) => s + p.valor);
    final ok = (soma - 100).abs() <= 0.01;
    String nome(String id) => id == _imobiliaria
        ? '${EmpresaInfo.nome} (imobiliária)'
        : contatos.firstWhere((c) => c.id == id).nome;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < itens.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: AppDropdown<String>(
                    label: rotulo,
                    value: itens[i].imobiliaria
                        ? _imobiliaria
                        : contatos.any((c) => c.id == itens[i].contatoId)
                        ? itens[i].contatoId
                        : null,
                    items: [
                      if (permitirImobiliaria) _imobiliaria,
                      ...contatos.map((c) => c.id),
                    ],
                    labelOf: nome,
                    onChanged: (v) {
                      itens[i].imobiliaria = v == _imobiliaria;
                      itens[i].contatoId = v == _imobiliaria ? null : v;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTextField.decimal(
                    label: 'Cota',
                    controller: itens[i].percentual,
                    suffixText: '%',
                    onChanged: (_) => onChanged(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    itens.removeAt(i).percentual.dispose();
                    onChanged();
                  },
                ),
              ],
            ),
          ),
        // O total desce para a linha de baixo em telas estreitas.
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  itens.add(
                    ParticipacaoEdit(percentual: itens.isEmpty ? 100 : null),
                  );
                  onChanged();
                },
                icon: const Icon(Icons.person_add_alt),
                label: Text('Adicionar ${rotulo.toLowerCase()}'),
              ),
              Text(
                'Total: ${decimalToText(soma)}%',
                style: TextStyle(
                  color: ok ? Colors.greenAccent : Colors.orangeAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
