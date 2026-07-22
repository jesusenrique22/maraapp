import {
  BannerPlacement,
  PrismaClient,
  UserRole,
  InventoryMovementType,
} from '@prisma/client';
import * as bcrypt from 'bcrypt';
import {
  getDefaultSeedBakery,
  getDefaultSeedBeverages,
} from '../src/catalog/catalog-client';
import { VENEZUELAN_PHARMACY_PRODUCTS } from '../src/catalog/venezuela-pharmacy.data';

const prisma = new PrismaClient();

/** Renombra email legacy si el destino aún no existe. */
async function migrateLegacyEmail(from: string, to: string) {
  if (!from || !to || from === to) return;
  const legacy = await prisma.user.findUnique({ where: { email: from } });
  if (!legacy) return;
  const target = await prisma.user.findUnique({ where: { email: to } });
  if (target) {
    await prisma.user.update({
      where: { id: legacy.id },
      data: { isActive: false },
    });
    return;
  }
  await prisma.user.update({
    where: { id: legacy.id },
    data: { email: to },
  });
}

async function main() {
  const adminEmail = process.env.ADMIN_EMAIL ?? 'admin@farmaexpress.com';
  const adminPassword = process.env.ADMIN_PASSWORD ?? 'Admin123!';
  const hashedPassword = await bcrypt.hash(adminPassword, 10);

  // Migrar email legacy @maraplus.com → @farmaexpress.com si aplica
  await migrateLegacyEmail('admin@maraplus.com', adminEmail);

  const admin = await prisma.user.upsert({
    where: { email: adminEmail },
    update: {
      name: 'Administrador Farma Express',
      password: hashedPassword,
      role: UserRole.ADMIN,
      isActive: true,
    },
    create: {
      email: adminEmail,
      password: hashedPassword,
      name: 'Administrador Farma Express',
      role: UserRole.ADMIN,
    },
  });

  // Limpiar nombres viejos de marca en cualquier usuario
  const brandedUsers = await prisma.user.findMany({
    where: {
      OR: [
        { name: { contains: 'MaraPlus', mode: 'insensitive' } },
        { name: { contains: 'Maraplus', mode: 'insensitive' } },
      ],
    },
    select: { id: true, name: true },
  });
  for (const u of brandedUsers) {
    await prisma.user.update({
      where: { id: u.id },
      data: {
        name: u.name
          .replace(/MaraPlus/gi, 'Farma Express')
          .replace(/Maraplus/gi, 'Farma Express'),
      },
    });
  }

  // Seed Doctor
  const doctorEmail = 'doctor@farmaexpress.com';
  await migrateLegacyEmail('doctor@maraplus.com', doctorEmail);
  const doctorPassword = 'Doctor123!';
  const hashedDoctorPassword = await bcrypt.hash(doctorPassword, 10);

  const doctorUser = await prisma.user.upsert({
    where: { email: doctorEmail },
    update: {
      name: 'Dr. Juan Pérez',
      password: hashedDoctorPassword,
      role: UserRole.DOCTOR,
      isActive: true,
    },
    create: {
      email: doctorEmail,
      password: hashedDoctorPassword,
      name: 'Dr. Juan Pérez',
      role: UserRole.DOCTOR,
    },
  });

  const doctorProfile = await prisma.doctorProfile.upsert({
    where: { userId: doctorUser.id },
    update: {
      specialty: 'Cardiología y Medicina General',
      bio: 'Especialista en cuidado cardiovascular y atención médica primaria con más de 10 años de experiencia. Disponible vía Medic Plus en Farma Express.',
      consultationFee: 25.0,
      isActive: true,
    },
    create: {
      userId: doctorUser.id,
      specialty: 'Cardiología y Medicina General',
      bio: 'Especialista en cuidado cardiovascular y atención médica primaria con más de 10 años de experiencia. Disponible vía Medic Plus en Farma Express.',
      consultationFee: 25.0,
    },
  });

  const extraDoctors = [
    {
      email: 'doctor2@farmaexpress.com',
      legacyEmail: 'doctor2@maraplus.com',
      password: 'Doctor123!',
      name: 'Dra. María González',
      specialty: 'Pediatría',
      bio: 'Pediatra con enfoque en control de niños sanos, vacunas y seguimiento del desarrollo. Medic Plus · Farma Express.',
      fee: 22.0,
    },
    {
      email: 'doctor3@farmaexpress.com',
      legacyEmail: 'doctor3@maraplus.com',
      password: 'Doctor123!',
      name: 'Dr. Roberto Silva',
      specialty: 'Dermatología',
      bio: 'Especialista en dermatología clínica, acné, alergias cutáneas y cuidado de la piel. Medic Plus · Farma Express.',
      fee: 28.0,
    },
  ];

  for (const doctor of extraDoctors) {
    await migrateLegacyEmail(doctor.legacyEmail, doctor.email);
    const hashed = await bcrypt.hash(doctor.password, 10);
    const user = await prisma.user.upsert({
      where: { email: doctor.email },
      update: {
        name: doctor.name,
        password: hashed,
        role: UserRole.DOCTOR,
        isActive: true,
      },
      create: {
        email: doctor.email,
        password: hashed,
        name: doctor.name,
        role: UserRole.DOCTOR,
      },
    });

    await prisma.doctorProfile.upsert({
      where: { userId: user.id },
      update: {
        specialty: doctor.specialty,
        bio: doctor.bio,
        consultationFee: doctor.fee,
        isActive: true,
      },
      create: {
        userId: user.id,
        specialty: doctor.specialty,
        bio: doctor.bio,
        consultationFee: doctor.fee,
      },
    });
  }

  // Seed Patient
  const patientEmail = 'patient@farmaexpress.com';
  await migrateLegacyEmail('patient@maraplus.com', patientEmail);
  const patientPassword = 'Patient123!';
  const hashedPatientPassword = await bcrypt.hash(patientPassword, 10);

  const patientUser = await prisma.user.upsert({
    where: { email: patientEmail },
    update: {
      name: 'Carlos Mendoza (Paciente)',
      password: hashedPatientPassword,
      role: UserRole.CUSTOMER,
      isActive: true,
    },
    create: {
      email: patientEmail,
      password: hashedPatientPassword,
      name: 'Carlos Mendoza (Paciente)',
      role: UserRole.CUSTOMER,
    },
  });

  const categories = [
    {
      name: 'Farmacia',
      slug: 'farmacia',
      description: 'Medicamentos, cuidado personal y salud',
      sortOrder: 1,
      isActive: true,
    },
    {
      name: 'Panadería',
      slug: 'panaderia',
      description: 'Pan fresco, pasteles y repostería',
      sortOrder: 2,
      isActive: true,
    },
    {
      name: 'Charcutería',
      slug: 'charcuteria',
      description: 'Embutidos, quesos y fiambres',
      sortOrder: 3,
      isActive: true,
    },
    {
      name: 'Bodegón',
      slug: 'bodegon',
      description: 'Abarrotes, bebidas y consumo diario',
      sortOrder: 4,
      isActive: true,
    },
    {
      name: 'Alimentos y bebidas',
      slug: 'alimentos-bebidas',
      description: 'Productos de consumo diario',
      sortOrder: 5,
      isActive: true,
    },
    {
      name: 'Mascotas',
      slug: 'mascotas',
      description: 'Categoría desactivada — no forma parte de Farma Express',
      sortOrder: 99,
      isActive: false,
    },
  ];

  const categoryMap = new Map<string, string>();

  for (const category of categories) {
    const saved = await prisma.category.upsert({
      where: { slug: category.slug },
      update: category,
      create: category,
    });
    categoryMap.set(category.slug, saved.id);
  }

  const branches = [
    {
      name: 'Farma Express Indio Mara',
      slug: 'indio-mara',
      address: 'Indio Mara, Maracaibo',
      city: 'Maracaibo',
      state: 'Zulia',
      phone: '+58 261-555-0101',
      whatsapp: '+58 414-555-0101',
      openingHours: 'Abierto 24 horas',
      isMain: true,
      isActive: true,
      sortOrder: 1,
      latitude: 10.6666,
      longitude: -71.6125,
    },
    {
      name: 'Farma Express Bella Vista',
      slug: 'bella-vista',
      address: 'Bella Vista, Maracaibo',
      city: 'Maracaibo',
      state: 'Zulia',
      phone: '+58 261-555-0102',
      whatsapp: '+58 414-555-0102',
      openingHours: 'Abierto 24 horas',
      isMain: false,
      isActive: true,
      sortOrder: 2,
      latitude: 10.6689,
      longitude: -71.6081,
    },
  ];

  const branchMap = new Map<string, string>();
  const activeBranchSlugs = branches.map((b) => b.slug);
  for (const branch of branches) {
    const saved = await prisma.branch.upsert({
      where: { slug: branch.slug },
      update: branch,
      create: branch,
    });
    branchMap.set(branch.slug, saved.id);
  }

  // Desactivar sucursales que no son Farma Express
  await prisma.branch.updateMany({
    where: { slug: { notIn: activeBranchSlugs } },
    data: { isActive: false },
  });

  // Rename leftover MaraPlus branch names if somehow still active
  await prisma.branch.updateMany({
    where: { name: { contains: 'MaraPlus', mode: 'insensitive' } },
    data: { isActive: false },
  });

  const products = [
    {
      sku: 'FAR-001',
      name: 'Acetaminofén 500mg x20',
      description: 'Analgésico y antipirético de venta libre. Alivia dolor leve y fiebre.',
      price: 4.5,
      discountPercent: 15,
      imageUrl:
        'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600&auto=format&fit=crop',
      categorySlug: 'farmacia',
      isFeatured: true,
    },
    {
      sku: 'FAR-002',
      name: 'Ibuprofeno 400mg x24',
      description: 'Antiinflamatorio no esteroideo. Reduce inflamación, dolor y fiebre.',
      price: 5.25,
      discountPercent: 10,
      imageUrl:
        'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=600&auto=format&fit=crop',
      categorySlug: 'farmacia',
      isFeatured: true,
    },
    {
      sku: 'FAR-003',
      name: 'Ibuprofeno 800mg x10',
      description: 'Antiinflamatorio de alta concentración. Oferta especial en presentación x10.',
      price: 3.50,
      discountPercent: 0,
      imageUrl:
        'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600&auto=format&fit=crop',
      categorySlug: 'farmacia',
      isFeatured: true,
    },
    {
      sku: 'PET-001',
      name: 'Alimento perro adulto 2kg',
      description: 'Alimento balanceado para perro adulto. Proteínas y vitaminas esenciales.',
      price: 14.99,
      discountPercent: 12,
      imageUrl:
        'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=600&auto=format&fit=crop',
      categorySlug: 'mascotas',
      isFeatured: true,
    },
    {
      sku: 'ALI-002',
      name: 'Harina PAN 1kg',
      description: 'Harina de maíz precocida marca líder. Base de la arepa venezolana.',
      price: 1.85,
      imageUrl:
        'https://images.unsplash.com/photo-1574323347407-f5e1f8c2c6c1?w=600&auto=format&fit=crop',
      categorySlug: 'alimentos-bebidas',
      isFeatured: true,
    },
  ];

  // 1. Consultar productos reales de la API de CIMA (Todos los medicamentos)
  let cimaProducts: any[] = [];
  try {
    console.log('Consultando API de CIMA de forma paginada para obtener todos los medicamentos comerciales...');
    let page = 1;
    let hasMore = true;
    const pageSize = 500; // CIMA permite páginas grandes

    while (hasMore && page <= 35) { // 35 páginas de 500 cubre los ~16,000 medicamentos
      console.log(`Cargando página ${page} de medicamentos de CIMA...`);
      const cimaRes = await fetch(`https://cima.aemps.es/cima/rest/medicamentos?comerc=1&pagina=${page}&tamanioPagina=${pageSize}`);
      if (!cimaRes.ok) {
        console.log(`Error de respuesta en página ${page}. Deteniendo.`);
        break;
      }

      const cimaData = await cimaRes.json();
      const resultados = cimaData.resultados || [];
      if (resultados.length === 0) {
        hasMore = false;
        break;
      }

      for (const med of resultados) {
        const sku = med.nregistro;
        const name = med.nombre;

        const boxPhoto =
          med.fotos?.find((f: any) => f.tipo === 'materialas')?.url ??
          med.fotos?.find((f: any) => f.tipo === 'formafarmac')?.url;

        // Solo medicamentos con foto real de la caja (sin placeholder genérico)
        if (!boxPhoto) continue;

        const price = Math.round((Math.random() * 22 + 3.0) * 100) / 100;

        cimaProducts.push({
          sku,
          name,
          description: `Principio Activo: ${med.vtm?.nombre || 'N/A'}. Presentación: ${med.dosis || 'Estándar'}. Vía: ${med.viasAdministracion?.[0]?.nombre || 'ORAL'}. ${med.cpresc || ''}`,
          price,
          discountPercent: Math.random() > 0.9 ? 15 : null,
          imageUrl: boxPhoto,
          categorySlug: 'farmacia',
          isFeatured: Math.random() > 0.995, // Muy pocos destacados
        });
      }

      page++;
    }
    console.log(`Carga de CIMA finalizada. Encontrados: ${cimaProducts.length} medicamentos reales.`);
  } catch (err) {
    console.log('API de CIMA inaccesible. Usando catálogo de respaldo offline.');
  }

  // Catálogo offline de respaldo en caso de desconexión o fallo de red
  if (cimaProducts.length === 0) {
    cimaProducts = [
      {
        sku: '42991',
        name: 'A.A.S. 100 mg COMPRIMIDOS',
        description: 'Principio Activo: ácido acetilsalicílico. Tratamiento de larga duración. Medicamento Sujeto A Prescripción Médica.',
        price: 3.50,
        discountPercent: null,
        imageUrl: 'https://cima.aemps.es/cima/fotos/thumbnails/materialas/42991/42991_materialas.jpg',
        categorySlug: 'farmacia',
        isFeatured: false,
      },
      {
        sku: '42956',
        name: 'A.A.S. 500 mg COMPRIMIDOS',
        description: 'Principio Activo: ácido acetilsalicílico. Sin receta.',
        price: 4.90,
        discountPercent: 10,
        imageUrl: 'https://cima.aemps.es/cima/fotos/thumbnails/materialas/42956/42956_materialas.jpg',
        categorySlug: 'farmacia',
        isFeatured: true,
      },
      {
        sku: '81012',
        name: 'ABACAVIR/LAMIVUDINA DR. REDDYS 600 MG/300 MG COMPRIMIDOS',
        description: 'Principio Activo: abacavir + lamivudina. Diagnóstico Hospitalario.',
        price: 19.50,
        discountPercent: null,
        imageUrl: 'https://cima.aemps.es/cima/fotos/thumbnails/materialas/81012/81012_materialas.jpg',
        categorySlug: 'farmacia',
        isFeatured: false,
      },
      {
        sku: '82591',
        name: 'ABACAVIR/LAMIVUDINA GLENMARK 600 MG/300 MG COMPRIMIDOS',
        description: 'Principio Activo: abacavir + lamivudina. Diagnóstico Hospitalario.',
        price: 18.99,
        discountPercent: 15,
        imageUrl: 'https://cima.aemps.es/cima/fotos/thumbnails/materialas/82591/82591_materialas.jpg',
        categorySlug: 'farmacia',
        isFeatured: false,
      },
      {
        sku: '85180',
        name: 'ABRILIA 20 MG COMPRIMIDOS EFG',
        description: 'Principio Activo: bilastina. Antialérgico. Sin receta.',
        price: 7.20,
        discountPercent: null,
        imageUrl: 'https://cima.aemps.es/cima/fotos/thumbnails/materialas/85180/85180_materialas.jpg',
        categorySlug: 'farmacia',
        isFeatured: true,
      }
    ];
  }

  // Quitar del inventario productos importados de Open Food Facts
  const offCleanup = await prisma.product.updateMany({
    where: {
      OR: [
        { imageUrl: { contains: 'openfoodfacts.org' } },
        { sku: { startsWith: 'WM-' } },
      ],
    },
    data: { isActive: false },
  });
  if (offCleanup.count > 0) {
    console.log(`Desactivados ${offCleanup.count} productos de Open Food Facts.`);
  }

  // Medicamentos CIMA/importados sin foto real (placeholder Unsplash)
  const noPhotoMeds = await prisma.product.updateMany({
    where: {
      isActive: true,
      category: { slug: 'farmacia' },
      imageUrl: { contains: 'unsplash.com' },
      NOT: {
        OR: [{ sku: { startsWith: 'FAR-' } }, { sku: { startsWith: 'VE-FAR-' } }],
      },
    },
    data: { isActive: false },
  });
  if (noPhotoMeds.count > 0) {
    console.log(`Desactivados ${noPhotoMeds.count} medicamentos sin imagen real.`);
  }

  // Productos duplicados reemplazados por catálogo venezolano (VE-*)
  const redundantCleanup = await prisma.product.updateMany({
    where: {
      isActive: true,
      OR: [
        { sku: { in: ['ALI-001', 'PAN-001', 'PAN-002'] } },
        { sku: { startsWith: 'DJ-' } },
        { sku: { startsWith: 'UPC-' } },
        { sku: { startsWith: 'PAN-API-' } },
      ],
    },
    data: { isActive: false },
  });
  if (redundantCleanup.count > 0) {
    console.log(`Desactivados ${redundantCleanup.count} productos redundantes o en inglés.`);
  }

  // Catálogo en español: bebidas, panadería y medicamentos venezolanos
  const convenienceProducts: Array<{
    sku: string;
    name: string;
    description: string;
    price: number;
    discountPercent: number | null;
    imageUrl: string;
    categorySlug: string;
    isFeatured: boolean;
  }> = [];

  console.log('Cargando bebidas venezolanas (español)...');
  for (const drink of getDefaultSeedBeverages(12)) {
    convenienceProducts.push({
      sku: drink.sku,
      name: drink.name,
      description: drink.description,
      price: drink.price,
      discountPercent: Math.random() > 0.85 ? 10 : null,
      imageUrl: drink.imageUrl,
      categorySlug: 'alimentos-bebidas',
      isFeatured: true,
    });
  }

  console.log('Cargando panadería venezolana (español)...');
  for (const item of getDefaultSeedBakery(10)) {
    convenienceProducts.push({
      sku: item.sku,
      name: item.name,
      description: item.description,
      price: item.price,
      discountPercent: Math.random() > 0.9 ? 15 : null,
      imageUrl: item.imageUrl,
      categorySlug: 'panaderia',
      isFeatured: item.sku === 'VE-PAN-001' || item.sku === 'VE-PAN-002',
    });
  }

  const venezuelanPharmacy = VENEZUELAN_PHARMACY_PRODUCTS.map((med) => ({
    sku: med.sku,
    name: med.name,
    description: med.description,
    price: med.price,
    discountPercent: med.discountPercent ?? null,
    imageUrl: med.imageUrl,
    categorySlug: med.categorySlug,
    isFeatured: med.isFeatured,
  }));

  const managedCatalogProducts = [...convenienceProducts, ...venezuelanPharmacy];

  const allProducts = [...products, ...cimaProducts, ...venezuelanPharmacy, ...convenienceProducts];

  // Actualizar catálogo gestionado (bebidas, panadería y farmacia VE)
  for (const item of managedCatalogProducts) {
    const categoryId = categoryMap.get(item.categorySlug);
    if (!categoryId) continue;

    await prisma.product.upsert({
      where: { sku: item.sku },
      update: {
        name: item.name,
        description: item.description,
        price: item.price,
        discountPercent: item.discountPercent ?? null,
        imageUrl: item.imageUrl,
        categoryId,
        isFeatured: item.isFeatured,
        isActive: true,
      },
      create: {
        sku: item.sku,
        name: item.name,
        description: item.description,
        price: item.price,
        discountPercent: item.discountPercent ?? null,
        imageUrl: item.imageUrl,
        categoryId,
        isFeatured: item.isFeatured,
      },
    });
  }

  const activeApiSkus = managedCatalogProducts.map((item) => item.sku);
  if (activeApiSkus.length > 0) {
    await prisma.product.updateMany({
      where: {
        OR: [
          { sku: { startsWith: 'DJ-' } },
          { sku: { startsWith: 'UPC-' } },
          { sku: { startsWith: 'PAN-API-' } },
        ],
        sku: { notIn: activeApiSkus },
      },
      data: { isActive: false },
    });
  }
  
  // 2. Cargar en lote optimizado los productos para evitar lentitud
  console.log(`Verificando base de datos para productos existentes...`);
  const existingProducts = await prisma.product.findMany({
    select: { id: true, sku: true },
  });
  const existingMap = new Map<string, string>();
  for (const p of existingProducts) {
    existingMap.set(p.sku, p.id);
  }

  const toCreate: any[] = [];
  for (const item of allProducts) {
    const categoryId = categoryMap.get(item.categorySlug);
    if (!categoryId) continue;

    if (!existingMap.has(item.sku)) {
      // Los de convenienceProducts ya se upsertearon arriba
      if (managedCatalogProducts.some((c) => c.sku === item.sku)) continue;

      toCreate.push({
        sku: item.sku,
        name: item.name,
        description: item.description,
        price: item.price,
        discountPercent: item.discountPercent ?? null,
        imageUrl: item.imageUrl,
        categoryId,
        isFeatured: item.isFeatured,
      });
    }
  }

  if (toCreate.length > 0) {
    console.log(`Insertando ${toCreate.length} nuevos productos en base de datos...`);
    // Insertar en lotes de 1000 para evitar límites
    for (let i = 0; i < toCreate.length; i += 1000) {
      const batch = toCreate.slice(i, i + 1000);
      await prisma.product.createMany({
        data: batch,
      });
    }
  } else {
    console.log('No hay productos nuevos para insertar.');
  }

  // Volver a consultar todos para tener el mapa de IDs
  const finalProducts = await prisma.product.findMany({
    select: { id: true, sku: true },
  });
  const productMap = new Map<string, string>();
  for (const p of finalProducts) {
    productMap.set(p.sku, p.id);
  }

  const branchStockMatrix: Record<string, Record<string, number>> = {
    'FAR-001': {
      'indio-mara': 45,
      'bella-vista': 38,
    },
    'FAR-002': {
      'indio-mara': 32,
      'bella-vista': 28,
    },
    'FAR-003': {
      'indio-mara': 24,
      'bella-vista': 20,
    },
    'PAN-001': {
      'indio-mara': 30,
      'bella-vista': 22,
    },
    'PAN-002': {
      'indio-mara': 40,
      'bella-vista': 26,
    },
    'PET-001': {
      'indio-mara': 10,
      'bella-vista': 8,
    },
    'ALI-001': {
      'indio-mara': 90,
      'bella-vista': 70,
    },
    'ALI-002': {
      'indio-mara': 28,
      'bella-vista': 18,
    },
  };

  // Generar matriz de stock para medicamentos cargados de CIMA si no están en la matriz
  for (const item of allProducts) {
    if (!branchStockMatrix[item.sku]) {
      branchStockMatrix[item.sku] = {
        'indio-mara': Math.floor(Math.random() * 40) + 20,
        'bella-vista': Math.floor(Math.random() * 35) + 15,
      };
    }
  }

  // Optimizar la inserción de movimientos de stock
  console.log('Verificando registros de stock existentes en base de datos...');
  const existingMovements = await prisma.inventoryMovement.findMany({
    where: { reference: { startsWith: 'SEED-' } },
    select: { productId: true, branchId: true },
  });
  const movementSet = new Set<string>();
  for (const m of existingMovements) {
    if (m.branchId) {
      movementSet.add(`${m.productId}_${m.branchId}`);
    }
  }

  const movementsToCreate: any[] = [];
  for (const [sku, branchStocks] of Object.entries(branchStockMatrix)) {
    const productId = productMap.get(sku);
    if (!productId) continue;

    for (const [branchSlug, quantity] of Object.entries(branchStocks)) {
      if (quantity <= 0) continue;

      const branchId = branchMap.get(branchSlug);
      if (!branchId) continue;

      const key = `${productId}_${branchId}`;
      if (movementSet.has(key)) continue;

      movementsToCreate.push({
        productId,
        branchId,
        type: InventoryMovementType.ENTRY,
        quantity,
        userId: admin.id,
        reference: `SEED-${branchSlug}`,
        notes: `Stock inicial sucursal ${branchSlug}`,
      });
    }
  }

  if (movementsToCreate.length > 0) {
    console.log(`Insertando ${movementsToCreate.length} movimientos de stock en lote...`);
    for (let i = 0; i < movementsToCreate.length; i += 2000) {
      const batch = movementsToCreate.slice(i, i + 2000);
      await prisma.inventoryMovement.createMany({
        data: batch,
      });
    }
  } else {
    console.log('No hay nuevos movimientos de stock que sembrar.');
  }

  const banners = [
    {
      title: 'Paga con Cashea en Farma Express',
      subtitle: 'Llévalo hoy · Inicial + cuotas sin interés',
      imageUrl:
        'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=900&auto=format&fit=crop',
      backgroundColor: '#FAFF00',
      textColor: '#000000',
      badgeText: 'CASHEA',
      buttonText: 'Ver cómo funciona',
      placement: BannerPlacement.HOME_HERO,
      sortOrder: 0,
      isActive: true,
    },
    {
      title: 'Medic Plus: consulta online',
      subtitle: 'Videollamada y receta digital · 24 horas',
      imageUrl:
        'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=900&auto=format&fit=crop',
      backgroundColor: '#0A1628',
      textColor: '#FFFFFF',
      badgeText: 'MEDIC PLUS',
      buttonText: 'Consultar ahora',
      placement: BannerPlacement.HOME_HERO,
      sortOrder: 1,
      isActive: true,
    },
    {
      title: 'Club FarmaExpress',
      subtitle: 'Gana puntos en cada compra',
      imageUrl:
        'https://images.unsplash.com/photo-1607083206869-4c7672e72a8a?w=900&auto=format&fit=crop',
      backgroundColor: '#7C3AED',
      textColor: '#FFFFFF',
      badgeText: 'CLUB',
      buttonText: 'Ver programa',
      placement: BannerPlacement.HOME_HERO,
      sortOrder: 2,
      isActive: true,
    },
    {
      title: 'Panadería fresca cada mañana',
      subtitle: 'Horneado diario · Stock en vivo',
      imageUrl:
        'https://images.unsplash.com/photo-1486427944299-195ffd3e8b07?w=900&auto=format&fit=crop',
      backgroundColor: '#C2410C',
      textColor: '#FFFFFF',
      badgeText: 'FRESCO',
      buttonText: 'Ver panadería',
      placement: BannerPlacement.HOME_HERO,
      sortOrder: 3,
      isActive: true,
    },
    {
      title: 'Todo en un solo lugar',
      subtitle: 'Farmacia, panadería, charcutería y bodegón · 24h',
      imageUrl:
        'https://images.unsplash.com/photo-1631549916762-40c9c2789f56?w=600&auto=format&fit=crop',
      backgroundColor: '#0F766E',
      textColor: '#FFFFFF',
      badgeText: '24 HORAS',
      buttonText: 'Explorar',
      placement: BannerPlacement.HOME_STRIP,
      sortOrder: 1,
      isActive: true,
    },
    {
      title: 'Elige cuidarte, elige ahorrar',
      subtitle: 'Hasta 20% en farmacia',
      imageUrl:
        'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=600&auto=format&fit=crop',
      backgroundColor: '#1D4ED8',
      textColor: '#FFFFFF',
      badgeText: 'OFERTA',
      buttonText: 'Ver farmacia',
      placement: BannerPlacement.HOME_STRIP,
      sortOrder: 2,
      isActive: true,
    },
  ];

  // Desactivar banners huérfanos fuera del set Farma Express actual
  await prisma.banner.updateMany({
    where: {
      OR: [
        { sortOrder: { gt: 3 }, placement: BannerPlacement.HOME_HERO },
        { title: { contains: 'prueba', mode: 'insensitive' } },
        { title: { contains: 'Promo prueba', mode: 'insensitive' } },
      ],
    },
    data: { isActive: false },
  });

  for (const banner of banners) {
    const existing = await prisma.banner.findFirst({
      where: {
        placement: banner.placement,
        sortOrder: banner.sortOrder,
      },
    });

    if (existing) {
      await prisma.banner.update({
        where: { id: existing.id },
        data: banner,
      });
    } else {
      await prisma.banner.create({ data: banner });
    }
  }

  // Desactivar banners con marca vieja (MaraPuntos, MaraPadel, Dog Plus, etc.)
  await prisma.banner.updateMany({
    where: {
      OR: [
        { title: { contains: 'MaraPuntos', mode: 'insensitive' } },
        { title: { contains: 'MaraPadel', mode: 'insensitive' } },
        { title: { contains: 'MaraPlus', mode: 'insensitive' } },
        { title: { contains: 'Dog Plus', mode: 'insensitive' } },
        { title: { contains: 'pádel', mode: 'insensitive' } },
        { title: { contains: 'padel', mode: 'insensitive' } },
      ],
    },
    data: { isActive: false },
  });

  // Seed an active/completed appointment
  const acetaminofen = await prisma.product.findUnique({
    where: { sku: 'FAR-001' },
  });

  const existingAppointment = await prisma.appointment.findFirst({
    where: { patientId: patientUser.id },
  });

  if (!existingAppointment) {
    const appointment = await prisma.appointment.create({
      data: {
        patientId: patientUser.id,
        doctorId: doctorProfile.id,
        dateTime: new Date(Date.now() - 3600000 * 2), // 2 hours ago
        status: 'COMPLETED',
        notes: 'Paciente refiere dolor de cabeza leve y fiebre ocasional. Se prescribe analgésico.',
      },
    });

    await prisma.prescription.create({
      data: {
        appointmentId: appointment.id,
        diagnosis: 'Cefalea tensional leve',
        items: {
          create: [
            {
              productId: acetaminofen?.id,
              medicationName: 'Acetaminofén 500mg',
              dosage: 'Tomar 1 tableta cada 8 horas por 3 días',
              duration: '3 días',
            },
          ],
        },
      },
    });

    // Create a pending appointment for tomorrow at 10 AM
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(10, 0, 0, 0);

    await prisma.appointment.create({
      data: {
        patientId: patientUser.id,
        doctorId: doctorProfile.id,
        dateTime: tomorrow,
        status: 'PENDING',
        patientNotes: 'Consulta de control general',
      },
    });

    // Create a scheduled appointment for today (in 1 hour)
    await prisma.appointment.create({
      data: {
        patientId: patientUser.id,
        doctorId: doctorProfile.id,
        dateTime: new Date(Date.now() + 3600000), // in 1 hour
        status: 'ACCEPTED',
        notes: 'Consulta de control de presión arterial.',
      },
    });
  }

  // Reparar URLs de imágenes CIMA en la base de datos para que apunten a los thumbnails válidos
  console.log('Reparando URLs de imágenes CIMA en base de datos para apuntar a los thumbnails válidos...');
  try {
    await prisma.$executeRawUnsafe(`
      UPDATE products 
      SET image_url = REPLACE(image_url, '/fotos/materialas/', '/fotos/thumbnails/materialas/') 
      WHERE image_url LIKE '%/fotos/materialas/%' AND image_url NOT LIKE '%/thumbnails/%'
    `);
    await prisma.$executeRawUnsafe(`
      UPDATE products 
      SET image_url = REPLACE(image_url, '/fotos/formafarmac/', '/fotos/thumbnails/formafarmac/') 
      WHERE image_url LIKE '%/fotos/formafarmac/%' AND image_url NOT LIKE '%/thumbnails/%'
    `);
    console.log('URLs de CIMA reparadas con éxito.');
  } catch (sqlErr) {
    console.error('Error al ejecutar migración SQL de imágenes:', sqlErr);
  }

  console.log('Seed Farma Express completado.');
  console.log(`Admin: ${adminEmail} / ${adminPassword}`);
  console.log(`Doctor: ${doctorEmail} / ${doctorPassword}`);
  console.log(`Doctor 2: doctor2@farmaexpress.com / Doctor123!`);
  console.log(`Doctor 3: doctor3@farmaexpress.com / Doctor123!`);
  console.log(`Paciente: ${patientEmail} / ${patientPassword}`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
