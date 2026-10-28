// prisma/seed.ts
// Realistic Indian MSME seed data for MoolParakh
import { PrismaClient } from '@prisma/client';

const db = new PrismaClient();

// ─── Helpers ──────────────────────────────────────────────────────────────────

function daysAgo(n: number): Date {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d;
}

function daysFromNow(n: number): Date {
  const d = new Date();
  d.setDate(d.getDate() + n);
  return d;
}

/** Generate 30 trust-history points (daily) ending today */
function trustHistory(finalScore: number, variance = 5) {
  const points: { score: number; recordedAt: Date }[] = [];
  let score = Math.max(10, finalScore - Math.floor(Math.random() * 15));
  for (let i = 29; i >= 0; i--) {
    score = Math.min(100, Math.max(5, score + Math.floor((Math.random() - 0.45) * variance)));
    points.push({ score, recordedAt: daysAgo(i) });
  }
  // Ensure last point matches finalScore
  points[points.length - 1].score = finalScore;
  return points;
}

// ─── Main ────────────────────────────────────────────────────────────────────

async function main() {
  console.log('🌱 Seeding MoolParakh database with Indian MSME vendors...\n');

  // ─── 1. Wipe existing seed data (safe re-run) ─────────────────────────────
  await db.notification.deleteMany();
  await db.bid.deleteMany();
  await db.rfq.deleteMany();
  await db.disruptionTarget.deleteMany();
  await db.disruptionEvent.deleteMany();
  await db.supplierRelationship.deleteMany();
  await db.vendorEvent.deleteMany();
  await db.alert.deleteMany();
  await db.trustHistoryPoint.deleteMany();
  await db.trustScore.deleteMany();
  await db.verificationRecord.deleteMany();
  await db.document.deleteMany();
  await db.vendor.deleteMany();

  console.log('✅ Cleared existing data');

  // ─── 2. Create Vendors ────────────────────────────────────────────────────

  const v1 = await db.vendor.create({
    data: {
      legalName: 'Bharat Electricals Pvt Ltd',
      tradeName: 'Bharat Electricals',
      email: 'procurement@bharatelectricals.in',
      phone: '+91-80-26712345',
      pan: 'AABCB1234A',
      gstin: '29AABCB1234A1ZX',
      cin: 'U31100KA1998PTC012345',
      udyamNumber: 'UDYAM-KA-01-0012345',
      msmeCategory: 'SMALL',
      city: 'Bengaluru',
      state: 'Karnataka',
      categories: ['Electrical', 'Control Panels', 'Switchgear'],
      contactName: 'Ramesh Nair',
      contactRole: 'MD',
      status: 'VERIFIED',
      onboardedAt: daysAgo(420),
      address: { street: '14-B, Peenya Industrial Area', city: 'Bengaluru', pincode: '560058' },
    },
  });

  const v2 = await db.vendor.create({
    data: {
      legalName: 'Sai Precision Parts Mfg',
      tradeName: 'Sai Precision',
      email: 'ops@saiprecision.co.in',
      phone: '+91-20-27654321',
      pan: 'AAHCS9876B',
      gstin: '27AAHCS9876B1Z2',
      udyamNumber: 'UDYAM-MH-05-0098765',
      msmeCategory: 'MICRO',
      city: 'Pune',
      state: 'Maharashtra',
      categories: ['CNC Machining', 'Mechanical Components', 'Aerospace Parts'],
      contactName: 'Surekha Desai',
      contactRole: 'Proprietor',
      status: 'VERIFIED',
      onboardedAt: daysAgo(310),
      address: { street: 'Plot 7, Bhosari MIDC', city: 'Pune', pincode: '411026' },
    },
  });

  const v3 = await db.vendor.create({
    data: {
      legalName: 'Rajasthan Textile Mills Ltd',
      tradeName: 'RT Mills',
      email: 'accounts@rtmills.com',
      phone: '+91-141-2567890',
      pan: 'AAECR4567C',
      gstin: '08AAECR4567C1ZP',
      cin: 'U17111RJ2005PTC021456',
      msmeCategory: 'MEDIUM',
      city: 'Jaipur',
      state: 'Rajasthan',
      categories: ['Textiles', 'Fabrics', 'Uniforms', 'PPE'],
      contactName: 'Vikram Agarwal',
      contactRole: 'CEO',
      status: 'FLAGGED',
      buyerFlagNote: 'Director appears in two other registered entities. Under review.',
      onboardedAt: daysAgo(180),
      address: { street: 'C-12 Sitapura Industrial Zone', city: 'Jaipur', pincode: '302022' },
    },
  });

  const v4 = await db.vendor.create({
    data: {
      legalName: 'Chennai Forge & Steel Works',
      tradeName: 'CF Steel',
      email: 'supply@cfsteel.in',
      phone: '+91-44-24356789',
      pan: 'AAECF2233D',
      gstin: '33AAECF2233D1ZK',
      udyamNumber: 'UDYAM-TN-03-0067890',
      msmeCategory: 'SMALL',
      city: 'Chennai',
      state: 'Tamil Nadu',
      categories: ['Steel Fabrication', 'Forging', 'Structural Steel'],
      contactName: 'Arun Krishnamurthy',
      contactRole: 'GM - Operations',
      status: 'VERIFIED',
      onboardedAt: daysAgo(540),
      address: { street: '45 Ambattur Industrial Estate', city: 'Chennai', pincode: '600058' },
    },
  });

  const v5 = await db.vendor.create({
    data: {
      legalName: 'Hyderabad Chemicals & Polymers',
      tradeName: 'HCP Industries',
      email: 'hcp@hcpindustries.in',
      phone: '+91-40-23456781',
      pan: 'AABCH5544E',
      gstin: '36AABCH5544E1ZA',
      cin: 'U24100TG2010PTC065432',
      msmeCategory: 'SMALL',
      city: 'Hyderabad',
      state: 'Telangana',
      categories: ['Industrial Chemicals', 'Polymers', 'Adhesives'],
      contactName: 'Padmaja Rao',
      contactRole: 'Director',
      status: 'PENDING_VERIFICATION',
      onboardedAt: daysAgo(45),
      address: { street: 'Plot 23, IDA Jeedimetla', city: 'Hyderabad', pincode: '500055' },
    },
  });

  const v6 = await db.vendor.create({
    data: {
      legalName: 'Punjab Agro Processing Ltd',
      tradeName: 'Punjab Agro',
      email: 'contact@punjabagroprocessing.com',
      phone: '+91-161-2345679',
      pan: 'AAFCP7788F',
      gstin: '03AAFCP7788F1ZR',
      udyamNumber: 'UDYAM-PB-02-0034567',
      msmeCategory: 'MEDIUM',
      city: 'Ludhiana',
      state: 'Punjab',
      categories: ['Food Processing', 'Packaging', 'Agricultural Inputs'],
      contactName: 'Gurpreet Singh',
      contactRole: 'Managing Director',
      status: 'VERIFIED',
      onboardedAt: daysAgo(720),
      address: { street: 'G.T. Road, Focal Point', city: 'Ludhiana', pincode: '141010' },
    },
  });

  const v7 = await db.vendor.create({
    data: {
      legalName: 'Delhi NCR Logistics Solutions',
      tradeName: 'NCR Logistics',
      email: 'ops@ncrlogistics.co.in',
      phone: '+91-11-45678901',
      pan: 'AABCD1122G',
      gstin: '07AABCD1122G1ZQ',
      msmeCategory: 'MICRO',
      city: 'Gurugram',
      state: 'Haryana',
      categories: ['3PL Logistics', 'Warehousing', 'Last Mile Delivery'],
      contactName: 'Deepak Taneja',
      contactRole: 'Founder',
      status: 'FLAGGED',
      buyerFlagNote: 'Bank account shared with another registered entity (Radha Logistics). Pending investigation.',
      onboardedAt: daysAgo(120),
      address: { street: 'Sector 18, Udyog Vihar', city: 'Gurugram', pincode: '122015' },
    },
  });

  const v8 = await db.vendor.create({
    data: {
      legalName: 'Coimbatore Engineering Works',
      tradeName: 'CEW',
      email: 'purchase@cewcoimbatore.in',
      phone: '+91-422-2345678',
      pan: 'AACCC3344H',
      gstin: '33AACCC3344H1Z5',
      udyamNumber: 'UDYAM-TN-07-0089012',
      msmeCategory: 'SMALL',
      city: 'Coimbatore',
      state: 'Tamil Nadu',
      categories: ['Pumps', 'Motors', 'Industrial Equipment'],
      contactName: 'Kavitha Subramanian',
      contactRole: 'Partner',
      status: 'VERIFIED',
      onboardedAt: daysAgo(280),
      address: { street: '23 Mettupalayam Road, Ganapathy', city: 'Coimbatore', pincode: '641006' },
    },
  });

  const v9 = await db.vendor.create({
    data: {
      legalName: 'Kolkata Printing & Packaging',
      tradeName: 'KPP',
      email: 'kpp@kolkatapackaging.in',
      phone: '+91-33-22345678',
      pan: 'AAFCK4455I',
      gstin: '19AAFCK4455I1ZY',
      msmeCategory: 'MICRO',
      city: 'Kolkata',
      state: 'West Bengal',
      categories: ['Printing', 'Packaging', 'Labels', 'Corrugated Boxes'],
      contactName: 'Biswajit Ghosh',
      contactRole: 'Director',
      status: 'PENDING_VERIFICATION',
      onboardedAt: daysAgo(22),
      address: { street: '7 Taratala Road, Garden Reach', city: 'Kolkata', pincode: '700024' },
    },
  });

  const v10 = await db.vendor.create({
    data: {
      legalName: 'Ahmedabad Safety Equipment',
      tradeName: 'ASE',
      email: 'sales@ase-safety.com',
      phone: '+91-79-26578901',
      pan: 'AABCA5566J',
      gstin: '24AABCA5566J1ZL',
      cin: 'U36900GJ2008PTC052789',
      udyamNumber: 'UDYAM-GJ-04-0056789',
      msmeCategory: 'SMALL',
      city: 'Ahmedabad',
      state: 'Gujarat',
      categories: ['Safety Equipment', 'PPE', 'Fire Safety'],
      contactName: 'Mehul Shah',
      contactRole: 'CEO',
      status: 'VERIFIED',
      onboardedAt: daysAgo(500),
      address: { street: '102 GIDC Vatva', city: 'Ahmedabad', pincode: '382445' },
    },
  });

  const v11 = await db.vendor.create({
    data: {
      legalName: 'Mumbai IT Hardware Supplies',
      tradeName: 'MHW Tech',
      email: 'procurement@mhwtech.co.in',
      phone: '+91-22-28901234',
      pan: 'AABCM7890K',
      gstin: '27AABCM7890K1ZN',
      msmeCategory: 'MICRO',
      city: 'Mumbai',
      state: 'Maharashtra',
      categories: ['IT Hardware', 'Networking Equipment', 'Peripherals'],
      contactName: 'Priya Mehta',
      contactRole: 'COO',
      status: 'PENDING_VERIFICATION',
      onboardedAt: daysAgo(10),
      address: { street: 'Shop 5, Dharavi Industrial Estate', city: 'Mumbai', pincode: '400017' },
    },
  });

  const v12 = await db.vendor.create({
    data: {
      legalName: 'Nagpur Industrial Gases Ltd',
      tradeName: 'NIG Ltd',
      email: 'orders@niggases.in',
      phone: '+91-712-2345670',
      pan: 'AADCN6677L',
      gstin: '27AADCN6677L1Z8',
      cin: 'U40200MH2001PLC134567',
      udyamNumber: 'UDYAM-MH-12-0078901',
      msmeCategory: 'MEDIUM',
      city: 'Nagpur',
      state: 'Maharashtra',
      categories: ['Industrial Gases', 'Welding Gases', 'Medical Gases'],
      contactName: 'Ashok Thakre',
      contactRole: 'VP Operations',
      status: 'VERIFIED',
      onboardedAt: daysAgo(650),
      address: { street: 'Hingna MIDC Road', city: 'Nagpur', pincode: '440016' },
    },
  });

  const v13 = await db.vendor.create({
    data: {
      legalName: 'Surat Diamond Tools Co',
      tradeName: 'SDT Tools',
      email: 'sales@sdttools.com',
      phone: '+91-261-2678901',
      pan: 'AAHCS1199M',
      gstin: '24AAHCS1199M1Z3',
      udyamNumber: 'UDYAM-GJ-09-0001234',
      msmeCategory: 'MICRO',
      city: 'Surat',
      state: 'Gujarat',
      categories: ['Diamond Tools', 'Cutting Tools', 'Precision Instruments'],
      contactName: 'Dilip Patel',
      contactRole: 'Proprietor',
      status: 'VERIFIED',
      onboardedAt: daysAgo(390),
      address: { street: 'Ring Road, Udhna', city: 'Surat', pincode: '394210' },
    },
  });

  const v14 = await db.vendor.create({
    data: {
      legalName: 'Bhopal Auto Components',
      tradeName: 'BAC Auto',
      email: 'supply@bacauto.in',
      phone: '+91-755-2890123',
      pan: 'AAFCB2233N',
      gstin: '23AAFCB2233N1ZV',
      udyamNumber: 'UDYAM-MP-01-0023456',
      msmeCategory: 'SMALL',
      city: 'Bhopal',
      state: 'Madhya Pradesh',
      categories: ['Auto Components', 'Sheet Metal', 'Welding Assemblies'],
      contactName: 'Sanjay Yadav',
      contactRole: 'Director',
      status: 'FLAGGED',
      buyerFlagNote: 'GST filing gaps detected for Q3 FY2024. Compliance team notified.',
      onboardedAt: daysAgo(200),
      address: { street: 'Sector C, Mandideep Industrial Area', city: 'Bhopal', pincode: '462046' },
    },
  });

  const v15 = await db.vendor.create({
    data: {
      legalName: 'Kochi Marine Engineering',
      tradeName: 'KME',
      email: 'projects@kochimarine.in',
      phone: '+91-484-2356789',
      pan: 'AABCK8899O',
      gstin: '32AABCK8899O1ZB',
      cin: 'U35110KL2012PLC031456',
      msmeCategory: 'SMALL',
      city: 'Kochi',
      state: 'Kerala',
      categories: ['Marine Engineering', 'Shipyard Services', 'Valves & Fittings'],
      contactName: 'Thomas Mathew',
      contactRole: 'CEO',
      status: 'VERIFIED',
      onboardedAt: daysAgo(340),
      address: { street: 'Marine Drive Industrial Estate', city: 'Kochi', pincode: '682015' },
    },
  });

  const v16 = await db.vendor.create({
    data: {
      legalName: 'Varanasi Handloom Cooperative',
      tradeName: 'VHC Textiles',
      email: 'vhc@banarasiweaves.com',
      phone: '+91-542-2456789',
      pan: 'AADCV3344P',
      gstin: '09AADCV3344P1ZU',
      udyamNumber: 'UDYAM-UP-07-0089123',
      msmeCategory: 'MICRO',
      city: 'Varanasi',
      state: 'Uttar Pradesh',
      categories: ['Handloom', 'Silk Fabrics', 'Traditional Textiles'],
      contactName: 'Ravi Shankar Gupta',
      contactRole: 'Secretary',
      status: 'PENDING_VERIFICATION',
      onboardedAt: daysAgo(35),
      address: { street: 'Madanpura, Varanasi', city: 'Varanasi', pincode: '221010' },
    },
  });

  const v17 = await db.vendor.create({
    data: {
      legalName: 'Indore Pharma Packaging',
      tradeName: 'IPP',
      email: 'info@indorepharmapack.in',
      phone: '+91-731-2567891',
      pan: 'AACEI4455Q',
      gstin: '23AACEI4455Q1ZJ',
      cin: 'U21022MP2016PTC089234',
      msmeCategory: 'SMALL',
      city: 'Indore',
      state: 'Madhya Pradesh',
      categories: ['Pharma Packaging', 'Blister Packs', 'Carton Printing'],
      contactName: 'Neha Joshi',
      contactRole: 'Managing Director',
      status: 'VERIFIED',
      onboardedAt: daysAgo(460),
      address: { street: 'Sector G, Sanwer Road Industrial Area', city: 'Indore', pincode: '452015' },
    },
  });

  const vendors = [v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v16, v17];
  console.log(`✅ Created ${vendors.length} vendors`);

  // ─── 3. Trust Scores & History ────────────────────────────────────────────

  const trustData: Record<string, { overall: number; vc: number; cf: number; aa: number; mb: number; risk: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL' }> = {
    [v1.id]:  { overall: 87, vc: 38, cf: 30, aa: 12, mb: 7,  risk: 'LOW' },
    [v2.id]:  { overall: 79, vc: 32, cf: 28, aa: 12, mb: 7,  risk: 'LOW' },
    [v3.id]:  { overall: 42, vc: 16, cf: 14, aa:  7, mb: 5,  risk: 'HIGH' },
    [v4.id]:  { overall: 83, vc: 35, cf: 29, aa: 13, mb: 6,  risk: 'LOW' },
    [v5.id]:  { overall: 55, vc: 20, cf: 22, aa:  8, mb: 5,  risk: 'MEDIUM' },
    [v6.id]:  { overall: 91, vc: 39, cf: 33, aa: 13, mb: 6,  risk: 'LOW' },
    [v7.id]:  { overall: 28, vc:  8, cf: 10, aa:  5, mb: 5,  risk: 'CRITICAL' },
    [v8.id]:  { overall: 76, vc: 31, cf: 27, aa: 11, mb: 7,  risk: 'LOW' },
    [v9.id]:  { overall: 48, vc: 18, cf: 19, aa:  7, mb: 4,  risk: 'MEDIUM' },
    [v10.id]: { overall: 85, vc: 36, cf: 31, aa: 12, mb: 6,  risk: 'LOW' },
    [v11.id]: { overall: 35, vc: 12, cf: 14, aa:  5, mb: 4,  risk: 'HIGH' },
    [v12.id]: { overall: 89, vc: 38, cf: 32, aa: 13, mb: 6,  risk: 'LOW' },
    [v13.id]: { overall: 73, vc: 30, cf: 25, aa: 11, mb: 7,  risk: 'LOW' },
    [v14.id]: { overall: 39, vc: 14, cf: 13, aa:  7, mb: 5,  risk: 'HIGH' },
    [v15.id]: { overall: 78, vc: 33, cf: 27, aa: 12, mb: 6,  risk: 'LOW' },
    [v16.id]: { overall: 52, vc: 19, cf: 21, aa:  8, mb: 4,  risk: 'MEDIUM' },
    [v17.id]: { overall: 81, vc: 34, cf: 28, aa: 13, mb: 6,  risk: 'LOW' },
  };

  for (const [vendorId, ts] of Object.entries(trustData)) {
    await db.trustScore.create({
      data: {
        vendorId,
        overallScore: ts.overall,
        verificationCompleteness: ts.vc,
        certificationFreshness: ts.cf,
        accountAgeActivity: ts.aa,
        manualBuyerFlag: ts.mb,
        riskLevel: ts.risk,
      },
    });

    const pts = trustHistory(ts.overall, 6);
    await db.trustHistoryPoint.createMany({
      data: pts.map((p) => ({ vendorId, score: p.score, recordedAt: p.recordedAt })),
    });
  }

  console.log('✅ Created trust scores and 30-day history sparklines');

  // ─── 4. Verification Records ──────────────────────────────────────────────

  const verifications = [
    // v1 - Bharat Electricals (VERIFIED, all checks pass)
    { vendorId: v1.id, type: 'GSTIN' as const,       status: 'SUCCESS' as const, verifiedAt: daysAgo(30) },
    { vendorId: v1.id, type: 'PAN' as const,         status: 'SUCCESS' as const, verifiedAt: daysAgo(31) },
    { vendorId: v1.id, type: 'CIN' as const,         status: 'SUCCESS' as const, verifiedAt: daysAgo(29) },
    { vendorId: v1.id, type: 'UDYAM' as const,       status: 'SUCCESS' as const, verifiedAt: daysAgo(30) },

    // v2 - Sai Precision (VERIFIED)
    { vendorId: v2.id, type: 'GSTIN' as const,       status: 'SUCCESS' as const, verifiedAt: daysAgo(15) },
    { vendorId: v2.id, type: 'PAN' as const,         status: 'SUCCESS' as const, verifiedAt: daysAgo(15) },
    { vendorId: v2.id, type: 'UDYAM' as const,       status: 'SUCCESS' as const, verifiedAt: daysAgo(16) },

    // v3 - Rajasthan Textile Mills (FLAGGED - CIN mismatch)
    { vendorId: v3.id, type: 'GSTIN' as const,       status: 'SUCCESS' as const, verifiedAt: daysAgo(60) },
    { vendorId: v3.id, type: 'PAN' as const,         status: 'FAILED' as const,  failureReason: 'PAN name mismatch with GSTIN entity name' },
    { vendorId: v3.id, type: 'CIN' as const,         status: 'FAILED' as const,  failureReason: 'Director DIN found in disqualified directors list' },

    // v4 - Chennai Forge (VERIFIED)
    { vendorId: v4.id, type: 'GSTIN' as const,       status: 'SUCCESS' as const, verifiedAt: daysAgo(20) },
    { vendorId: v4.id, type: 'PAN' as const,         status: 'SUCCESS' as const, verifiedAt: daysAgo(21) },
    { vendorId: v4.id, type: 'UDYAM' as const,       status: 'SUCCESS' as const, verifiedAt: daysAgo(22) },

    // v5 - HCP Industries (PENDING_VERIFICATION)
    { vendorId: v5.id, type: 'GSTIN' as const,       status: 'PENDING' as const },
    { vendorId: v5.id, type: 'PAN' as const,         status: 'PENDING' as const },
    { vendorId: v5.id, type: 'CIN' as const,         status: 'PENDING' as const },

    // v6 - Punjab Agro (VERIFIED - excellent)
    { vendorId: v6.id, type: 'GSTIN' as const,       status: 'SUCCESS' as const, verifiedAt: daysAgo(45) },
    { vendorId: v6.id, type: 'PAN' as const,         status: 'SUCCESS' as const, verifiedAt: daysAgo(45) },
    { vendorId: v6.id, type: 'UDYAM' as const,       status: 'SUCCESS' as const, verifiedAt: daysAgo(46) },

    // v7 - NCR Logistics (FLAGGED - shared bank account)
    { vendorId: v7.id, type: 'GSTIN' as const,       status: 'SUCCESS' as const, verifiedAt: daysAgo(90) },
    { vendorId: v7.id, type: 'PAN' as const,         status: 'FAILED' as const,  failureReason: 'Bank account linked to another PAN entity' },
    { vendorId: v7.id, type: 'BANK_ACCOUNT' as const, status: 'FAILED' as const, failureReason: 'Account active under different company registration' },

    // v8 - CEW (VERIFIED)
    { vendorId: v8.id, type: 'GSTIN' as const,       status: 'SUCCESS' as const, verifiedAt: daysAgo(10) },
    { vendorId: v8.id, type: 'PAN' as const,         status: 'SUCCESS' as const, verifiedAt: daysAgo(11) },
    { vendorId: v8.id, type: 'UDYAM' as const,       status: 'SUCCESS' as const, verifiedAt: daysAgo(10) },

    // v9 - KPP (PENDING)
    { vendorId: v9.id, type: 'GSTIN' as const,       status: 'PENDING' as const },
    { vendorId: v9.id, type: 'PAN' as const,         status: 'PENDING' as const },

    // v10 - ASE (VERIFIED)
    { vendorId: v10.id, type: 'GSTIN' as const,      status: 'SUCCESS' as const, verifiedAt: daysAgo(25) },
    { vendorId: v10.id, type: 'PAN' as const,        status: 'SUCCESS' as const, verifiedAt: daysAgo(25) },
    { vendorId: v10.id, type: 'CIN' as const,        status: 'SUCCESS' as const, verifiedAt: daysAgo(26) },
    { vendorId: v10.id, type: 'UDYAM' as const,      status: 'SUCCESS' as const, verifiedAt: daysAgo(26) },

    // v11 - MHW Tech (PENDING - very new)
    { vendorId: v11.id, type: 'GSTIN' as const,      status: 'PENDING' as const },
    { vendorId: v11.id, type: 'PAN' as const,        status: 'PENDING' as const },

    // v12 - Nagpur Industrial Gases (VERIFIED)
    { vendorId: v12.id, type: 'GSTIN' as const,      status: 'SUCCESS' as const, verifiedAt: daysAgo(50) },
    { vendorId: v12.id, type: 'PAN' as const,        status: 'SUCCESS' as const, verifiedAt: daysAgo(50) },
    { vendorId: v12.id, type: 'CIN' as const,        status: 'SUCCESS' as const, verifiedAt: daysAgo(51) },
    { vendorId: v12.id, type: 'UDYAM' as const,      status: 'SUCCESS' as const, verifiedAt: daysAgo(51) },
    { vendorId: v12.id, type: 'BANK_ACCOUNT' as const, status: 'SUCCESS' as const, verifiedAt: daysAgo(52) },

    // v13 - Surat Diamond Tools (VERIFIED)
    { vendorId: v13.id, type: 'GSTIN' as const,      status: 'SUCCESS' as const, verifiedAt: daysAgo(40) },
    { vendorId: v13.id, type: 'PAN' as const,        status: 'SUCCESS' as const, verifiedAt: daysAgo(41) },
    { vendorId: v13.id, type: 'UDYAM' as const,      status: 'SUCCESS' as const, verifiedAt: daysAgo(41) },

    // v14 - Bhopal Auto (FLAGGED)
    { vendorId: v14.id, type: 'GSTIN' as const,      status: 'FAILED' as const,  failureReason: 'GST registration suspended by GSTN portal' },
    { vendorId: v14.id, type: 'PAN' as const,        status: 'SUCCESS' as const, verifiedAt: daysAgo(100) },
    { vendorId: v14.id, type: 'UDYAM' as const,      status: 'MANUAL_REVIEW' as const },

    // v15 - Kochi Marine (VERIFIED)
    { vendorId: v15.id, type: 'GSTIN' as const,      status: 'SUCCESS' as const, verifiedAt: daysAgo(18) },
    { vendorId: v15.id, type: 'PAN' as const,        status: 'SUCCESS' as const, verifiedAt: daysAgo(18) },
    { vendorId: v15.id, type: 'CIN' as const,        status: 'SUCCESS' as const, verifiedAt: daysAgo(19) },

    // v16 - VHC (PENDING)
    { vendorId: v16.id, type: 'GSTIN' as const,      status: 'PENDING' as const },
    { vendorId: v16.id, type: 'PAN' as const,        status: 'PENDING' as const },
    { vendorId: v16.id, type: 'UDYAM' as const,      status: 'PENDING' as const },

    // v17 - Indore Pharma (VERIFIED)
    { vendorId: v17.id, type: 'GSTIN' as const,      status: 'SUCCESS' as const, verifiedAt: daysAgo(35) },
    { vendorId: v17.id, type: 'PAN' as const,        status: 'SUCCESS' as const, verifiedAt: daysAgo(35) },
    { vendorId: v17.id, type: 'CIN' as const,        status: 'SUCCESS' as const, verifiedAt: daysAgo(36) },
  ];

  for (const vr of verifications) {
    await db.verificationRecord.create({ data: { ...vr, source: 'SurePass' } });
  }

  console.log(`✅ Created ${verifications.length} verification records`);

  // ─── 5. Compliance Documents ──────────────────────────────────────────────

  const documents = [
    // v1 - Bharat Electricals
    { vendorId: v1.id, type: 'GST_CERTIFICATE' as const,   fileKey: 'docs/v1/gst.pdf',     mimeType: 'application/pdf', fileSize: 120000, status: 'PARSED' as const, certificateNumber: 'GST/29/2021/KA/00123', issuingAuthority: 'GSTN', issueDate: daysAgo(1200), expirationDate: daysFromNow(180) },
    { vendorId: v1.id, type: 'ISO_CERTIFICATE' as const,    fileKey: 'docs/v1/iso.pdf',     mimeType: 'application/pdf', fileSize: 98000,  status: 'PARSED' as const, certificateNumber: 'ISO9001-2022-BEL-001', issuingAuthority: 'Bureau Veritas', issueDate: daysAgo(500), expirationDate: daysFromNow(365) },
    { vendorId: v1.id, type: 'INSURANCE_DOCUMENT' as const, fileKey: 'docs/v1/insure.pdf',  mimeType: 'application/pdf', fileSize: 85000,  status: 'PARSED' as const, certificateNumber: 'NIC/2024/PLY-0034567', issuingAuthority: 'National Insurance', issueDate: daysAgo(200), expirationDate: daysFromNow(25) },

    // v2 - Sai Precision
    { vendorId: v2.id, type: 'GST_CERTIFICATE' as const,   fileKey: 'docs/v2/gst.pdf',     mimeType: 'application/pdf', fileSize: 115000, status: 'PARSED' as const, certificateNumber: 'GST/27/2020/MH/00456', issuingAuthority: 'GSTN', issueDate: daysAgo(800), expirationDate: daysFromNow(120) },
    { vendorId: v2.id, type: 'UDYAM_CERTIFICATE' as const, fileKey: 'docs/v2/udyam.pdf',   mimeType: 'application/pdf', fileSize: 45000,  status: 'PARSED' as const, certificateNumber: 'UDYAM-MH-05-0098765', issuingAuthority: 'MSME Ministry', issueDate: daysAgo(600), expirationDate: daysFromNow(730) },

    // v3 - Rajasthan Textile Mills (some expired)
    { vendorId: v3.id, type: 'GST_CERTIFICATE' as const,   fileKey: 'docs/v3/gst.pdf',     mimeType: 'application/pdf', fileSize: 112000, status: 'PARSED' as const, certificateNumber: 'GST/08/2019/RJ/00789', issuingAuthority: 'GSTN', issueDate: daysAgo(1500), expirationDate: daysAgo(30) },
    { vendorId: v3.id, type: 'ISO_CERTIFICATE' as const,   fileKey: 'docs/v3/iso.pdf',     mimeType: 'application/pdf', fileSize: 90000,  status: 'PARSED' as const, certificateNumber: 'ISO9001-2021-RTM-007', issuingAuthority: 'TUV SUD', issueDate: daysAgo(900), expirationDate: daysFromNow(15) },

    // v4 - Chennai Forge
    { vendorId: v4.id, type: 'GST_CERTIFICATE' as const,   fileKey: 'docs/v4/gst.pdf',     mimeType: 'application/pdf', fileSize: 118000, status: 'PARSED' as const, certificateNumber: 'GST/33/2018/TN/01234', issuingAuthority: 'GSTN', issueDate: daysAgo(2000), expirationDate: daysFromNow(300) },
    { vendorId: v4.id, type: 'UDYAM_CERTIFICATE' as const, fileKey: 'docs/v4/udyam.pdf',   mimeType: 'application/pdf', fileSize: 43000,  status: 'PARSED' as const, certificateNumber: 'UDYAM-TN-03-0067890', issuingAuthority: 'MSME Ministry', issueDate: daysAgo(700), expirationDate: daysFromNow(660) },
    { vendorId: v4.id, type: 'ISO_CERTIFICATE' as const,   fileKey: 'docs/v4/iso.pdf',     mimeType: 'application/pdf', fileSize: 95000,  status: 'PARSED' as const, certificateNumber: 'ISO14001-2023-CFS-003', issuingAuthority: 'DNV GL', issueDate: daysAgo(100), expirationDate: daysFromNow(900) },

    // v5 - HCP Industries
    { vendorId: v5.id, type: 'GST_CERTIFICATE' as const,   fileKey: 'docs/v5/gst.pdf',     mimeType: 'application/pdf', fileSize: 108000, status: 'UPLOADED' as const, certificateNumber: null, issuingAuthority: null, issueDate: daysAgo(300), expirationDate: daysFromNow(60) },

    // v6 - Punjab Agro
    { vendorId: v6.id, type: 'GST_CERTIFICATE' as const,   fileKey: 'docs/v6/gst.pdf',     mimeType: 'application/pdf', fileSize: 121000, status: 'PARSED' as const, certificateNumber: 'GST/03/2016/PB/00567', issuingAuthority: 'GSTN', issueDate: daysAgo(2800), expirationDate: daysFromNow(400) },
    { vendorId: v6.id, type: 'UDYAM_CERTIFICATE' as const, fileKey: 'docs/v6/udyam.pdf',   mimeType: 'application/pdf', fileSize: 47000,  status: 'PARSED' as const, certificateNumber: 'UDYAM-PB-02-0034567', issuingAuthority: 'MSME Ministry', issueDate: daysAgo(1000), expirationDate: daysFromNow(730) },
    { vendorId: v6.id, type: 'ISO_CERTIFICATE' as const,   fileKey: 'docs/v6/iso.pdf',     mimeType: 'application/pdf', fileSize: 92000,  status: 'PARSED' as const, certificateNumber: 'ISO22000-2022-PAP-001', issuingAuthority: 'SGS India', issueDate: daysAgo(400), expirationDate: daysFromNow(500) },

    // v7 - NCR Logistics (critical - expired)
    { vendorId: v7.id, type: 'GST_CERTIFICATE' as const,   fileKey: 'docs/v7/gst.pdf',     mimeType: 'application/pdf', fileSize: 99000,  status: 'PARSED' as const, certificateNumber: 'GST/07/2021/HR/00890', issuingAuthority: 'GSTN', issueDate: daysAgo(900), expirationDate: daysAgo(15) },
    { vendorId: v7.id, type: 'INSURANCE_DOCUMENT' as const, fileKey: 'docs/v7/insure.pdf',  mimeType: 'application/pdf', fileSize: 78000,  status: 'PARSED' as const, certificateNumber: 'HDFC/2022/CARGO-00456', issuingAuthority: 'HDFC Ergo', issueDate: daysAgo(800), expirationDate: daysAgo(60) },

    // v8 - CEW
    { vendorId: v8.id, type: 'GST_CERTIFICATE' as const,   fileKey: 'docs/v8/gst.pdf',     mimeType: 'application/pdf', fileSize: 117000, status: 'PARSED' as const, certificateNumber: 'GST/33/2019/TN/01567', issuingAuthority: 'GSTN', issueDate: daysAgo(1800), expirationDate: daysFromNow(240) },
    { vendorId: v8.id, type: 'UDYAM_CERTIFICATE' as const, fileKey: 'docs/v8/udyam.pdf',   mimeType: 'application/pdf', fileSize: 44000,  status: 'PARSED' as const, certificateNumber: 'UDYAM-TN-07-0089012', issuingAuthority: 'MSME Ministry', issueDate: daysAgo(900), expirationDate: daysFromNow(800) },

    // v10 - ASE
    { vendorId: v10.id, type: 'GST_CERTIFICATE' as const,  fileKey: 'docs/v10/gst.pdf',    mimeType: 'application/pdf', fileSize: 119000, status: 'PARSED' as const, certificateNumber: 'GST/24/2017/GJ/00234', issuingAuthority: 'GSTN', issueDate: daysAgo(2500), expirationDate: daysFromNow(220) },
    { vendorId: v10.id, type: 'ISO_CERTIFICATE' as const,  fileKey: 'docs/v10/iso.pdf',    mimeType: 'application/pdf', fileSize: 94000,  status: 'PARSED' as const, certificateNumber: 'ISO45001-2023-ASE-002', issuingAuthority: 'Bureau Veritas', issueDate: daysAgo(200), expirationDate: daysFromNow(800) },
    { vendorId: v10.id, type: 'UDYAM_CERTIFICATE' as const, fileKey: 'docs/v10/udyam.pdf', mimeType: 'application/pdf', fileSize: 46000,  status: 'PARSED' as const, certificateNumber: 'UDYAM-GJ-04-0056789', issuingAuthority: 'MSME Ministry', issueDate: daysAgo(1200), expirationDate: daysFromNow(365) },

    // v12 - Nagpur Industrial Gases
    { vendorId: v12.id, type: 'GST_CERTIFICATE' as const,  fileKey: 'docs/v12/gst.pdf',    mimeType: 'application/pdf', fileSize: 122000, status: 'PARSED' as const, certificateNumber: 'GST/27/2015/MH/00678', issuingAuthority: 'GSTN', issueDate: daysAgo(3000), expirationDate: daysFromNow(350) },
    { vendorId: v12.id, type: 'UDYAM_CERTIFICATE' as const, fileKey: 'docs/v12/udyam.pdf', mimeType: 'application/pdf', fileSize: 48000,  status: 'PARSED' as const, certificateNumber: 'UDYAM-MH-12-0078901', issuingAuthority: 'MSME Ministry', issueDate: daysAgo(1100), expirationDate: daysFromNow(900) },
    { vendorId: v12.id, type: 'ISO_CERTIFICATE' as const,  fileKey: 'docs/v12/iso.pdf',    mimeType: 'application/pdf', fileSize: 96000,  status: 'PARSED' as const, certificateNumber: 'ISO9001-2022-NIG-004', issuingAuthority: 'TUV Nord', issueDate: daysAgo(300), expirationDate: daysFromNow(700) },

    // v13 - SDT Tools
    { vendorId: v13.id, type: 'GST_CERTIFICATE' as const,  fileKey: 'docs/v13/gst.pdf',    mimeType: 'application/pdf', fileSize: 113000, status: 'PARSED' as const, certificateNumber: 'GST/24/2020/GJ/01890', issuingAuthority: 'GSTN', issueDate: daysAgo(1400), expirationDate: daysFromNow(160) },
    { vendorId: v13.id, type: 'UDYAM_CERTIFICATE' as const, fileKey: 'docs/v13/udyam.pdf', mimeType: 'application/pdf', fileSize: 42000,  status: 'PARSED' as const, certificateNumber: 'UDYAM-GJ-09-0001234', issuingAuthority: 'MSME Ministry', issueDate: daysAgo(800), expirationDate: daysFromNow(560) },

    // v14 - Bhopal Auto (compliance problems)
    { vendorId: v14.id, type: 'GST_CERTIFICATE' as const,  fileKey: 'docs/v14/gst.pdf',    mimeType: 'application/pdf', fileSize: 105000, status: 'PARSED' as const, certificateNumber: 'GST/23/2020/MP/00345', issuingAuthority: 'GSTN', issueDate: daysAgo(1200), expirationDate: daysAgo(5) },
    { vendorId: v14.id, type: 'UDYAM_CERTIFICATE' as const, fileKey: 'docs/v14/udyam.pdf', mimeType: 'application/pdf', fileSize: 41000,  status: 'PARSED' as const, certificateNumber: 'UDYAM-MP-01-0023456', issuingAuthority: 'MSME Ministry', issueDate: daysAgo(700), expirationDate: daysFromNow(25) },

    // v15 - Kochi Marine
    { vendorId: v15.id, type: 'GST_CERTIFICATE' as const,  fileKey: 'docs/v15/gst.pdf',    mimeType: 'application/pdf', fileSize: 116000, status: 'PARSED' as const, certificateNumber: 'GST/32/2019/KL/01234', issuingAuthority: 'GSTN', issueDate: daysAgo(1700), expirationDate: daysFromNow(200) },
    { vendorId: v15.id, type: 'ISO_CERTIFICATE' as const,  fileKey: 'docs/v15/iso.pdf',    mimeType: 'application/pdf', fileSize: 91000,  status: 'PARSED' as const, certificateNumber: 'ISO9001-2023-KME-005', issuingAuthority: 'Lloyd\'s Register', issueDate: daysAgo(180), expirationDate: daysFromNow(730) },

    // v17 - Indore Pharma
    { vendorId: v17.id, type: 'GST_CERTIFICATE' as const,  fileKey: 'docs/v17/gst.pdf',    mimeType: 'application/pdf', fileSize: 120000, status: 'PARSED' as const, certificateNumber: 'GST/23/2017/MP/00901', issuingAuthority: 'GSTN', issueDate: daysAgo(2300), expirationDate: daysFromNow(280) },
    { vendorId: v17.id, type: 'ISO_CERTIFICATE' as const,  fileKey: 'docs/v17/iso.pdf',    mimeType: 'application/pdf', fileSize: 93000,  status: 'PARSED' as const, certificateNumber: 'ISO15378-2022-IPP-001', issuingAuthority: 'Bureau Veritas', issueDate: daysAgo(350), expirationDate: daysFromNow(650) },
  ];

  for (const doc of documents) {
    await db.document.create({ data: doc });
  }

  console.log(`✅ Created ${documents.length} compliance documents`);

  // ─── 6. Vendor Events (Audit Trail) ──────────────────────────────────────

  const events = [
    { vendorId: v1.id, kind: 'VERIFICATION' as const, title: 'Vendor onboarded', detail: 'Bharat Electricals Pvt Ltd added to MoolParakh. Status: DRAFT.', at: daysAgo(420) },
    { vendorId: v1.id, kind: 'VERIFICATION' as const, title: 'GSTIN verified', detail: 'GSTN API returned active status for 29AABCB1234A1ZX', at: daysAgo(419) },
    { vendorId: v1.id, kind: 'VERIFICATION' as const, title: 'PAN verified', detail: 'PAN AABCB1234A verified — legal name matches GSTIN entity', at: daysAgo(419) },
    { vendorId: v1.id, kind: 'TRUST' as const, title: 'Trust score updated', detail: 'Score recalculated to 87/100. Risk: LOW.', at: daysAgo(418) },
    { vendorId: v1.id, kind: 'COMPLIANCE' as const, title: 'Insurance expiring soon', detail: 'Policy NIC/2024/PLY-0034567 expires in 25 days. Renewal required.', at: daysAgo(5) },

    { vendorId: v3.id, kind: 'VERIFICATION' as const, title: 'Vendor onboarded', detail: 'Rajasthan Textile Mills Ltd added to MoolParakh.', at: daysAgo(180) },
    { vendorId: v3.id, kind: 'VERIFICATION' as const, title: 'PAN verification failed', detail: 'PAN name mismatch with GSTIN entity name. Manual review triggered.', at: daysAgo(179) },
    { vendorId: v3.id, kind: 'RISK' as const, title: 'Vendor flagged', detail: 'Director DIN found in disqualified directors list. Status set to FLAGGED.', at: daysAgo(170) },
    { vendorId: v3.id, kind: 'COMPLIANCE' as const, title: 'GST Certificate expired', detail: 'GST/08/2019/RJ/00789 expired 30 days ago. Renewal overdue.', at: daysAgo(30) },

    { vendorId: v7.id, kind: 'VERIFICATION' as const, title: 'Vendor onboarded', detail: 'Delhi NCR Logistics Solutions added to MoolParakh.', at: daysAgo(120) },
    { vendorId: v7.id, kind: 'RISK' as const, title: 'Bank account anomaly detected', detail: 'Current account linked to Radha Logistics Pvt Ltd. Sharing detected.', at: daysAgo(90) },
    { vendorId: v7.id, kind: 'RISK' as const, title: 'Vendor flagged', detail: 'Multiple relationship anomalies. Status set to FLAGGED.', at: daysAgo(88) },
    { vendorId: v7.id, kind: 'COMPLIANCE' as const, title: 'GST Certificate expired', detail: 'GST/07/2021/HR/00890 expired. Immediate renewal required.', at: daysAgo(15) },

    { vendorId: v6.id, kind: 'VERIFICATION' as const, title: 'Vendor onboarded', detail: 'Punjab Agro Processing Ltd added to MoolParakh.', at: daysAgo(720) },
    { vendorId: v6.id, kind: 'TRUST' as const, title: 'Trust score updated', detail: 'Score recalculated to 91/100. Excellent standing.', at: daysAgo(45) },
    { vendorId: v6.id, kind: 'RFQ' as const, title: 'Bid submitted on RFQ-2026-001', detail: 'Bid ₹142/kg for Food Grade Packaging Film. 14-day delivery.', at: daysAgo(12) },

    { vendorId: v14.id, kind: 'VERIFICATION' as const, title: 'Vendor onboarded', detail: 'Bhopal Auto Components added to MoolParakh.', at: daysAgo(200) },
    { vendorId: v14.id, kind: 'VERIFICATION' as const, title: 'GSTIN verification failed', detail: 'GST registration suspended by GSTN portal. Filing gaps detected.', at: daysAgo(150) },
    { vendorId: v14.id, kind: 'RISK' as const, title: 'Vendor flagged', detail: 'GST compliance issues. Manual review required.', at: daysAgo(148) },
    { vendorId: v14.id, kind: 'COMPLIANCE' as const, title: 'GST Certificate expired', detail: 'GST certificate expired 5 days ago.', at: daysAgo(5) },
  ];

  for (const event of events) {
    await db.vendorEvent.create({ data: event });
  }

  console.log(`✅ Created ${events.length} vendor events`);

  // ─── 7. Alerts ────────────────────────────────────────────────────────────

  const alerts = [
    { vendorId: v3.id,  title: 'Director disqualification detected', description: 'Director DIN associated with this company appears in the MCA disqualified directors list.', severity: 'CRITICAL' as const },
    { vendorId: v7.id,  title: 'Shared bank account — relationship risk', description: 'The bank account used for this vendor is also associated with Radha Logistics Pvt Ltd. This may indicate a shell entity.', severity: 'CRITICAL' as const },
    { vendorId: v14.id, title: 'GST registration suspended', description: 'GSTN portal reports GST registration as suspended. Vendor may not be eligible for Input Tax Credit.', severity: 'CRITICAL' as const },
    { vendorId: v7.id,  title: 'Insurance certificate expired', description: 'Cargo insurance policy (HDFC/2022/CARGO-00456) expired 60 days ago.', severity: 'WARNING' as const },
    { vendorId: v3.id,  title: 'ISO certificate expiring in 15 days', description: 'ISO9001 certificate for Rajasthan Textile Mills expires on the 15th.', severity: 'WARNING' as const },
    { vendorId: v1.id,  title: 'Insurance expiring in 25 days', description: 'NIC policy NIC/2024/PLY-0034567 due for renewal. Contact National Insurance.', severity: 'WARNING' as const },
    { vendorId: v14.id, title: 'Udyam certificate under manual review', description: 'Udyam certificate authenticity flagged for manual review.', severity: 'WARNING' as const },
    { vendorId: v5.id,  title: 'Verification pending for 45 days', description: 'HCP Industries verification has been in PENDING state. Escalate to KYB team.', severity: 'INFO' as const },
  ];

  for (const alert of alerts) {
    await db.alert.create({ data: alert });
  }

  console.log(`✅ Created ${alerts.length} alerts`);

  // ─── 8. Supplier Relationships ────────────────────────────────────────────

  await db.supplierRelationship.create({
    data: {
      vendorAId: v7.id,
      vendorBId: v3.id,
      type: 'SHARED_DIRECTOR',
      value: 'Vikram Taneja (DIN: 07891234)',
    },
  });

  await db.supplierRelationship.create({
    data: {
      vendorAId: v7.id,
      vendorBId: v14.id,
      type: 'SHARED_BANK_ACCOUNT',
      value: 'HDFC Bank A/C ending ...8823',
    },
  });

  await db.supplierRelationship.create({
    data: {
      vendorAId: v3.id,
      vendorBId: v14.id,
      type: 'SHARED_DIRECTOR',
      value: 'Sanjay Agarwal (DIN: 05678901)',
    },
  });

  console.log('✅ Created 3 supplier relationships');

  // ─── 9. RFQs with multiple bids ───────────────────────────────────────────

  const rfq1 = await db.rfq.create({
    data: {
      reference: 'RFQ-2026-001',
      title: 'Food Grade Packaging Film — 5,000 kg',
      status: 'OPEN',
      spec: {
        item: 'Food Grade BOPP Film',
        standard: 'IS 2508:2000',
        grade: 'Food Safe A',
        quantity: 5000,
        unit: 'kg',
        deliveryDays: 14,
        deliveryLocation: 'Ludhiana Warehouse',
        qualityNotes: 'Must be BIS certified, FDA compliant, 20–40 micron thickness.',
      },
      freeText: 'Preferred supplier should have ISO 22000 certification. Payment: 30 days net.',
      suppliersNotified: 7,
      closesAt: daysFromNow(5),
    },
  });

  const rfq2 = await db.rfq.create({
    data: {
      reference: 'RFQ-2026-002',
      title: 'CNC Machined Aluminium Brackets — 2,000 units',
      status: 'OPEN',
      spec: {
        item: 'Aluminium Alloy 6061 Bracket',
        standard: 'ASTM B209',
        grade: '6061-T6',
        quantity: 2000,
        unit: 'pcs',
        deliveryDays: 21,
        deliveryLocation: 'Pune Plant Gate',
        qualityNotes: 'Tolerance ±0.05mm. Surface finish Ra 1.6. Dimensional report required with each batch.',
      },
      freeText: 'Samples required before bulk order. Prior aerospace experience preferred.',
      suppliersNotified: 5,
      closesAt: daysFromNow(12),
    },
  });

  const rfq3 = await db.rfq.create({
    data: {
      reference: 'RFQ-2026-003',
      title: 'Industrial Safety Helmets — 500 units',
      status: 'OPEN',
      spec: {
        item: 'Class E Safety Helmet',
        standard: 'IS 2925:1984',
        grade: 'Class E (Electrical)',
        quantity: 500,
        unit: 'units',
        deliveryDays: 10,
        deliveryLocation: 'Chennai Main Store',
        qualityNotes: 'BIS mark mandatory. HDPE shell. Must withstand 2000V electrical test.',
      },
      freeText: 'Bulk order. Multiple color options acceptable. Delivery in two batches.',
      suppliersNotified: 4,
      closesAt: daysFromNow(8),
    },
  });

  console.log('✅ Created 3 open RFQs');

  // ─── RFQ Bids ─────────────────────────────────────────────────────────────

  // RFQ1 bids
  await db.bid.create({ data: { rfqId: rfq1.id, vendorId: v6.id, vendorName: 'Punjab Agro Processing Ltd', pricePerUnit: 142, deliveryDays: 14, trustScoreAtBid: 91, notes: 'ISO 22000 certified. FDA compliance documentation available.', submittedAt: daysAgo(3) } });
  await db.bid.create({ data: { rfqId: rfq1.id, vendorId: v17.id, vendorName: 'Indore Pharma Packaging', pricePerUnit: 138, deliveryDays: 18, trustScoreAtBid: 81, notes: 'Pharmaceutical-grade film. Slightly longer delivery but lowest price.', submittedAt: daysAgo(2) } });
  await db.bid.create({ data: { rfqId: rfq1.id, vendorId: v3.id, vendorName: 'Rajasthan Textile Mills Ltd', pricePerUnit: 128, deliveryDays: 12, trustScoreAtBid: 42, notes: 'Best price. Can deliver early.', submittedAt: daysAgo(1) } });

  // RFQ2 bids
  await db.bid.create({ data: { rfqId: rfq2.id, vendorId: v2.id, vendorName: 'Sai Precision Parts Mfg', pricePerUnit: 385, deliveryDays: 18, trustScoreAtBid: 79, notes: 'Aerospace-grade machining. CMM reports included.', submittedAt: daysAgo(5) } });
  await db.bid.create({ data: { rfqId: rfq2.id, vendorId: v8.id, vendorName: 'Coimbatore Engineering Works', pricePerUnit: 362, deliveryDays: 21, trustScoreAtBid: 76, notes: 'Experienced in auto-grade tolerances. Slightly longer delivery.', submittedAt: daysAgo(4) } });
  await db.bid.create({ data: { rfqId: rfq2.id, vendorId: v13.id, vendorName: 'Surat Diamond Tools Co', pricePerUnit: 398, deliveryDays: 16, trustScoreAtBid: 73, notes: 'Premium tooling ensures superior finish. Sample available.', submittedAt: daysAgo(3) } });
  await db.bid.create({ data: { rfqId: rfq2.id, vendorId: v14.id, vendorName: 'Bhopal Auto Components', pricePerUnit: 310, deliveryDays: 14, trustScoreAtBid: 39, notes: 'Lowest price in market. Can beat any quote.', submittedAt: daysAgo(2) } });

  // RFQ3 bids
  await db.bid.create({ data: { rfqId: rfq3.id, vendorId: v10.id, vendorName: 'Ahmedabad Safety Equipment', pricePerUnit: 245, deliveryDays: 8, trustScoreAtBid: 85, notes: 'BIS certified. IS 2925 compliant. Available in 5 colors.', submittedAt: daysAgo(2) } });
  await db.bid.create({ data: { rfqId: rfq3.id, vendorId: v4.id, vendorName: 'Chennai Forge & Steel Works', pricePerUnit: 268, deliveryDays: 10, trustScoreAtBid: 83, notes: 'Only helmets available, no fabrication. Quote from partner supplier.', submittedAt: daysAgo(1) } });

  console.log('✅ Created 9 bids across 3 RFQs');

  // ─── 10. Disruption Events ────────────────────────────────────────────────

  const d1 = await db.disruptionEvent.create({
    data: {
      severity: 'HIGH',
      title: 'JNPT Container Terminal Congestion — Dwell Times +72h',
      category: 'PORT_DISRUPTION',
      region: 'Navi Mumbai, Maharashtra',
      summary: 'Jawaharlal Nehru Port Trust reports severe container congestion at NSTF terminal. Average dwell time has risen to 6.2 days. Exporters and importers advised to plan for 2–4 day additional delays. Primarily affects raw material imports for western zone manufacturers.',
      sourceUrl: 'https://www.jnpa.gov.in/disruption/oct2026',
      detectedAt: daysAgo(2),
    },
  });

  const d2 = await db.disruptionEvent.create({
    data: {
      severity: 'CRITICAL',
      title: 'BIS Mandatory Certification — New Steel Product Categories',
      category: 'REGULATORY',
      region: 'Pan India',
      summary: 'Bureau of Indian Standards has issued mandatory BIS certification for 12 new steel product categories effective January 1, 2027. Vendors supplying uncertified steel components risk product recall and contractual penalties. Affected vendors must initiate BIS application within 60 days.',
      sourceUrl: 'https://bis.gov.in/notification/steel-certification-2026',
      detectedAt: daysAgo(5),
    },
  });

  const d3 = await db.disruptionEvent.create({
    data: {
      severity: 'MEDIUM',
      title: 'Gujarat Port Strike — 48h Work Stoppage',
      category: 'LOGISTICS',
      region: 'Mundra & Hazira, Gujarat',
      summary: 'Port workers at Mundra and Hazira ports have announced a 48-hour solidarity strike. Chemical and polymer imports are expected to be delayed by 3–5 days. APSEZ management is in talks with union representatives.',
      detectedAt: daysAgo(1),
    },
  });

  const d4 = await db.disruptionEvent.create({
    data: {
      severity: 'HIGH',
      title: 'Cyclone Alert — Bay of Bengal Category 3',
      category: 'NATURAL_DISASTER',
      region: 'Tamil Nadu & Andhra Pradesh Coast',
      summary: 'IMD has issued a high alert for a Category 3 cyclone approaching the eastern coastline. Chennai and Vizag ports may close for 48–72 hours. Supply chains dependent on eastern coast vendors should activate contingency plans. Expected landfall in 5–7 days.',
      sourceUrl: 'https://imd.gov.in/cyclone/oct2026-alert',
      detectedAt: daysAgo(0),
    },
  });

  const d5 = await db.disruptionEvent.create({
    data: {
      severity: 'MEDIUM',
      title: 'EU Anti-Dumping Duties — Indian Textile Exports',
      category: 'TARIFF',
      region: 'Rajasthan, Gujarat, Tamil Nadu',
      summary: 'European Union has imposed provisional anti-dumping duties of 12–18% on specific Indian woven fabric exports. This may affect Indian textile vendors with significant EU export exposure and their domestic pricing strategies.',
      detectedAt: daysAgo(8),
    },
  });

  const d6 = await db.disruptionEvent.create({
    data: {
      severity: 'LOW',
      title: 'NH-48 Highway Maintenance — Bengaluru-Chennai Corridor',
      category: 'LOGISTICS',
      region: 'Karnataka — Tamil Nadu Border',
      summary: 'NHAI announces scheduled maintenance on NH-48 between Krishnagiri and Hosur. Single-lane traffic during 10 PM – 6 AM over 2 weeks. Vendors transporting goods between Bengaluru and Chennai should expect 2–3 hour additional transit times during night hours.',
      detectedAt: daysAgo(3),
    },
  });

  // Link affected vendors
  await db.disruptionTarget.createMany({
    data: [
      { eventId: d1.id, vendorId: v12.id }, // Nagpur - imports through JNPT
      { eventId: d1.id, vendorId: v17.id }, // Indore Pharma - imports APIs through JNPT
      { eventId: d1.id, vendorId: v5.id },  // HCP chemicals
    ],
  });

  await db.disruptionTarget.createMany({
    data: [
      { eventId: d2.id, vendorId: v4.id },  // Chennai Forge - steel
      { eventId: d2.id, vendorId: v14.id }, // Bhopal Auto - steel components
      { eventId: d2.id, vendorId: v8.id },  // CEW - steel equipment
    ],
  });

  await db.disruptionTarget.createMany({
    data: [
      { eventId: d3.id, vendorId: v5.id },  // HCP - chemical imports through Gujarat
      { eventId: d3.id, vendorId: v10.id }, // ASE - imports through Gujarat
    ],
  });

  await db.disruptionTarget.createMany({
    data: [
      { eventId: d4.id, vendorId: v4.id },  // Chennai Forge
      { eventId: d4.id, vendorId: v8.id },  // CEW - Coimbatore
      { eventId: d4.id, vendorId: v15.id }, // Kochi Marine
    ],
  });

  await db.disruptionTarget.createMany({
    data: [
      { eventId: d5.id, vendorId: v3.id },  // Rajasthan Textiles - EU exports
      { eventId: d5.id, vendorId: v16.id }, // VHC Textiles
    ],
  });

  await db.disruptionTarget.createMany({
    data: [
      { eventId: d6.id, vendorId: v1.id },  // Bharat Electricals - Bengaluru
      { eventId: d6.id, vendorId: v4.id },  // Chennai Forge
    ],
  });

  console.log('✅ Created 6 disruption events with affected vendor links');

  // ─── 11. Notifications ────────────────────────────────────────────────────

  const notifs = [
    { vendorId: v3.id,  vendorName: 'Rajasthan Textile Mills', kind: 'CRITICAL' as const, title: 'Director disqualification alert', detail: 'Director DIN linked to disqualified directors list. Vendor flagged. Review before awarding any active RFQ.', read: false, createdAt: daysAgo(1) },
    { vendorId: v7.id,  vendorName: 'NCR Logistics', kind: 'CRITICAL' as const, title: 'Shared bank account — collusion risk', detail: 'Bank account shared with Radha Logistics Pvt Ltd. Risk of bid rigging on active RFQs. Flag for legal review.', read: false, createdAt: daysAgo(0) },
    { vendorId: v14.id, vendorName: 'Bhopal Auto Components', kind: 'HIGH' as const, title: 'GST certificate expired', detail: 'GST/23/2020/MP/00345 expired 5 days ago. Purchases from this vendor are not eligible for ITC until renewal.', read: false, createdAt: daysAgo(5) },
    { vendorId: v4.id,  vendorName: 'Chennai Forge & Steel Works', kind: 'HIGH' as const, title: 'Cyclone alert — supply risk', detail: 'Category 3 cyclone approaching Tamil Nadu coast. Vendor Chennai Forge may face 3–5 day disruption. Activate backup supplier.', read: false, createdAt: daysAgo(0) },
    { vendorId: v1.id,  vendorName: 'Bharat Electricals', kind: 'COMPLIANCE' as const, title: 'Insurance expiring in 25 days', detail: 'NIC/2024/PLY-0034567 due for renewal by Nov 21. Contact Ramesh Nair at +91-80-26712345.', read: false, createdAt: daysAgo(2) },
    { vendorId: v5.id,  vendorName: 'HCP Industries', kind: 'COMPLIANCE' as const, title: 'Verification pending — 45 days', detail: 'HCP Industries GSTIN, PAN, and CIN verification still PENDING. Escalate to KYB team.', read: true, createdAt: daysAgo(10) },
    { vendorId: v3.id,  vendorName: 'Rajasthan Textile Mills', kind: 'COMPLIANCE' as const, title: 'GST Certificate expired 30 days ago', detail: 'GST/08/2019/RJ/00789 expired. Vendor is non-compliant. Block payments until renewal proof received.', read: true, createdAt: daysAgo(30) },
    { vendorId: null,   vendorName: 'System', kind: 'RFQ' as const, title: 'RFQ-2026-001 closes in 5 days', detail: '3 bids received for Food Grade Packaging Film. Compare bids before deadline.', read: false, createdAt: daysAgo(1) },
    { vendorId: v6.id,  vendorName: 'Punjab Agro Processing Ltd', kind: 'RFQ' as const, title: 'New bid on RFQ-2026-001', detail: 'Punjab Agro submitted ₹142/kg bid. ISO 22000 certified. Review in bid comparison.', read: true, createdAt: daysAgo(3) },
    { vendorId: v14.id, vendorName: 'Bhopal Auto Components', kind: 'RFQ' as const, title: 'Low-trust bid on RFQ-2026-002', detail: 'Bhopal Auto submitted a competitive bid (₹310/unit) but has trust score 39/100. Review risk before awarding.', read: false, createdAt: daysAgo(2) },
    { vendorId: v2.id,  vendorName: 'Sai Precision Parts Mfg', kind: 'TRUST' as const, title: 'Trust score improved to 79', detail: 'Sai Precision completed Udyam verification. Trust score increased from 72 to 79.', read: true, createdAt: daysAgo(15) },
    { vendorId: v6.id,  vendorName: 'Punjab Agro Processing Ltd', kind: 'TRUST' as const, title: 'Trust score at 91 — Excellent', detail: 'Punjab Agro maintains top trust score after ISO 22000 renewal. Recommended for preferred vendor status.', read: true, createdAt: daysAgo(45) },
    { vendorId: v7.id,  vendorName: 'NCR Logistics', kind: 'HIGH' as const, title: 'Insurance certificates expired', detail: 'Both cargo insurance policies for NCR Logistics have expired. Shipments are uninsured. Suspend logistics orders.', read: true, createdAt: daysAgo(20) },
    { vendorId: v8.id,  vendorName: 'Coimbatore Engineering Works', kind: 'HIGH' as const, title: 'Cyclone risk — Tamil Nadu coast', detail: 'CEW Coimbatore may be impacted by incoming Bay of Bengal cyclone. Check delivery timelines for RFQ-2026-002 bid.', read: false, createdAt: daysAgo(0) },
    { vendorId: v12.id, vendorName: 'Nagpur Industrial Gases Ltd', kind: 'HIGH' as const, title: 'JNPT congestion — import delay', detail: 'NIG imports specialty gas cylinders through JNPT. Port congestion may delay Q4 procurement by 4+ days.', read: false, createdAt: daysAgo(2) },
  ];

  for (const notif of notifs) {
    await db.notification.create({ data: notif });
  }

  console.log(`✅ Created ${notifs.length} notifications`);

  console.log('\n🎉 Seed complete! Database populated with:');
  console.log(`   • ${vendors.length} Indian MSME vendors (4 risk levels, mixed statuses)`);
  console.log('   • Trust scores + 30-day sparkline history for all vendors');
  console.log('   • Verification records across all check types');
  console.log('   • Compliance documents with real expiry dates');
  console.log('   • 3 open RFQs with 9 competitive bids');
  console.log('   • 6 disruption events linked to affected vendors');
  console.log('   • 3 supplier relationships (shared director + shared bank account)');
  console.log(`   • ${notifs.length} notifications (mix of read/unread)`);
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => db.$disconnect());
