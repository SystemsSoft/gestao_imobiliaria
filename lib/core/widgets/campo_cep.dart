import 'package:flutter/material.dart';

import '../cep/busca_cep.dart';
import '../di/injector.dart';
import '../errors/domain_exception.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Campo de CEP que, ao completar os 8 dígitos, busca o endereço e chama
/// [onEncontrado] para preencher os demais campos.
class CampoCep extends StatefulWidget {
  const CampoCep({
    super.key,
    required this.controller,
    required this.onEncontrado,
    this.label = 'CEP',
  });

  final TextEditingController controller;
  final ValueChanged<EnderecoCep> onEncontrado;
  final String label;

  @override
  State<CampoCep> createState() => _CampoCepState();
}

class _CampoCepState extends State<CampoCep> {
  bool _buscando = false;
  String? _aviso;
  String _ultimo = '';

  Future<void> _mudou(String texto) async {
    final cep = BuscaCep.digitos(texto);
    if (cep.length != 8) {
      if (_aviso != null) setState(() => _aviso = null);
      _ultimo = '';
      return;
    }
    if (cep == _ultimo) return;
    _ultimo = cep;
    setState(() {
      _buscando = true;
      _aviso = null;
    });
    try {
      final e = await sl<BuscaCep>()(cep);
      if (!mounted || BuscaCep.digitos(widget.controller.text) != cep) return;
      if (e == null) {
        setState(() => _aviso = 'CEP não encontrado.');
      } else {
        widget.onEncontrado(e);
      }
    } on DomainException catch (e) {
      if (mounted) setState(() => _aviso = e.mensagem);
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: TextInputType.number,
      inputFormatters: [cepFormatter],
      onChanged: _mudou,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: _aviso == null ? 'Preenche o endereço' : null,
        errorText: _aviso,
        errorMaxLines: 3,
        suffixIcon: _buscando
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                ),
              )
            : const Icon(Icons.search, size: 20),
      ),
    );
  }
}
