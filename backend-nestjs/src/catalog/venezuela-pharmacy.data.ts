/** Medicamentos comunes en farmacias venezolanas (además del catálogo CIMA). */
export interface SeedProductItem {
  sku: string;
  name: string;
  description: string;
  price: number;
  discountPercent?: number | null;
  imageUrl: string;
  categorySlug: 'farmacia';
  isFeatured: boolean;
}

export const VENEZUELAN_PHARMACY_PRODUCTS: SeedProductItem[] = [
  {
    sku: 'VE-FAR-001',
    name: 'Losartán 50 mg x30 comprimidos',
    description:
      'Antihipertensivo. Laboratorio venezolano. Indicado para control de la presión arterial. Consulte a su médico.',
    price: 8.5,
    discountPercent: 10,
    imageUrl:
      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600&auto=format&fit=crop',
    categorySlug: 'farmacia',
    isFeatured: true,
  },
  {
    sku: 'VE-FAR-002',
    name: 'Amoxicilina 500 mg x21 cápsulas',
    description:
      'Antibiótico de amplio espectro. Requiere receta médica. Tratamiento de infecciones bacterianas.',
    price: 12.0,
    discountPercent: null,
    imageUrl:
      'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=600&auto=format&fit=crop',
    categorySlug: 'farmacia',
    isFeatured: true,
  },
  {
    sku: 'VE-FAR-003',
    name: 'Omeprazol 20 mg x14 cápsulas',
    description:
      'Protector gástrico. Alivia acidez, reflujo y gastritis. Uso bajo indicación médica.',
    price: 6.75,
    discountPercent: 15,
    imageUrl:
      'https://images.unsplash.com/photo-1631549916762-40c9c2789f56?w=600&auto=format&fit=crop',
    categorySlug: 'farmacia',
    isFeatured: true,
  },
  {
    sku: 'VE-FAR-004',
    name: 'Loratadina 10 mg x10 comprimidos',
    description:
      'Antialérgico no sedante. Alivia estornudos, rinitis y picazón por alergias.',
    price: 4.2,
    discountPercent: null,
    imageUrl:
      'https://images.unsplash.com/photo-1587854692152-c104265145f5?w=600&auto=format&fit=crop',
    categorySlug: 'farmacia',
    isFeatured: false,
  },
  {
    sku: 'VE-FAR-005',
    name: 'Metformina 850 mg x30 comprimidos',
    description:
      'Antidiabético oral. Control de glucosa en pacientes con diabetes tipo 2. Prescripción médica.',
    price: 9.9,
    discountPercent: null,
    imageUrl:
      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600&auto=format&fit=crop',
    categorySlug: 'farmacia',
    isFeatured: false,
  },
  {
    sku: 'VE-FAR-006',
    name: 'Diclofenaco 100 mg x20 comprimidos',
    description:
      'Antiinflamatorio y analgésico. Para dolores musculares, articulares y inflamación.',
    price: 5.5,
    discountPercent: 10,
    imageUrl:
      'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=600&auto=format&fit=crop',
    categorySlug: 'farmacia',
    isFeatured: true,
  },
  {
    sku: 'VE-FAR-007',
    name: 'Salbutamol inhalador 100 mcg',
    description:
      'Broncodilatador. Alivia broncoespasmo y dificultad respiratoria en asma. Uso bajo supervisión médica.',
    price: 11.5,
    discountPercent: null,
    imageUrl:
      'https://images.unsplash.com/photo-1587854692152-c104265145f5?w=600&auto=format&fit=crop',
    categorySlug: 'farmacia',
    isFeatured: false,
  },
  {
    sku: 'VE-FAR-008',
    name: 'Complejo B x30 tabletas',
    description:
      'Suplemento vitamínico del complejo B. Apoya el sistema nervioso y combate la fatiga.',
    price: 3.8,
    discountPercent: null,
    imageUrl:
      'https://images.unsplash.com/photo-1631549916762-40c9c2789f56?w=600&auto=format&fit=crop',
    categorySlug: 'farmacia',
    isFeatured: false,
  },
  {
    sku: 'VE-FAR-009',
    name: 'Vitamina C 1 g x10 comprimidos efervescentes',
    description:
      'Refuerzo inmunológico. Sabor cítrico, fácil de disolver. Complemento vitamínico diario.',
    price: 4.5,
    discountPercent: 20,
    imageUrl:
      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600&auto=format&fit=crop',
    categorySlug: 'farmacia',
    isFeatured: true,
  },
  {
    sku: 'VE-FAR-010',
    name: 'Ketorolaco 10 mg x10 comprimidos sublinguales',
    description:
      'Analgésico de acción rápida para dolor moderado a intenso. Uso por tiempo limitado.',
    price: 7.25,
    discountPercent: null,
    imageUrl:
      'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=600&auto=format&fit=crop',
    categorySlug: 'farmacia',
    isFeatured: false,
  },
  {
    sku: 'VE-FAR-011',
    name: 'Hioscina 10 mg x20 comprimidos',
    description:
      'Antiespasmódico. Alivia cólicos abdominales y dolor estomacal. Consulte al farmacéutico.',
    price: 5.0,
    discountPercent: null,
    imageUrl:
      'https://images.unsplash.com/photo-1587854692152-c104265145f5?w=600&auto=format&fit=crop',
    categorySlug: 'farmacia',
    isFeatured: false,
  },
  {
    sku: 'VE-FAR-012',
    name: 'Alcohol antiséptico 70% 120 ml',
    description:
      'Antiséptico tópico para desinfección de piel y superficies. Uso externo.',
    price: 2.1,
    discountPercent: null,
    imageUrl:
      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600&auto=format&fit=crop',
    categorySlug: 'farmacia',
    isFeatured: false,
  },
];
