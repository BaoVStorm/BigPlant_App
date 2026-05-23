import 'models/shop_product.dart';

class LocalShopCatalog {
  static const ProductCategory indoorCategory = ProductCategory(
    id: 1,
    name: 'Trong nhà',
    slug: 'indoor-plants',
    description: 'Plant collection for bright interior corners.',
    isActive: true,
    sortOrder: 0,
  );

  static const ProductCategory outdoorCategory = ProductCategory(
    id: 2,
    name: 'Ngoài trời',
    slug: 'outdoor-plants',
    description: 'Outdoor-ready plant collection.',
    isActive: true,
    sortOrder: 1,
  );

  static const ProductCategory cactusCategory = ProductCategory(
    id: 3,
    name: 'Xương rồng',
    slug: 'cacti-succulents',
    description: 'Succulents and cactus forms.',
    isActive: true,
    sortOrder: 2,
  );

  static const ProductCategory ornamentalCategory = ProductCategory(
    id: 4,
    name: 'Cây cảnh',
    slug: 'ornamental-plants',
    description: 'Decorative statement foliage.',
    isActive: true,
    sortOrder: 3,
  );

  static const ProductCategory hydroCategory = ProductCategory(
    id: 5,
    name: 'Thủy sinh',
    slug: 'aquatic-plants',
    description: 'Aquatic and hydro display plants.',
    isActive: true,
    sortOrder: 4,
  );

  static const List<ProductCategory> categories = [
    indoorCategory,
    outdoorCategory,
    cactusCategory,
    ornamentalCategory,
    hydroCategory,
  ];

  static final List<ShopProduct> products = [
    _monstera(),
    _fiddleLeafFig(),
    _snakePlant(),
    _aloeVera(),
    _goldenPothos(),
    _peaceLily(),
    _jadePlant(),
    _spiderPlant(),
    _calatheaOrbifolia(),
    _rubberPlant(),
    _bostonFern(),
    _zzPlant(),
  ];

  static List<ShopProduct> productsForCategory(String categorySlug) {
    if (categorySlug == 'all')
      return products.where((item) => item.isActive).toList();
    return products
        .where((item) => item.isActive && item.category?.slug == categorySlug)
        .toList();
  }

