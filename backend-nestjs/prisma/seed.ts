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

async function main() {
  const adminEmail = process.env.ADMIN_EMAIL ?? 'admin@maraplus.com';
  const adminPassword = process.env.ADMIN_PASSWORD ?? 'Admin123!';
  const hashedPassword = await bcrypt.hash(adminPassword, 10);

  const admin = await prisma.user.upsert({
    where: { email: adminEmail },
    update: {
      name: 'Administrador MaraPlus',
      password: hashedPassword,
      role: UserRole.ADMIN,
      isActive: true,
    },
    create: {
      email: adminEmail,
      password: hashedPassword,
      name: 'Administrador MaraPlus',
      role: UserRole.ADMIN,
    },
  });

  // Seed Doctor
  const doctorEmail = 'doctor@maraplus.com';
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
      bio: 'Especialista en cuidado cardiovascular y atención médica primaria con más de 10 años de experiencia.',
      consultationFee: 25.0,
      isActive: true,
    },
    create: {
      userId: doctorUser.id,
      specialty: 'Cardiología y Medicina General',
      bio: 'Especialista en cuidado cardiovascular y atención médica primaria con más de 10 años de experiencia.',
      consultationFee: 25.0,
    },
  });

  const extraDoctors = [
    {
      email: 'doctor2@maraplus.com',
      password: 'Doctor123!',
      name: 'Dra. María González',
      specialty: 'Pediatría',
      bio: 'Pediatra con enfoque en control de niños sanos, vacunas y seguimiento del desarrollo.',
      fee: 22.0,
    },
    {
      email: 'doctor3@maraplus.com',
      password: 'Doctor123!',
      name: 'Dr. Roberto Silva',
      specialty: 'Dermatología',
      bio: 'Especialista en dermatología clínica, acné, alergias cutáneas y cuidado de la piel.',
      fee: 28.0,
    },
  ];

  for (const doctor of extraDoctors) {
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
  const patientEmail = 'patient@maraplus.com';
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
      description: 'Medicamentos y productos de salud',
      sortOrder: 1,
    },
    {
      name: 'Panadería',
      slug: 'panaderia',
      description: 'Pan, pasteles y repostería',
      sortOrder: 2,
    },
    {
      name: 'Mascotas',
      slug: 'mascotas',
      description: 'Alimentos y accesorios para mascotas',
      sortOrder: 3,
    },
    {
      name: 'Alimentos y bebidas',
      slug: 'alimentos-bebidas',
      description: 'Productos de consumo diario',
      sortOrder: 4,
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
      name: 'MaraPlus Las Mercedes',
      slug: 'las-mercedes',
      address: 'Av. Principal de Las Mercedes, Centro Comercial Paseo',
      city: 'Caracas',
      state: 'Miranda',
      phone: '+58 212-555-0101',
      whatsapp: '+58 414-555-0101',
      openingHours: 'Lun–Sáb 8:00–21:00 · Dom 9:00–18:00',
      isMain: true,
      sortOrder: 1,
      latitude: 10.4806,
      longitude: -66.8534,
    },
    {
      name: 'MaraPlus Fuerzas Armadas',
      slug: 'fuerzas-armadas',
      address: 'Av. Fuerzas Armadas, CC Plaza MaraPlus Local 4',
      city: 'Caracas',
      state: 'Distrito Capital',
      phone: '+58 212-555-0102',
      whatsapp: '+58 414-555-0102',
      openingHours: 'Lun–Sáb 8:00–20:00',
      sortOrder: 2,
      latitude: 10.4969,
      longitude: -66.8981,
    },
    {
      name: 'MaraPlus Delicias',
      slug: 'delicias',
      address: 'Av. Principal de Delicias Norte, Local 12',
      city: 'Maracay',
      state: 'Aragua',
      phone: '+58 243-555-0103',
      whatsapp: '+58 414-555-0103',
      openingHours: 'Lun–Sáb 7:30–20:30',
      sortOrder: 3,
      latitude: 10.2469,
      longitude: -67.5958,
    },
    {
      name: 'MaraPlus Catia',
      slug: 'catia',
      address: 'Av. Sucre, Centro Comercial Plaza Catia',
      city: 'Caracas',
      state: 'Distrito Capital',
      phone: '+58 212-555-0104',
      whatsapp: '+58 414-555-0104',
      openingHours: 'Lun–Sáb 8:00–19:00',
      sortOrder: 4,
      latitude: 10.5134,
      longitude: -66.9467,
    },
    {
      name: 'MaraPlus Valencia Norte',
      slug: 'valencia-norte',
      address: 'Av. Bolívar Norte, CC MaraPlus Valencia',
      city: 'Valencia',
      state: 'Carabobo',
      phone: '+58 241-555-0105',
      whatsapp: '+58 414-555-0105',
      openingHours: 'Lun–Sáb 8:00–21:00 · Dom 9:00–17:00',
      sortOrder: 5,
      latitude: 10.1621,
      longitude: -68.0077,
    },
  ];

  const branchMap = new Map<string, string>();
  for (const branch of branches) {
    const saved = await prisma.branch.upsert({
      where: { slug: branch.slug },
      update: branch,
      create: branch,
    });
    branchMap.set(branch.slug, saved.id);
  }

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
      'las-mercedes': 40,
      'fuerzas-armadas': 35,
      'delicias': 18,
      'catia': 15,
      'valencia-norte': 12,
    },
    'FAR-002': {
      'las-mercedes': 30,
      'fuerzas-armadas': 25,
      'delicias': 12,
      'catia': 10,
      'valencia-norte': 8,
    },
    'FAR-003': {
      'las-mercedes': 20,
      'fuerzas-armadas': 20,
      'delicias': 15,
      'catia': 12,
      'valencia-norte': 10,
    },
    'PAN-001': {
      'las-mercedes': 25,
      'fuerzas-armadas': 18,
      'delicias': 8,
      'catia': 12,
      'valencia-norte': 15,
    },
    'PAN-002': {
      'las-mercedes': 35,
      'fuerzas-armadas': 28,
      'delicias': 0,
      'catia': 20,
      'valencia-norte': 14,
    },
    'PET-001': {
      'las-mercedes': 12,
      'fuerzas-armadas': 8,
      'delicias': 5,
      'catia': 3,
      'valencia-norte': 6,
    },
    'ALI-001': {
      'las-mercedes': 80,
      'fuerzas-armadas': 60,
      'delicias': 45,
      'catia': 50,
      'valencia-norte': 55,
    },
    'ALI-002': {
      'fuerzas-armadas': 10,
      'delicias': 0,
      'las-mercedes': 25,
      'catia': 6,
      'valencia-norte': 14,
    },
  };

  // Generar matriz de stock para medicamentos cargados de CIMA si no están en la matriz
  for (const item of allProducts) {
    if (!branchStockMatrix[item.sku]) {
      branchStockMatrix[item.sku] = {
        'las-mercedes': Math.floor(Math.random() * 40) + 15,
        'fuerzas-armadas': Math.floor(Math.random() * 35) + 15,
        'delicias': Math.floor(Math.random() * 30) + 10,
        'catia': Math.floor(Math.random() * 25) + 10,
        'valencia-norte': Math.floor(Math.random() * 20) + 5,
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
      title: '15% en tu primera compra',
      subtitle: 'Solo delivery · Válido hoy',
      imageUrl:
        'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=900&auto=format&fit=crop',
      backgroundColor: '#1B3A8A',
      textColor: '#FFFFFF',
      badgeText: 'NUEVO',
      buttonText: 'Ordenar ahora',
      placement: BannerPlacement.HOME_HERO,
      sortOrder: 1,
    },
    {
      title: 'Panadería fresca cada mañana',
      subtitle: 'Horneado artesanal · Stock en vivo',
      imageUrl:
        'https://images.unsplash.com/photo-1486427944299-195ffd3e8b07?w=900&auto=format&fit=crop',
      backgroundColor: '#009640',
      textColor: '#FFFFFF',
      badgeText: 'FRESCO',
      buttonText: 'Ver panadería',
      placement: BannerPlacement.HOME_HERO,
      sortOrder: 2,
    },
    {
      title: 'Delivery gratis',
      subtitle: 'En compras mayores a \$20',
      imageUrl:
        'https://images.unsplash.com/photo-1526367790999-015a178e6d9c?w=600&auto=format&fit=crop',
      backgroundColor: '#009640',
      textColor: '#FFFFFF',
      badgeText: 'ENVÍO',
      buttonText: 'Ver más',
      placement: BannerPlacement.HOME_STRIP,
      sortOrder: 1,
    },
    {
      title: 'Elige cuidarte, elige ahorrar',
      subtitle: 'Hasta 20% en farmacia',
      imageUrl:
        'https://images.unsplash.com/photo-1631549916762-40c9c2789f56?w=600&auto=format&fit=crop',
      backgroundColor: '#1B3A8A',
      textColor: '#FFFFFF',
      badgeText: 'SALE',
      buttonText: 'Explorar',
      placement: BannerPlacement.HOME_STRIP,
      sortOrder: 2,
    },
  ];

  for (const banner of banners) {
    const existing = await prisma.banner.findFirst({
      where: { title: banner.title, placement: banner.placement },
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

  console.log('Seed completado.');
  console.log(`Admin: ${adminEmail} / ${adminPassword}`);
  console.log(`Doctor: ${doctorEmail} / ${doctorPassword}`);
  console.log(`Doctor 2: doctor2@maraplus.com / Doctor123!`);
  console.log(`Doctor 3: doctor3@maraplus.com / Doctor123!`);
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
