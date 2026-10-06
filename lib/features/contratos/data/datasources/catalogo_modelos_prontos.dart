import '../../domain/entities/modelo_contrato.dart';
import '../../domain/entities/modelo_pronto.dart';
import '../../domain/entities/parametro_modelo.dart';
import 'modelos_padrao.dart';

/// Ids dos modelos prontos usados como base dos modelos iniciais.
const idProntoLocacaoResidencial = 'pronto-locacao-residencial';
const idProntoCompraVenda = 'pronto-compra-venda';

const _foro = ParametroModelo(
  chave: 'foro_cidade',
  rotulo: 'Cidade do foro',
  valorPadrao: 'Niterói',
  descricao: 'Comarca eleita para resolver dúvidas do contrato.',
);

/// Catálogo de modelos prontos. Os textos são minutas gerais: revise com um
/// advogado antes de usar com clientes.
const catalogoModelosProntos = <ModeloPronto>[
  ModeloPronto(
    id: idProntoLocacaoResidencial,
    nome: 'Locação residencial',
    descricao:
        'Contrato de aluguel de imóvel residencial com fiador, caução ou seguro-fiança.',
    tipo: TipoModelo.locacao,
    texto: modeloLocacaoResidencial,
  ),
  ModeloPronto(
    id: 'pronto-locacao-comercial',
    nome: 'Locação comercial',
    descricao:
        'Aluguel de sala, loja ou galpão, com aviso prévio, multa rescisória e foro configuráveis.',
    tipo: TipoModelo.locacao,
    texto: modeloLocacaoComercial,
    parametros: [
      _foro,
      ParametroModelo(
        chave: 'multa_rescisoria_alugueis',
        rotulo: 'Multa rescisória (em aluguéis)',
        tipo: TipoParametro.numero,
        valorPadrao: '3',
      ),
      ParametroModelo(
        chave: 'prazo_aviso_dias',
        rotulo: 'Aviso prévio (dias)',
        tipo: TipoParametro.numero,
        valorPadrao: '30',
      ),
    ],
  ),
  ModeloPronto(
    id: 'pronto-temporada',
    nome: 'Locação por temporada',
    descricao:
        'Hospedagem de curta duração, com caução, regras da casa e política de cancelamento.',
    tipo: TipoModelo.temporada,
    texto: modeloTemporada,
    parametros: [
      ParametroModelo(
        chave: 'horario_entrada',
        rotulo: 'Horário de entrada',
        valorPadrao: '14h',
      ),
      ParametroModelo(
        chave: 'horario_saida',
        rotulo: 'Horário de saída',
        valorPadrao: '11h',
      ),
      ParametroModelo(
        chave: 'prazo_cancelamento_dias',
        rotulo: 'Cancelamento sem devolução (dias)',
        tipo: TipoParametro.numero,
        valorPadrao: '15',
      ),
    ],
  ),
  ModeloPronto(
    id: idProntoCompraVenda,
    nome: 'Promessa de compra e venda',
    descricao:
        'Instrumento particular de venda, à vista, financiado ou com parcelamento próprio.',
    tipo: TipoModelo.venda,
    texto: modeloCompraVenda,
  ),
  ModeloPronto(
    id: 'pronto-administracao',
    nome: 'Administração de imóvel',
    descricao:
        'Contrato entre proprietário e imobiliária para administrar e locar o imóvel.',
    tipo: TipoModelo.administracao,
    texto: modeloAdministracao,
    parametros: [
      ParametroModelo(
        chave: 'limite_reparos',
        rotulo: 'Limite para reparos de urgência',
        tipo: TipoParametro.dinheiro,
        valorPadrao: '1.000,00',
      ),
    ],
  ),
  ModeloPronto(
    id: 'pronto-autorizacao-venda',
    nome: 'Autorização de venda com exclusividade',
    descricao:
        'Autoriza o corretor a vender o imóvel, com prazo, preço e comissão.',
    tipo: TipoModelo.autorizacao,
    texto: modeloAutorizacaoVenda,
    parametros: [
      ParametroModelo(
        chave: 'prazo_protecao_dias',
        rotulo: 'Proteção da comissão após o prazo (dias)',
        tipo: TipoParametro.numero,
        valorPadrao: '90',
      ),
    ],
  ),
  ModeloPronto(
    id: 'pronto-proposta-compra',
    nome: 'Proposta de compra',
    descricao:
        'Proposta formal do interessado, com validade e prazo para o contrato.',
    tipo: TipoModelo.outros,
    texto: modeloPropostaCompra,
    parametros: [
      ParametroModelo(
        chave: 'validade_dias',
        rotulo: 'Validade da proposta (dias)',
        tipo: TipoParametro.numero,
        valorPadrao: '5',
      ),
      ParametroModelo(
        chave: 'prazo_contrato_dias',
        rotulo: 'Prazo para o contrato (dias)',
        tipo: TipoParametro.numero,
        valorPadrao: '15',
      ),
    ],
  ),
  ModeloPronto(
    id: 'pronto-distrato',
    nome: 'Distrato de locação',
    descricao:
        'Encerramento amigável do contrato, com entrega de chaves e quitação.',
    tipo: TipoModelo.outros,
    texto: modeloDistrato,
    parametros: [
      ParametroModelo(
        chave: 'condicao_multa',
        rotulo: 'Condição sobre a multa',
        valorPadrao: 'As partes ajustam a dispensa da multa rescisória.',
      ),
    ],
  ),
  ModeloPronto(
    id: 'pronto-recibo-sinal',
    nome: 'Recibo de sinal',
    descricao:
        'Comprova o recebimento do sinal e princípio de pagamento (arras).',
    tipo: TipoModelo.outros,
    texto: modeloReciboSinal,
  ),
];