  static List<ShopProduct> pageItems({
    required String categorySlug,
    required int page,
    required int pageSize,
  }) {
    final items = productsForCategory(categorySlug);
    final start = page * pageSize;
    if (start >= items.length) return const [];
    final end = (start + pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  static int totalPages({required String categorySlug, required int pageSize}) {
    final length = productsForCategory(categorySlug).length;
    return (length / pageSize).ceil().clamp(1, 999);
  }

  static ShopProduct bySlug(String slug) =>
      products.firstWhere((item) => item.slug == slug);

  static ShopProduct _monstera() {
    const plant = LinkedPlantSnapshot(
      plantId: 101,
      scientificName: 'Monstera Planto',
      commonName: 'Swiss cheese plant',
      family: 'Araceae',
      taxonomicOrder: 'Alismatales',
      genus: 'Monstera',
      species: 'M. deliciosa',
      taxonomicStatus: 'accepted',
      description:
          'Native to the tropical rainforests of southern Mexico and Central America, the Monstera Planto is famous for its natural fenestrations and structural presence indoors.',
      toxicityWarning: 'Mildly toxic to pets and humans if ingested.',
    );

    final variants = [
      const ProductVariant(
        id: 1,
        productId: 'prod_monstera',
        variantSku: 'MON-DEL-01-S-WHT',
        variantName: 'Small',
        attributes: {
          'size_label': 'Small',
          'size_subtitle': '4" Pot',
          'pot_style': 'White Ceramic',
          'water_need': 'Moderate Water',
          'light_need': 'Bright Indirect',
          'care_badge': 'Easy Care',
        },
        price: 45,
        compareAtPrice: 60,
        weightGram: 1200,
        isDefault: true,
        isActive: true,
      ),
      const ProductVariant(
        id: 2,
        productId: 'prod_monstera',
        variantSku: 'MON-DEL-01-M-WHT',
        variantName: 'Medium',
        attributes: {
          'size_label': 'Medium',
          'size_subtitle': '6" Pot',
          'pot_style': 'White Ceramic',
          'water_need': 'Moderate Water',
          'light_need': 'Bright Indirect',
          'care_badge': 'Easy Care',
        },
        price: 60,
        compareAtPrice: 75,
        weightGram: 1800,
        isDefault: false,
        isActive: true,
      ),
      const ProductVariant(
        id: 3,
        productId: 'prod_monstera',
        variantSku: 'MON-DEL-01-L-WHT',
        variantName: 'Large',
        attributes: {
          'size_label': 'Large',
          'size_subtitle': '8" Pot',
          'pot_style': 'White Ceramic',
          'water_need': 'Moderate Water',
          'light_need': 'Bright Indirect',
          'care_badge': 'Easy Care',
        },
        price: 82,
        compareAtPrice: 98,
        weightGram: 2600,
        isDefault: false,
        isActive: true,
      ),
      const ProductVariant(
        id: 4,
        productId: 'prod_monstera',
        variantSku: 'MON-DEL-01-S-TER',
        variantName: 'Small',
        attributes: {
          'size_label': 'Small',
          'size_subtitle': '4" Pot',
          'pot_style': 'Terracotta',
          'water_need': 'Moderate Water',
          'light_need': 'Bright Indirect',
          'care_badge': 'Easy Care',
        },
        price: 42,
        compareAtPrice: 58,
        weightGram: 1180,
        isDefault: false,
        isActive: true,
      ),
      const ProductVariant(
        id: 5,
        productId: 'prod_monstera',
        variantSku: 'MON-DEL-01-M-TER',
        variantName: 'Medium',
        attributes: {
          'size_label': 'Medium',
          'size_subtitle': '6" Pot',
          'pot_style': 'Terracotta',
          'water_need': 'Moderate Water',
          'light_need': 'Bright Indirect',
          'care_badge': 'Easy Care',
        },
        price: 56,
        compareAtPrice: 70,
        weightGram: 1760,
        isDefault: false,
        isActive: true,
      ),
      const ProductVariant(
        id: 6,
        productId: 'prod_monstera',
        variantSku: 'MON-DEL-01-L-CHR',
        variantName: 'Large',
        attributes: {
          'size_label': 'Large',
          'size_subtitle': '8" Pot',
          'pot_style': 'Charcoal',
          'water_need': 'Moderate Water',
          'light_need': 'Bright Indirect',
          'care_badge': 'Easy Care',
        },
        price: 86,
        compareAtPrice: 102,
        weightGram: 2680,
        isDefault: false,
        isActive: true,
      ),
    ];

    final images = [
      const ProductImage(
        imageId: 'img_monstera_1',
        productId: 'prod_monstera',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDTkDJZ65C_gOFr46Orn1y4lMOB6WVPRDGbL5J4dTNkwu-e2hDqnmhvEyv0HEN_4N0y1udkUZSQKWexIatkorO1RlfCQA0L4L2Y91C9EToNwdI3e75VRGjytIDEEQD4vmp0PPa44ZrIUuJXJlza3IJBleuvdDYymMAHeaNMVvOYivElGUSMx9MJ1lTJ0QTl9UZkqtUg1KV3xBzQIsBMu31XxpU9jL-BU0oxcswYoQdhIeChamNvvSZXkeopF3v2r418QxzGFmWnQe2m',
        altText: 'Main view of Monstera Planto plant in a modern white pot.',
        sortOrder: 0,
        isPrimary: true,
      ),
      const ProductImage(
        imageId: 'img_monstera_2',
        productId: 'prod_monstera',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDss3O_KIvPLvNFpUEgYsu6iid6jerTMP046A7I6D1lWdfgZxDddFahqscgnsWMxCfzZClG4QP3i1BPrU7HxFvM5tKOn29cZKxqjy_BB1mFfrYphdqDDZHZNr9cYgNYHHoUkAqDmRMtfSafuC0VeuhfqAwNfXScgOANwqrofUPVfy5vYMcAQtiJm1hi9E2MM4z4uHb6zoVCmc_EQ9O_SSjx5USpbklHW9eRyt1XMyxEZ603G8ha-sVLtx_a_r-x5Ks8UMhtsjxCuszt',
        altText: 'Monstera Planto leaf close-up.',
        sortOrder: 1,
        isPrimary: false,
      ),
      const ProductImage(
        imageId: 'img_monstera_3',
        productId: 'prod_monstera',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAtTHjrdNRKdnOPALhsuzPa2Hmk5TZ_Fnz6DJmWhgc2juIlX6madD6wYhjMI2eVdQQ2ypf7DKlkHLZ0UPkooA6n7vXPTNaucuCSeQGOf0D9CyqM4zjrGKj8XoaR8Ut_maDpHgz099S5u-4nuEB9CorMfNTigbCBQ4i3GSLts_vdN2PLluenK2sVrJmRsEgZhTe65Mkt5K2ACrOF_kF9E037qDL4jGCeW9rfsbPZQtcMwMY5HubnFcDVmS4rMGdyFmjZNPR80TYH8GqG',
        altText: 'Monstera Planto in detail.',
        sortOrder: 2,
        isPrimary: false,
      ),
      const ProductImage(
        imageId: 'img_monstera_4',
        productId: 'prod_monstera',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuApfT7uGuul0l8AbwNPkuyACvj2bryQ_4jc-ABZnD_zL8rm8zHlUMzbpik2Z8NHBTwD7BqqnkLtJp0c-bIcVfPaH3wmI8aznWh9wgjzTkL7ZxgvAQrJjMF_VVavlMgkCIhaFdltr4ZlVkgPeUvErWpljEmC7YHowl8LoEEUyU1LBrnqn3y_gI6JOkCul7E2nztTqxQupt52Qfv6y8idsmFMThdiyuW5pWIqjoDyq3NNg5__a-h_DHQILD1R9f0RGptmWKUJoCU1ru4f',
        altText: 'Monstera Planto wide view.',
        sortOrder: 3,
        isPrimary: false,
      ),
    ];

    return ShopProduct(
      id: 'prod_monstera',
      categoryId: indoorCategory.id,
      plantId: plant.plantId,
      sku: 'MON-DEL-01',
      productType: ShopProductType.plant,
      name: 'Monstera Planto',
      slug: 'monstera-deliciosa',
      shortDescription:
          'Also known as the Swiss Cheese Plant, this iconic tropical beauty features large, glossy leaves with distinctive splits and holes.',
      description:
          'As an indoor plant, Monstera Planto grows relatively quickly and can become quite large, often requiring a moss pole or trellis for support as it climbs. It is an excellent air-purifying plant, removing indoor toxins while adding a dramatic structural green element to your decor.',
      careLevel: 'Easy Care',
      ratingAvg: 4.8,
      ratingCount: 124,
      isActive: true,
      category: indoorCategory,
      variants: variants,
      images: images,
      linkedPlant: plant,
    );
  }

  static ShopProduct _fiddleLeafFig() => _simpleProduct(
    id: 'prod_fiddle_leaf',
    plantId: 102,
    sku: 'FID-LYR-01',
    name: 'Fiddle Leaf Fig',
    slug: 'fiddle-leaf-fig',
    category: indoorCategory,
    shortDescription:
        'Broad violin-shaped foliage for bright interior corners.',
    description:
        'A sculptural indoor tree prized for glossy oversized leaves and architectural silhouette.',
    careLevel: 'Bright Indirect',
    ratingAvg: 4.7,
    ratingCount: 88,
    price: 45,
    comparePrice: 58,
    waterNeed: 'Moderate Water',
    lightNeed: 'Bright Indirect',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDIrVnZtStA7jVgJjst7q-4vNcW5ygVI0w2Q3hp3ws8I8gudhhrqB-xXsHP3avUIhAL826QjFhxVRjXrMF-tm_q1ivlwmnvMQooxf50euQ_lW6Mf76U8V3tHWVVL4YREpaPsaWj5ZpLrsYAVnLfDPxbnFsNmjgAbA0iiESN-3ksz1_Suo5mFphC49o1cD4dnfde5OH6IxlnEaWmqxjeO8S5eiZ8cKhtG0YLH7D32AjyydlHlQFfYpaR4jqPC-nGj-p12CpkcJHvi3Oy',
    scientificName: 'Ficus lyrata',
    commonName: 'Fiddle leaf fig',
    family: 'Moraceae',
    order: 'Rosales',
    genus: 'Ficus',
    species: 'F. lyrata',
    toxicity: 'Mildly toxic to pets when chewed.',
  );

  static ShopProduct _snakePlant() => _simpleProduct(
    id: 'prod_snake_plant',
    plantId: 103,
    sku: 'SNK-TRI-01',
    name: 'Snake Plant',
    slug: 'snake-plant',
    category: ornamentalCategory,
    shortDescription:
        'Structured upright foliage with durable, easy-going care habits.',
    description:
        'An adaptable, drought-tolerant houseplant known for resilience and sculptural striped leaves.',
    careLevel: 'Easy Care',
    ratingAvg: 4.8,
    ratingCount: 96,
    price: 18,
    comparePrice: 26,
    waterNeed: 'Low Water',
    lightNeed: 'Flexible Light',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCfyNmN-hPF9KdYroKXlLCAOtfgr87ULnM_yFxaTBgjqg0r6bwcEhmK0Ja-GFCpI-RBnR3bE5BnwpeN1ZaURmtGV3SvdbhpsIxEVWLpCxgfpfK0CbpRlZSpkMMEzdbXhogESmY7IvhH6YtTgAF3RsW0C3htq0wja-no2vxcbqhp67SayzgV5gpWKMpBPOOxNmHdC4y0LL4vGSzJyvm06-3SDyFTJHoGTtWz9qvA9eRcc71rBrKQym8Q1WqUXXOyIxdFuncu00ktkc3d',
    scientificName: 'Dracaena trifasciata',
    commonName: 'Snake plant',
    family: 'Asparagaceae',
    order: 'Asparagales',
    genus: 'Dracaena',
    species: 'D. trifasciata',
    toxicity: 'Mildly toxic to pets when ingested.',
  );

  static ShopProduct _aloeVera() => _simpleProduct(
    id: 'prod_aloe_vera',
    plantId: 104,
    sku: 'ALO-VER-01',
    name: 'Aloe Vera',
    slug: 'aloe-vera',
    category: cactusCategory,
    shortDescription:
        'Medicinal succulent with fleshy leaves and sun-loving form.',
    description:
        'Aloe vera stores water in thick leaves, making it ideal for bright windows and low-maintenance routines.',
    careLevel: 'Sun Friendly',
    ratingAvg: 4.5,
    ratingCount: 64,
    price: 12,
    comparePrice: 18,
    waterNeed: 'Low Water',
    lightNeed: 'Bright Sun',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCaE3Jaoq6a9wZ2afe5ktz5NSfIQW6Qhu4BlQXXDTLtjSYL3yGZh_yFWGRHacLGQCqrjQfyOXcnet5MCf5pat3yHEFV6TGgnNT_i2TU0z1WiWPW5X-592KjpSsqT8vAGHn8Y46RkLIdVWBPG44JU4ZB4nl61V7UrGavi8TwKDBxvloLee7dfJpSLfjAWaydlKinUsL-PyxPFqEDIXI5SMbFQo0nPppy9RqmrwxQ44WKXPZkWNNHeNIo-yY5ZP1STWJI5TJ-rTHwz88N',
    scientificName: 'Aloe vera',
    commonName: 'Aloe vera',
    family: 'Asphodelaceae',
    order: 'Asparagales',
    genus: 'Aloe',
    species: 'A. vera',
    toxicity: 'Gel is useful, but latex can irritate pets and humans.',
  );

  static ShopProduct _goldenPothos() => _simpleProduct(
    id: 'prod_golden_pothos',
    plantId: 105,
    sku: 'GOL-POT-01',
    name: 'Golden Pothos',
    slug: 'golden-pothos',
    category: indoorCategory,
    shortDescription:
        'Trailing vine with forgiving care and vivid marbled leaves.',
    description:
        'Golden pothos is a versatile trailing houseplant ideal for shelves, hanging baskets, and training up poles.',
    careLevel: 'Easy Care',
    ratingAvg: 4.6,
    ratingCount: 73,
    price: 15,
    comparePrice: 22,
    waterNeed: 'Moderate Water',
    lightNeed: 'Bright Indirect',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBkaW9koNxaFpE84Jxmo1sk1S3s2BTWEmw0FP5YbLo8MVJRW9PVWdEKD63Ly719fcY4i6iNR9bFmbTAqZr6wzNhKpXVJOHQ7AUp61hT657isz4deuRp7SHL9EfTTmsxvhxPbQvMiRcPL5X1K6U08DE1oRvuIlfirTj2LmmTEik0WsWmTm1yV9LGEhHooaABplJ_LQCG6Q2XCCmtvdA2GyL2ZIf5CrkYvUmzyvNFdMH8HCVN4pKg2M0w2zUhWUDRdgKp9T3rZ8cm1tbZ',
    scientificName: 'Epipremnum aureum',
    commonName: 'Golden pothos',
    family: 'Araceae',
    order: 'Alismatales',
    genus: 'Epipremnum',
    species: 'E. aureum',
    toxicity: 'Toxic to pets if ingested.',
  );

  static ShopProduct _peaceLily() => _simpleProduct(
    id: 'prod_peace_lily',
    plantId: 106,
    sku: 'PEA-LIL-01',
    name: 'Peace Lily',
    slug: 'peace-lily',
    category: outdoorCategory,
    shortDescription: 'Elegant white blooms paired with deep green leaves.',
    description:
        'Peace lilies thrive in filtered light and are loved for their calm silhouette and flowering habit.',
    careLevel: 'Balanced Care',
    ratingAvg: 4.4,
    ratingCount: 58,
    price: 22,
    comparePrice: 29,
    waterNeed: 'Even Moisture',
    lightNeed: 'Medium Light',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDIrVnZtStA7jVgJjst7q-4vNcW5ygVI0w2Q3hp3ws8I8gudhhrqB-xXsHP3avUIhAL826QjFhxVRjXrMF-tm_q1ivlwmnvMQooxf50euQ_lW6Mf76U8V3tHWVVL4YREpaPsaWj5ZpLrsYAVnLfDPxbnFsNmjgAbA0iiESN-3ksz1_Suo5mFphC49o1cD4dnfde5OH6IxlnEaWmqxjeO8S5eiZ8cKhtG0YLH7D32AjyydlHlQFfYpaR4jqPC-nGj-p12CpkcJHvi3Oy',
    scientificName: 'Spathiphyllum wallisii',
    commonName: 'Peace lily',
    family: 'Araceae',
    order: 'Alismatales',
    genus: 'Spathiphyllum',
    species: 'S. wallisii',
    toxicity: 'Toxic to pets if chewed or eaten.',
  );

  static ShopProduct _jadePlant() => _simpleProduct(
    id: 'prod_jade_plant',
    plantId: 107,
    sku: 'JAD-PLA-01',
    name: 'Jade Plant',
    slug: 'jade-plant',
    category: ornamentalCategory,
    shortDescription:
        'Compact succulent with dense branching and glossy rounded leaves.',
    description:
        'A beloved tabletop succulent associated with longevity and easy indoor care.',
    careLevel: 'Easy Care',
    ratingAvg: 4.9,
    ratingCount: 102,
    price: 28,
    comparePrice: 36,
    waterNeed: 'Low Water',
    lightNeed: 'Bright Sun',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCfyNmN-hPF9KdYroKXlLCAOtfgr87ULnM_yFxaTBgjqg0r6bwcEhmK0Ja-GFCpI-RBnR3bE5BnwpeN1ZaURmtGV3SvdbhpsIxEVWLpCxgfpfK0CbpRlZSpkMMEzdbXhogESmY7IvhH6YtTgAF3RsW0C3htq0wja-no2vxcbqhp67SayzgV5gpWKMpBPOOxNmHdC4y0LL4vGSzJyvm06-3SDyFTJHoGTtWz9qvA9eRcc71rBrKQym8Q1WqUXXOyIxdFuncu00ktkc3d',
    scientificName: 'Crassula ovata',
    commonName: 'Jade plant',
    family: 'Crassulaceae',
    order: 'Saxifragales',
    genus: 'Crassula',
    species: 'C. ovata',
    toxicity: 'Toxic to pets if ingested.',
  );

  static ShopProduct _spiderPlant() => _simpleProduct(
    id: 'prod_spider_plant',
    plantId: 108,
    sku: 'SPI-PLA-01',
    name: 'Spider Plant',
    slug: 'spider-plant',
    category: ornamentalCategory,
    shortDescription:
        'Arching green-and-cream leaves with prolific baby plantlets.',
    description:
        'Spider plants are forgiving and ideal for hanging displays in bright, indirect light.',
    careLevel: 'Easy Care',
    ratingAvg: 4.3,
    ratingCount: 41,
    price: 14,
    comparePrice: 20,
    waterNeed: 'Moderate Water',
    lightNeed: 'Bright Indirect',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCaE3Jaoq6a9wZ2afe5ktz5NSfIQW6Qhu4BlQXXDTLtjSYL3yGZh_yFWGRHacLGQCqrjQfyOXcnet5MCf5pat3yHEFV6TGgnNT_i2TU0z1WiWPW5X-592KjpSsqT8vAGHn8Y46RkLIdVWBPG44JU4ZB4nl61V7UrGavi8TwKDBxvloLee7dfJpSLfjAWaydlKinUsL-PyxPFqEDIXI5SMbFQo0nPppy9RqmrwxQ44WKXPZkWNNHeNIo-yY5ZP1STWJI5TJ-rTHwz88N',
    scientificName: 'Chlorophytum comosum',
    commonName: 'Spider plant',
    family: 'Asparagaceae',
    order: 'Asparagales',
    genus: 'Chlorophytum',
    species: 'C. comosum',
    toxicity: 'Non-toxic and pet friendly.',
  );

  static ShopProduct _calatheaOrbifolia() => _simpleProduct(
    id: 'prod_calathea',
    plantId: 109,
    sku: 'CAL-ORB-01',
    name: 'Calathea Orbifolia',
    slug: 'calathea-orbifolia',
    category: indoorCategory,
    shortDescription: 'Broad striped leaves with a velvety tropical presence.',
    description:
        'A humidity-loving foliage plant known for wide, painterly leaves and refined indoor character.',
    careLevel: 'Humidity Loving',
    ratingAvg: 4.7,
    ratingCount: 52,
    price: 32,
    comparePrice: 40,
    waterNeed: 'Even Moisture',
    lightNeed: 'Soft Indirect',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBkaW9koNxaFpE84Jxmo1sk1S3s2BTWEmw0FP5YbLo8MVJRW9PVWdEKD63Ly719fcY4i6iNR9bFmbTAqZr6wzNhKpXVJOHQ7AUp61hT657isz4deuRp7SHL9EfTTmsxvhxPbQvMiRcPL5X1K6U08DE1oRvuIlfirTj2LmmTEik0WsWmTm1yV9LGEhHooaABplJ_LQCG6Q2XCCmtvdA2GyL2ZIf5CrkYvUmzyvNFdMH8HCVN4pKg2M0w2zUhWUDRdgKp9T3rZ8cm1tbZ',
    scientificName: 'Calathea orbifolia',
    commonName: 'Calathea orbifolia',
    family: 'Marantaceae',
    order: 'Zingiberales',
    genus: 'Calathea',
    species: 'C. orbifolia',
    toxicity: 'Generally considered non-toxic to pets.',
  );

  static ShopProduct _rubberPlant() => _simpleProduct(
    id: 'prod_rubber_plant',
    plantId: 110,
    sku: 'RUB-PLA-01',
    name: 'Rubber Plant',
    slug: 'rubber-plant',
    category: indoorCategory,
    shortDescription:
        'Glossy leaves and upright growth with a polished architectural form.',
    description:
        'A bold, low-fuss plant with thick leaves that bring depth to modern interiors.',
    careLevel: 'Moderate Care',
    ratingAvg: 4.5,
    ratingCount: 49,
    price: 30,
    comparePrice: 38,
    waterNeed: 'Moderate Water',
    lightNeed: 'Bright Indirect',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDIrVnZtStA7jVgJjst7q-4vNcW5ygVI0w2Q3hp3ws8I8gudhhrqB-xXsHP3avUIhAL826QjFhxVRjXrMF-tm_q1ivlwmnvMQooxf50euQ_lW6Mf76U8V3tHWVVL4YREpaPsaWj5ZpLrsYAVnLfDPxbnFsNmjgAbA0iiESN-3ksz1_Suo5mFphC49o1cD4dnfde5OH6IxlnEaWmqxjeO8S5eiZ8cKhtG0YLH7D32AjyydlHlQFfYpaR4jqPC-nGj-p12CpkcJHvi3Oy',
    scientificName: 'Ficus elastica',
    commonName: 'Rubber plant',
    family: 'Moraceae',
    order: 'Rosales',
    genus: 'Ficus',
    species: 'F. elastica',
    toxicity: 'Sap may irritate skin and is mildly toxic to pets.',
  );

  static ShopProduct _bostonFern() => _simpleProduct(
    id: 'prod_boston_fern',
    plantId: 111,
    sku: 'BOS-FER-01',
    name: 'Boston Fern',
    slug: 'boston-fern',
    category: hydroCategory,
    shortDescription: 'Soft feathery fronds for humid, shaded corners.',
    description:
        'Boston ferns enjoy consistent moisture and high humidity, making them ideal bathroom or patio companions.',
    careLevel: 'Humidity Loving',
    ratingAvg: 4.2,
    ratingCount: 35,
    price: 19,
    comparePrice: 25,
    waterNeed: 'High Moisture',
    lightNeed: 'Filtered Light',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCfyNmN-hPF9KdYroKXlLCAOtfgr87ULnM_yFxaTBgjqg0r6bwcEhmK0Ja-GFCpI-RBnR3bE5BnwpeN1ZaURmtGV3SvdbhpsIxEVWLpCxgfpfK0CbpRlZSpkMMEzdbXhogESmY7IvhH6YtTgAF3RsW0C3htq0wja-no2vxcbqhp67SayzgV5gpWKMpBPOOxNmHdC4y0LL4vGSzJyvm06-3SDyFTJHoGTtWz9qvA9eRcc71rBrKQym8Q1WqUXXOyIxdFuncu00ktkc3d',
    scientificName: 'Nephrolepis exaltata',
    commonName: 'Boston fern',
    family: 'Nephrolepidaceae',
    order: 'Polypodiales',
    genus: 'Nephrolepis',
    species: 'N. exaltata',
    toxicity: 'Non-toxic to cats and dogs.',
  );

  static ShopProduct _zzPlant() => _simpleProduct(
    id: 'prod_zz_plant',
    plantId: 112,
    sku: 'ZZ-PLA-01',
    name: 'ZZ Plant',
    slug: 'zz-plant',
    category: indoorCategory,
    shortDescription:
        'Glossy upright stems for low-light corners and easy care routines.',
    description:
        'The ZZ Plant thrives on neglect, tolerates lower light, and stores moisture in rhizomes.',
    careLevel: 'Easy Care',
    ratingAvg: 4.8,
    ratingCount: 81,
    price: 26,
    comparePrice: 34,
    waterNeed: 'Low Water',
    lightNeed: 'Low to Bright Indirect',
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCaE3Jaoq6a9wZ2afe5ktz5NSfIQW6Qhu4BlQXXDTLtjSYL3yGZh_yFWGRHacLGQCqrjQfyOXcnet5MCf5pat3yHEFV6TGgnNT_i2TU0z1WiWPW5X-592KjpSsqT8vAGHn8Y46RkLIdVWBPG44JU4ZB4nl61V7UrGavi8TwKDBxvloLee7dfJpSLfjAWaydlKinUsL-PyxPFqEDIXI5SMbFQo0nPppy9RqmrwxQ44WKXPZkWNNHeNIo-yY5ZP1STWJI5TJ-rTHwz88N',
    scientificName: 'Zamioculcas zamiifolia',
    commonName: 'ZZ plant',
    family: 'Araceae',
    order: 'Alismatales',
    genus: 'Zamioculcas',
    species: 'Z. zamiifolia',
    toxicity: 'Toxic if ingested by pets or children.',
  );

  static ShopProduct _simpleProduct({
    required String id,
    required int plantId,
    required String sku,
    required String name,
    required String slug,
    required ProductCategory category,
    required String shortDescription,
    required String description,
    required String careLevel,
    required double ratingAvg,
    required int ratingCount,
    required double price,
    required double comparePrice,
    required String waterNeed,
    required String lightNeed,
    required String imageUrl,
    required String scientificName,
    required String commonName,
    required String family,
    required String order,
    required String genus,
    required String species,
    required String toxicity,
  }) {
    final plant = LinkedPlantSnapshot(
      plantId: plantId,
      scientificName: scientificName,
      commonName: commonName,
      family: family,
      taxonomicOrder: order,
      genus: genus,
      species: species,
      taxonomicStatus: 'accepted',
      description: description,
      toxicityWarning: toxicity,
    );

    final variant = ProductVariant(
      id: plantId,
      productId: id,
      variantSku: '$sku-DEF',
      variantName: 'Default',
      attributes: {
        'size_label': 'Standard',
        'size_subtitle': 'Nursery Pot',
        'pot_style': 'White Ceramic',
        'water_need': waterNeed,
        'light_need': lightNeed,
        'care_badge': careLevel,
      },
      price: price,
      compareAtPrice: comparePrice,
      weightGram: 1000,
      isDefault: true,
      isActive: true,
    );

    final image = ProductImage(
      imageId: 'img_$id',
      productId: id,
      imageUrl: imageUrl,
      altText: name,
      sortOrder: 0,
      isPrimary: true,
    );

    return ShopProduct(
      id: id,
      categoryId: category.id,
      plantId: plantId,
      sku: sku,
      productType: ShopProductType.plant,
      name: name,
      slug: slug,
      shortDescription: shortDescription,
      description: description,
      careLevel: careLevel,
      ratingAvg: ratingAvg,
      ratingCount: ratingCount,
      isActive: true,
      category: category,
      variants: [variant],
      images: [image],
      linkedPlant: plant,
    );
  }
}
