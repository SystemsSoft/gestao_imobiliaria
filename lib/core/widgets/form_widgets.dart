import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Cartão com título que agrupa campos de um formulário.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Coloca os filhos lado a lado em telas largas e empilhados em telas estreitas.
class FieldRow extends StatelessWidget {
  const FieldRow({super.key, required this.children, this.flex = const []});

  final List<Widget> children;
  final List<int> flex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                children[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(flex: i < flex.length ? flex[i] : 1, child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
    this.prefixText,
    this.suffixText,
    this.hint,
    this.readOnly = false,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
    this.icon,
  });

  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;
  final String? prefixText;
  final String? suffixText;
  final String? hint;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;
  final IconData? icon;

  /// Campo de dinheiro (centavos), com prefixo R$.
  factory AppTextField.money({
    Key? key,
    required String label,
    required TextEditingController controller,
  }) => AppTextField(
    key: key,
    label: label,
    controller: controller,
    prefixText: r'R$ ',
    keyboardType: TextInputType.number,
    inputFormatters: [CurrencyInputFormatter()],
  );

  factory AppTextField.integer({
    Key? key,
    required String label,
    required TextEditingController controller,
  }) => AppTextField(
    key: key,
    label: label,
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  );

  factory AppTextField.decimal({
    Key? key,
    required String label,
    required TextEditingController controller,
    String? suffixText,
    ValueChanged<String>? onChanged,
  }) => AppTextField(
    key: key,
    label: label,
    controller: controller,
    suffixText: suffixText,
    onChanged: onChanged,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))],
  );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      readOnly: readOnly,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        suffixText: suffixText,
        prefixIcon: icon == null ? null : Icon(icon),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelOf,
    this.validator,
  });

  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T)? labelOf;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      // Recria o campo quando as opções mudam (ex.: carregadas depois).
      key: ValueKey(Object.hashAll(items)),
      initialValue: value,
      isExpanded: true,
      dropdownColor: AppColors.navy,
      validator: validator,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final e in items)
          DropdownMenuItem<T>(
            value: e,
            child: Text(
              labelOf != null ? labelOf!(e) : e.toString(),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Seleção múltipla em formato de chips.
class ChipMultiSelect<T> extends StatelessWidget {
  const ChipMultiSelect({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.labelOf,
    this.title,
  });

  final List<T> options;
  final Set<T> selected;
  final ValueChanged<Set<T>> onChanged;
  final String Function(T)? labelOf;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title!, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              FilterChip(
                label: Text(labelOf != null ? labelOf!(o) : o.toString()),
                selected: selected.contains(o),
                showCheckmark: false,
                selectedColor: AppColors.gold,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
                labelStyle: TextStyle(
                  color: selected.contains(o)
                      ? AppColors.navyDark
                      : Colors.white,
                  fontWeight: selected.contains(o)
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
                onSelected: (on) {
                  final next = {...selected};
                  on ? next.add(o) : next.remove(o);
                  onChanged(next);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label),
      value: value,
      activeThumbColor: AppColors.gold,
      onChanged: onChanged,
    );
  }
}

/// Campo que abre o seletor de data (e hora, se [withTime]).
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.withTime = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool withTime;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;
    if (!withTime) {
      onChanged(date);
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value ?? now),
    );
    if (time == null) return;
    onChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: value == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(
          withTime ? formatDateTime(value) : formatDate(value),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.gold.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class GoldChip extends StatelessWidget {
  const GoldChip(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Text(text, style: TextStyle(color: c, fontSize: 12)),
    );
  }
}

Future<bool> confirmDelete(BuildContext context, String message) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.navy,
      title: const Text('Excluir'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Ícone de fundo dourado para botões de ação flutuantes.
FloatingActionButton goldFab({
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
}) {
  return FloatingActionButton.extended(
    onPressed: onPressed,
    backgroundColor: AppColors.gold,
    foregroundColor: AppColors.navyDark,
    icon: Icon(icon),
    label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}

/// Linha horizontal de chips de filtro com a opção "Todos".
class FiltroChips<T> extends StatelessWidget {
  const FiltroChips({
    super.key,
    required this.opcoes,
    required this.selecionado,
    required this.labelOf,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<T> opcoes;
  final T? selecionado;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        children: [
          for (final o in <T?>[null, ...opcoes])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(o == null ? 'Todos' : labelOf(o)),
                selected: selecionado == o,
                selectedColor: AppColors.gold,
                labelStyle: TextStyle(
                  color: selecionado == o ? AppColors.navyDark : Colors.white,
                ),
                onSelected: (_) => onChanged(o),
              ),
            ),
        ],
      ),
    );
  }
}

void mostrarMensagem(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensagem)));
}

/// Cartão padrão das listas.
class CardPadrao extends StatelessWidget {
  const CardPadrao({super.key, required this.child, this.onTap, this.borda});

  final Widget child;
  final VoidCallback? onTap;
  final Color? borda;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.06),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: (borda ?? AppColors.gold).withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(12), child: child),
      ),
    );
  }
}

/// Faixa de indicadores (ex.: previsto, recebido, em aberto).
class ResumoValores extends StatelessWidget {
  const ResumoValores({super.key, required this.itens});

  final List<({String rotulo, String valor, Color cor})> itens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.blue.withValues(alpha: 0.5), AppColors.navy],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          for (final i in itens)
            Expanded(
              child: Column(
                children: [
                  FittedBox(
                    child: Text(
                      i.valor,
                      style: TextStyle(
                        color: i.cor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    i.rotulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
