/// O que o site público mostra e como os leads são atendidos. Contatos em
/// branco usam os dados da imobiliária (Personalização).
class ConfiguracaoSite {
  const ConfiguracaoSite({
    this.noAr = true,
    this.titulo = 'Encontre o imóvel ideal para você',
    this.subtitulo =
        'Compra, venda e locação com atendimento personalizado de quem '
        'conhece a região.',
    this.textoSobre =
        'Atuamos com ética, transparência e dedicação para que cada cliente '
        'encontre o imóvel certo — seja para morar, investir ou alugar. '
        'Cuidamos de toda a negociação, da primeira visita à entrega das chaves.',
    this.chamadaAnuncie =
        'Quer vender ou alugar seu imóvel? Cadastre-o com a gente e receba '
        'uma avaliação sem compromisso.',
    this.mensagemObrigado =
        'Recebemos sua mensagem! Um de nossos corretores vai falar com você '
        'em breve.',
    this.whatsapp = '',
    this.telefone = '',
    this.email = '',
    this.endereco = '',
    this.horario = 'Segunda a sexta, das 9h às 18h',
    this.instagram = '',
    this.facebook = '',
    this.mostrarBusca = true,
    this.mostrarDestaques = true,
    this.mostrarSobre = true,
    this.mostrarContato = true,
    this.mostrarAnuncie = true,
    this.permitirAgendarVisita = true,
    this.botaoWhatsapp = true,
    this.mostrarValores = true,
    this.mostrarAreaInquilino = true,
    this.distribuirNaFila = true,
    this.criarTarefa = true,
    this.metaDescricao = '',
  });

  final bool noAr;

  // Conteúdo
  final String titulo;
  final String subtitulo;
  final String textoSobre;
  final String chamadaAnuncie;
  final String mensagemObrigado;

  // Contatos e redes
  final String whatsapp;
  final String telefone;
  final String email;
  final String endereco;
  final String horario;
  final String instagram;
  final String facebook;

  // Funcionalidades
  final bool mostrarBusca;
  final bool mostrarDestaques;
  final bool mostrarSobre;
  final bool mostrarContato;
  final bool mostrarAnuncie;
  final bool permitirAgendarVisita;
  final bool botaoWhatsapp;
  final bool mostrarValores;

  /// Link e páginas da Área do inquilino (/inquilino).
  final bool mostrarAreaInquilino;

  // Atendimento dos leads
  final bool distribuirNaFila;
  final bool criarTarefa;

  // Buscadores
  final String metaDescricao;

  ConfiguracaoSite copyWith({
    bool? noAr,
    String? titulo,
    String? subtitulo,
    String? textoSobre,
    String? chamadaAnuncie,
    String? mensagemObrigado,
    String? whatsapp,
    String? telefone,
    String? email,
    String? endereco,
    String? horario,
    String? instagram,
    String? facebook,
    bool? mostrarBusca,
    bool? mostrarDestaques,
    bool? mostrarSobre,
    bool? mostrarContato,
    bool? mostrarAnuncie,
    bool? permitirAgendarVisita,
    bool? botaoWhatsapp,
    bool? mostrarValores,
    bool? mostrarAreaInquilino,
    bool? distribuirNaFila,
    bool? criarTarefa,
    String? metaDescricao,
  }) => ConfiguracaoSite(
    noAr: noAr ?? this.noAr,
    titulo: titulo ?? this.titulo,
    subtitulo: subtitulo ?? this.subtitulo,
    textoSobre: textoSobre ?? this.textoSobre,
    chamadaAnuncie: chamadaAnuncie ?? this.chamadaAnuncie,
    mensagemObrigado: mensagemObrigado ?? this.mensagemObrigado,
    whatsapp: whatsapp ?? this.whatsapp,
    telefone: telefone ?? this.telefone,
    email: email ?? this.email,
    endereco: endereco ?? this.endereco,
    horario: horario ?? this.horario,
    instagram: instagram ?? this.instagram,
    facebook: facebook ?? this.facebook,
    mostrarBusca: mostrarBusca ?? this.mostrarBusca,
    mostrarDestaques: mostrarDestaques ?? this.mostrarDestaques,
    mostrarSobre: mostrarSobre ?? this.mostrarSobre,
    mostrarContato: mostrarContato ?? this.mostrarContato,
    mostrarAnuncie: mostrarAnuncie ?? this.mostrarAnuncie,
    permitirAgendarVisita: permitirAgendarVisita ?? this.permitirAgendarVisita,
    botaoWhatsapp: botaoWhatsapp ?? this.botaoWhatsapp,
    mostrarValores: mostrarValores ?? this.mostrarValores,
    mostrarAreaInquilino: mostrarAreaInquilino ?? this.mostrarAreaInquilino,
    distribuirNaFila: distribuirNaFila ?? this.distribuirNaFila,
    criarTarefa: criarTarefa ?? this.criarTarefa,
    metaDescricao: metaDescricao ?? this.metaDescricao,
  );
}
