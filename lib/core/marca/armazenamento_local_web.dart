import 'package:web/web.dart' as web;

import 'armazenamento_local.dart';

/// No navegador: localStorage (navegação privada ou bloqueio não quebram o
/// app; o valor só não fica guardado).
class ArmazenamentoLocalPlataforma implements ArmazenamentoLocal {
  @override
  String? ler(String chave) {
    try {
      return web.window.localStorage.getItem(chave);
    } on Object {
      return null;
    }
  }

  @override
  void gravar(String chave, String valor) {
    try {
      web.window.localStorage.setItem(chave, valor);
    } on Object {
      // Sem armazenamento: o código é pedido de novo na próxima vez.
    }
  }

  @override
  void remover(String chave) {
    try {
      web.window.localStorage.removeItem(chave);
    } on Object {
      // Nada guardado.
    }
  }
}
