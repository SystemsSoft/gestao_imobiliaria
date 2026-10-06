import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

const _cores = [
  Color(0xFFF5C432),
  Color(0xFF4FC3F7),
  Color(0xFF81C784),
  Color(0xFFFF8A65),
  Color(0xFFBA68C8),
  Color(0xFF4DB6AC),
  Color(0xFFE57373),
  Color(0xFF7986CB),
];

/// Avatar com as iniciais e, opcionalmente, o ponto de presença.
class AvatarUsuario extends StatelessWidget {
  const AvatarUsuario({
    super.key,
    required this.nome,
    this.online,
    this.raio = 22,
  });

  final String nome;

  /// Nulo não mostra o ponto de presença.
  final bool? online;
  final double raio;

  String get _iniciais {
    final p = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (p.isEmpty) return '?';
    return (p.first[0] + (p.length > 1 ? p.last[0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cor = _cores[nome.codeUnits.fold(0, (a, b) => a + b) % _cores.length];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: raio,
          backgroundColor: cor.withValues(alpha: 0.25),
          foregroundColor: cor,
          child: Text(
            _iniciais,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: raio * 0.7),
          ),
        ),
        if (online != null)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: raio * 0.6,
              height: raio * 0.6,
              decoration: BoxDecoration(
                color: online! ? Colors.greenAccent : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.navyDark, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
