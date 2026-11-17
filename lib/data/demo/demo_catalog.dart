import '../models/brand.dart';
import '../models/drop.dart';

/// CONTEÚDO DE DEMONSTRAÇÃO.
///
/// Marcas e produtos fictícios, criados só para validar as telas enquanto o
/// catálogo real não está no Firestore. Nada aqui representa um lançamento
/// real: os sites apontam para `example.com` e as datas são relativas ao
/// momento em que o app abre (para a linha do tempo estar sempre viva).
///
/// Para trocar por conteúdo real, basta ligar o Firebase: o
/// `FirestoreCatalogRepository` substitui este arquivo sem mexer nas telas.
abstract final class DemoCatalog {
  static const brands = <Brand>[
    Brand(
      id: 'vertice',
      name: 'Vértice',
      tagline: 'Sneakers de arquitetura.',
      description:
          'Estúdio de calçados que desenha tênis como quem projeta um prédio: '
          'linhas de estrutura à mostra, poucas cores e solados pensados para '
          'o asfalto. Cada modelo sai em tiragem numerada.',
      origin: 'São Paulo, BR',
      websiteUrl: 'https://example.com/vertice',
      tone: 0,
    ),
    Brand(
      id: 'cromo',
      name: 'Cromo Lab',
      tagline: 'Edições limitadas em prata.',
      description:
          'Laboratório de acabamentos metálicos. Trabalha com couro espelhado, '
          'malha refletiva e ferragens polidas, sempre em lotes pequenos que '
          'não voltam ao catálogo.',
      origin: 'Porto Alegre, BR',
      websiteUrl: 'https://example.com/cromo-lab',
      tone: 1,
    ),
    Brand(
      id: 'kalt',
      name: 'Kalt Atelier',
      tagline: 'Peças para clima frio.',
      description:
          'Moletons pesados, zíperes à prova de vento e uma paleta que vai do '
          'grafite ao azul-gelo. Feito para a rua nas manhãs frias do sul.',
      origin: 'Curitiba, BR',
      websiteUrl: 'https://example.com/kalt-atelier',
      tone: 5,
    ),
    Brand(
      id: 'asfalto',
      name: 'Asfalto Club',
      tagline: 'Corrida de rua, à noite.',
      description:
          'Coletivo de corredores noturnos que virou marca. Os tênis têm '
          'detalhes refletivos e o nome de cada modelo vem de uma pista da '
          'cidade.',
      origin: 'Rio de Janeiro, BR',
      websiteUrl: 'https://example.com/asfalto-club',
      tone: 4,
    ),
    Brand(
      id: 'monofase',
      name: 'Monofase',
      tagline: 'Básicos em uma cor só.',
      description:
          'Camisetas e moletons de algodão pesado, tingidos peça a peça. Uma '
          'cor por coleção, sem estampa, sem logo aparente.',
      origin: 'Belo Horizonte, BR',
      websiteUrl: 'https://example.com/monofase',
      tone: 3,
    ),
    Brand(
      id: 'orla',
      name: 'Orla Norte',
      tagline: 'Acessórios de bolso e de ombro.',
      description:
          'Bolsas transversais, bonés e pequenos objetos feitos de lona náutica '
          'reaproveitada. Leves, resistentes à maresia.',
      origin: 'Recife, BR',
      // Sem site cadastrado: exercita o estado "link indisponível".
      websiteUrl: null,
      tone: 2,
    ),
  ];

