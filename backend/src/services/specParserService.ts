// src/services/specParserService.ts
// LLM-Powered RFQ Spec Parser (Gemini Flash + heuristic NLP fallback)

const GEMINI_API_KEY = process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY || '';

export interface ParsedRfqSpec {
  item: string;
  standard: string;
  grade: string;
  quantity: number;
  unit: string;
  deliveryDays: number;
  deliveryLocation: string;
  qualityNotes: string;
}

const COMMON_RULES = [
  { match: /bolt|fastener|screw/i, item: 'M8 Hex Bolt', standard: 'ISO 4017', grade: 'A2-70', unit: 'pieces' },
  { match: /plate|mild steel|is 2062/i, item: 'Mild Steel Plates', standard: 'IS 2062', grade: 'Grade B', unit: 'MT' },
  { match: /sheet|crca/i, item: 'CRCA Sheet', standard: 'IS 513', grade: 'D', unit: 'kg' },
  { match: /o-ring|gasket|seal|rubber/i, item: 'Nitrile O-Ring', standard: 'IS 5382', grade: 'Shore 70A', unit: 'pieces' },
  { match: /cable|wire|harness/i, item: 'Copper Cable', standard: 'IS 694', grade: 'Cu, 1100 V', unit: 'metres' },
  { match: /housing|casting/i, item: 'Die Cast Housing', standard: 'IS 3965', grade: 'ADC12', unit: 'pieces' },
];

const KNOWN_CITIES = [
  'Pune', 'Chakan', 'Bengaluru', 'Chennai', 'Coimbatore', 'Indore', 'Noida',
  'Ludhiana', 'Kochi', 'Nashik', 'Hyderabad', 'Ahmedabad', 'Mumbai', 'Delhi', 'Gurugram'
];

/**
 * Parses free-text RFQ requirement into structured RFQ spec fields.
 */
export async function parseRfqRequirement(freeText: string): Promise<ParsedRfqSpec> {
  const trimmed = freeText.trim();
  if (!trimmed) {
    return {
      item: 'General Industrial Supply',
      standard: 'IS Standard',
      grade: 'Commercial Grade',
      quantity: 100,
      unit: 'pieces',
      deliveryDays: 14,
      deliveryLocation: 'Pune',
      qualityNotes: 'Standard incoming inspection applies.',
    };
  }

  // 1. Try Gemini Flash if API key is provided
  if (GEMINI_API_KEY) {
    try {
      const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`;
      const prompt = `You are an expert industrial procurement engineer in India.
Extract structured procurement RFQ specification fields from this buyer requirement text:

Requirement text: "${trimmed}"

Extract into a JSON object with these exact keys:
- item: string (e.g. "Mild Steel Plates", "M8 Hex Bolt", "CRCA Sheet")
- standard: string (e.g. "IS 2062", "ISO 4017", "IS 513", "IS 694", or "Standard")
- grade: string (e.g. "Grade B", "A2", "ADC12", "Cu 1100V", or "Commercial")
- quantity: number (extract numeric count or volume)
- unit: string (e.g. "MT", "kg", "pieces", "metres", "sets")
- deliveryDays: number (days until required delivery, default to 15 if unstated)
- deliveryLocation: string (city or industrial hub, e.g. "Pune", "Chakan", "Bengaluru")
- qualityNotes: string (e.g. "Mill test certificate (MTC) required with dispatch")

Respond with ONLY valid JSON:`;

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { responseMimeType: 'application/json' },
        }),
      });

      if (response.ok) {
        const json: any = await response.json();
        const text = json.candidates?.[0]?.content?.parts?.[0]?.text;
        if (text) {
          const parsed = JSON.parse(text);
          return {
            item: String(parsed.item ?? 'Industrial Material'),
            standard: String(parsed.standard ?? 'IS 2062'),
            grade: String(parsed.grade ?? 'Standard Grade'),
            quantity: Number(parsed.quantity ?? 100) || 100,
            unit: String(parsed.unit ?? 'pieces'),
            deliveryDays: Number(parsed.deliveryDays ?? 15) || 15,
            deliveryLocation: String(parsed.deliveryLocation ?? 'Pune'),
            qualityNotes: String(parsed.qualityNotes ?? 'Inspection certificate required with dispatch.'),
          };
        }
      }
    } catch (err) {
      console.warn('Gemini RFQ spec parser call failed, falling back to deterministic extractor:', err);
    }
  }

  // 2. Deterministic NLP extraction fallback
  const rule = COMMON_RULES.find((r) => r.match.test(trimmed));
  const qtyMatch = trimmed.match(/(\d[\d,]*)\s*(mt|tonnes|tons|kg|pieces|pcs|nos|units|sets|metres|m)?/i);
  const daysMatch = trimmed.match(/(\d+)\s*days?/i);
  const cityMatch = KNOWN_CITIES.find((c) => new RegExp(`\\b${c}\\b`, 'i').test(trimmed));

  // Extract explicit standard if mentioned (e.g. "IS 2062", "ISO 4017")
  const standardMatch = trimmed.match(/\b(IS\s*\d+|ISO\s*\d+|DIN\s*\d+|ASTM\s*[A-Z0-9]+)\b/i);
  // Extract grade if mentioned (e.g. "Grade B", "A2", "304")
  const gradeMatch = trimmed.match(/\b(Grade\s*[A-Z0-9]+|[A-Z]\d+[-0-9]*|SS\s*304|SS\s*316)\b/i);

  const unit = qtyMatch?.[2]?.toLowerCase();
  const normalizedUnit =
    unit === 'mt' || unit === 'tonnes' || unit === 'tons'
      ? 'MT'
      : unit === 'kg'
      ? 'kg'
      : unit === 'metres' || unit === 'm'
      ? 'metres'
      : rule?.unit ?? 'pieces';

  return {
    item: rule?.item ?? 'Mild Steel Plates',
    standard: standardMatch ? standardMatch[1].toUpperCase() : rule?.standard ?? 'IS 2062',
    grade: gradeMatch ? gradeMatch[1] : rule?.grade ?? 'Grade B',
    quantity: qtyMatch ? Number(qtyMatch[1].replace(/,/g, '')) : 100,
    unit: normalizedUnit,
    deliveryDays: daysMatch ? Number(daysMatch[1]) : 15,
    deliveryLocation: cityMatch ?? 'Pune',
    qualityNotes: /test certificate|mtc|mill test/i.test(trimmed)
      ? 'Mill test certificate (MTC) required with dispatch.'
      : 'Standard incoming inspection applies.',
  };
}
