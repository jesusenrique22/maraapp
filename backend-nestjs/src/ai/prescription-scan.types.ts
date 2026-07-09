export type PrescriptionMatchStatus = 'exact' | 'similar' | 'not_found';

export type ExtractedPrescriptionMedication = {
  rawText: string;
  medicationName: string;
  activeIngredient: string | null;
  dosage: string | null;
  frequency: string | null;
  duration: string | null;
  quantity: string | null;
};

export type PrescriptionVisionResult = {
  patientName: string | null;
  doctorName: string | null;
  prescriptionDate: string | null;
  medications: ExtractedPrescriptionMedication[];
  generalNotes: string | null;
  confidence: number;
};

export type PrescriptionInventoryProduct = {
  id: string;
  sku: string;
  name: string;
  description: string | null;
  price: number;
  finalPrice: number;
  inStock: boolean;
  stock: number;
  categoryName: string;
  imageUrl: string | null;
};

export type PrescriptionScanItemResult = {
  extracted: ExtractedPrescriptionMedication;
  matchStatus: PrescriptionMatchStatus;
  products: PrescriptionInventoryProduct[];
};

export type PrescriptionScanResponse = {
  prescription: PrescriptionVisionResult;
  items: PrescriptionScanItemResult[];
  summary: {
    totalMedications: number;
    foundExact: number;
    foundSimilar: number;
    notFound: number;
  };
};