  /// Gera os lançamentos em torno de [now].
  static List<Drop> drops(DateTime now) {
    DateTime at(int days, [int hour = 10, int minute = 0]) =>
        DateTime(now.year, now.month, now.day + days, hour, minute);
    final created = now.subtract(const Duration(days: 20));
    DateTime added(int daysAgo) => now.subtract(Duration(days: daysAgo));

    return [
      Drop(
        id: 'cromo-liga-prata-fria',
        name: "Liga 'Prata Fria'",
        brandId: 'cromo',
        brandName: 'Cromo Lab',
        category: DropCategory.sneakers,
        colorway: 'Prata / Grafite',
        description:
            'Cabedal em couro espelhado com costura aparente e entressola '
            'branca. É o primeiro modelo da linha Liga e sai em lote único.',
        price: 1299,
        releaseAt: now.subtract(const Duration(hours: 3)),
        hasTime: true,
        officialUrl: 'https://example.com/cromo-lab/liga-prata-fria',
        featured: true,
        art: DropArt.sneaker,
        tone: 1,
        createdAt: added(12),
        updatedAt: added(0),
      ),
      Drop(
        id: 'vertice-arco-01',
        name: "Arco 01 'Grafite'",
        brandId: 'vertice',
        brandName: 'Vértice',
        category: DropCategory.sneakers,
        colorway: 'Grafite / Osso',
        description:
            'Tênis de perfil baixo com painel lateral contínuo, do calcanhar '
            'ao arco do pé. Sola em borracha natural e forro em algodão.',
        price: 899.9,
        releaseAt: at(2, 10),
        hasTime: true,
        officialUrl: 'https://example.com/vertice/arco-01',
        featured: true,
        art: DropArt.sneaker,
        tone: 0,
        createdAt: added(6),
        updatedAt: added(1),
      ),
      Drop(
        id: 'geada-cromo-kalt',
        name: "Geada 'Cromo × Kalt'",
        brandId: 'cromo',
        brandName: 'Cromo Lab',
        category: DropCategory.sneakers,
        colorway: 'Gelo / Prata',
        description:
            'Colaboração entre Cromo Lab e Kalt Atelier: cano alto forrado, '
            'malha refletiva e cadarço encerado. Preço ainda não divulgado.',
        releaseAt: at(3, 20),
        hasTime: true,
        officialUrl: 'https://example.com/cromo-lab/geada',
        featured: true,
        art: DropArt.sneaker,
        tone: 5,
        createdAt: added(2),
        updatedAt: added(0),
      ),
      Drop(
        id: 'monofase-tee-osso',
        name: "Tee Peso Pesado 'Osso'",
        brandId: 'monofase',
        brandName: 'Monofase',
        category: DropCategory.apparel,
        colorway: 'Osso',
        description:
            'Camiseta de algodão 280 g/m², gola reforçada e modelagem ampla. '
            'Tingida depois de pronta, o que deixa cada peça com um tom único.',
        price: 189,
        releaseAt: at(1, 9),
        hasTime: true,
        officialUrl: 'https://example.com/monofase/tee-osso',
        art: DropArt.tee,
        tone: 3,
        createdAt: added(9),
        updatedAt: added(3),
      ),
      Drop(
        id: 'kalt-casulo',
        name: 'Casulo Hoodie',
        brandId: 'kalt',
        brandName: 'Kalt Atelier',
        category: DropCategory.apparel,
        colorway: 'Aço',
        description:
            'Moletom com capuz duplo e bolso canguru forrado. O punho longo '
            'cobre metade da mão: pensado para as manhãs abaixo de 10 °C.',
        price: 549,
        releaseAt: at(5, 12),
        hasTime: true,
        officialUrl: 'https://example.com/kalt-atelier/casulo',
        featured: true,
        art: DropArt.hoodie,
        tone: 5,
        createdAt: added(4),
        updatedAt: added(2),
      ),
      Drop(
        id: 'asfalto-noturno-2',
        name: 'Noturno 2',
        brandId: 'asfalto',
        brandName: 'Asfalto Club',
        category: DropCategory.sneakers,
        colorway: 'Tinta / Refletivo',
        description:
            'Segunda geração do tênis de corrida noturna do coletivo. '
            'O horário de abertura ainda não foi confirmado pela marca.',
        releaseAt: at(9, 0),
        hasTime: false,
        officialUrl: 'https://example.com/asfalto-club/noturno-2',
        art: DropArt.sneaker,
        tone: 4,
        createdAt: added(3),
        updatedAt: added(3),
      ),
      Drop(
        id: 'orla-mare-crossbody',
        name: 'Maré Crossbody',
        brandId: 'orla',
        brandName: 'Orla Norte',
        category: DropCategory.accessories,
        colorway: 'Gelo',
        description:
            'Bolsa transversal em lona náutica reaproveitada, com fecho '
            'magnético e alça regulável. Cabe carteira, chaves e celular.',
        price: 329,
        releaseAt: at(12, 11),
        hasTime: true,
        // Link malformado de propósito: exercita o tratamento de URL inválida.
        officialUrl: 'orla-norte/mare',
        featured: true,
        art: DropArt.bag,
        tone: 2,
        createdAt: added(1),
        updatedAt: added(1),
      ),
      Drop(
        id: 'monofase-moletom-tinta',
        name: "Moletom 'Tinta'",
        brandId: 'monofase',
        brandName: 'Monofase',
        category: DropCategory.apparel,
        colorway: 'Tinta',
        description:
            'O moletom fechado da casa na cor da próxima coleção: um preto '
            'azulado, tingido em tambor. Sem logo, sem etiqueta externa.',
        price: 399,
        releaseAt: at(20, 0),
        hasTime: false,
        officialUrl: 'https://example.com/monofase/moletom-tinta',
        art: DropArt.hoodie,
        tone: 4,
        createdAt: created,
        updatedAt: added(5),
      ),
      Drop(
        id: 'vertice-arco-02',
        name: "Arco 02 'Gelo'",
        brandId: 'vertice',
        brandName: 'Vértice',
        category: DropCategory.sneakers,
        colorway: 'Gelo / Branco',
        description:
            'A segunda cor do Arco: cabedal claro com painel azul-gelo e '
            'solado translúcido.',
        price: 949.9,
        releaseAt: at(30, 10),
        hasTime: true,
        officialUrl: 'https://example.com/vertice/arco-02',
        art: DropArt.sneaker,
        tone: 2,
        createdAt: added(1),
        updatedAt: added(1),
      ),
      Drop(
        id: 'vertice-viga-high',
        name: 'Viga High',
        brandId: 'vertice',
        brandName: 'Vértice',
        category: DropCategory.sneakers,
        colorway: 'Tinta',
        description:
            'Cano alto com reforço estrutural no tornozelo. A marca confirmou '
            'o modelo, mas ainda não anunciou data nem preço.',
        officialUrl: 'https://example.com/vertice/viga-high',
        art: DropArt.sneaker,
        tone: 4,
        createdAt: added(5),
        updatedAt: added(5),
      ),
      Drop(
        id: 'orla-cap-sal',
        name: 'Cap Sal',
        brandId: 'orla',
        brandName: 'Orla Norte',
        category: DropCategory.accessories,
        colorway: 'Osso',
        description:
            'Boné de cinco gomos em lona lavada com sal. Data a definir.',
        art: DropArt.cap,
        tone: 3,
        createdAt: added(8),
        updatedAt: added(8),
      ),
      Drop(
        id: 'cromo-bone-aro',
        name: 'Boné Aro',
        brandId: 'cromo',
        brandName: 'Cromo Lab',
        category: DropCategory.accessories,
        colorway: 'Prata',
        description:
            'Boné de aba curva com regulador metálico polido e ilhoses '
            'prateados.',
        price: 219,
        releaseAt: at(-4, 10),
        hasTime: true,
        officialUrl: 'https://example.com/cromo-lab/bone-aro',
        art: DropArt.cap,
        tone: 1,
        createdAt: created,
        updatedAt: added(4),
      ),
      Drop(
        id: 'kalt-neblina',
        name: 'Neblina Half-Zip',
        brandId: 'kalt',
        brandName: 'Kalt Atelier',
        category: DropCategory.apparel,
        colorway: 'Grafite',
        description:
            'Moletom de meio zíper com gola alta e bolso frontal embutido.',
        price: 629,
        releaseAt: at(-9, 12),
        hasTime: true,
        officialUrl: 'https://example.com/kalt-atelier/neblina',
        art: DropArt.hoodie,
        tone: 0,
        createdAt: created,
        updatedAt: added(9),
      ),
      Drop(
        id: 'asfalto-pista-400',
        name: 'Pista 400',
        brandId: 'asfalto',
        brandName: 'Asfalto Club',
        category: DropCategory.sneakers,
        colorway: 'Aço / Branco',
        description:
            'Tênis de treino com entressola alta e travas de borracha para '
            'pista molhada.',
        price: 749,
        releaseAt: at(-15, 8),
        hasTime: true,
        officialUrl: 'https://example.com/asfalto-club/pista-400',
        art: DropArt.sneaker,
        tone: 5,
        createdAt: created,
        updatedAt: added(15),
      ),
    ];
  }
}
