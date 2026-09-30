-- CreateEnum
CREATE TYPE "VendorStatus" AS ENUM ('DRAFT', 'PENDING_VERIFICATION', 'VERIFIED', 'FLAGGED', 'REJECTED');

-- CreateEnum
CREATE TYPE "MsmeCategory" AS ENUM ('MICRO', 'SMALL', 'MEDIUM');

-- CreateEnum
CREATE TYPE "DocumentType" AS ENUM ('PAN_CARD', 'GST_CERTIFICATE', 'UDYAM_CERTIFICATE', 'BANK_STATEMENT', 'CANCELLED_CHEQUE', 'ISO_CERTIFICATE', 'INSURANCE_DOCUMENT', 'OTHER');

-- CreateEnum
CREATE TYPE "DocumentStatus" AS ENUM ('UPLOADED', 'PROCESSING_OCR', 'PARSED', 'FAILED');

-- CreateEnum
CREATE TYPE "VerificationType" AS ENUM ('PAN', 'GSTIN', 'UDYAM', 'CIN', 'BANK_ACCOUNT');

-- CreateEnum
CREATE TYPE "VerificationStatus" AS ENUM ('PENDING', 'SUCCESS', 'FAILED', 'MANUAL_REVIEW');

-- CreateEnum
CREATE TYPE "RiskLevel" AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL');

-- CreateEnum
CREATE TYPE "AlertSeverity" AS ENUM ('INFO', 'WARNING', 'CRITICAL');

-- CreateEnum
CREATE TYPE "AlertStatus" AS ENUM ('UNREAD', 'READ', 'SNOOZED', 'DISMISSED');

-- CreateEnum
CREATE TYPE "RfqStatus" AS ENUM ('DRAFT', 'OPEN', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "RelationshipType" AS ENUM ('SHARED_DIRECTOR', 'SHARED_BANK_ACCOUNT', 'SHARED_ADDRESS');

-- CreateEnum
CREATE TYPE "DisruptionCategory" AS ENUM ('PORT_DISRUPTION', 'TARIFF', 'NATURAL_DISASTER', 'GEOPOLITICAL', 'LOGISTICS', 'REGULATORY');

-- CreateEnum
CREATE TYPE "NotificationKind" AS ENUM ('HIGH', 'CRITICAL', 'COMPLIANCE', 'RFQ', 'TRUST');

-- CreateEnum
CREATE TYPE "VendorEventKind" AS ENUM ('VERIFICATION', 'COMPLIANCE', 'RISK', 'TRUST', 'RFQ', 'DOCUMENT');

-- CreateTable
CREATE TABLE "vendors" (
    "id" TEXT NOT NULL,
    "legal_name" TEXT NOT NULL,
    "trade_name" TEXT,
    "email" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "pan" TEXT,
    "gstin" TEXT,
    "cin" TEXT,
    "udyam_number" TEXT,
    "msme_category" "MsmeCategory" NOT NULL DEFAULT 'MICRO',
    "city" TEXT NOT NULL DEFAULT '',
    "state" TEXT NOT NULL DEFAULT '',
    "categories" TEXT[],
    "contact_name" TEXT NOT NULL DEFAULT '',
    "contact_role" TEXT NOT NULL DEFAULT '',
    "status" "VendorStatus" NOT NULL DEFAULT 'DRAFT',
    "address" JSONB,
    "buyer_flag_note" TEXT,
    "onboarded_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "vendors_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "documents" (
    "id" TEXT NOT NULL,
    "vendor_id" TEXT NOT NULL,
    "type" "DocumentType" NOT NULL,
    "file_key" TEXT NOT NULL,
    "mime_type" TEXT NOT NULL,
    "file_size" INTEGER NOT NULL,
    "status" "DocumentStatus" NOT NULL DEFAULT 'UPLOADED',
    "certificate_number" TEXT,
    "issuing_authority" TEXT,
    "issue_date" TIMESTAMP(3),
    "expiration_date" TIMESTAMP(3),
    "confidence" DOUBLE PRECISION DEFAULT 0,
    "raw_ocr_text" TEXT,
    "extracted_data" JSONB,
    "uploaded_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "documents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "verification_records" (
    "id" TEXT NOT NULL,
    "vendor_id" TEXT NOT NULL,
    "type" "VerificationType" NOT NULL,
    "status" "VerificationStatus" NOT NULL DEFAULT 'PENDING',
    "source" TEXT,
    "response_payload" JSONB,
    "failure_reason" TEXT,
    "verified_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "verification_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trust_scores" (
    "id" TEXT NOT NULL,
    "vendor_id" TEXT NOT NULL,
    "overall_score" INTEGER NOT NULL,
    "verification_completeness" INTEGER NOT NULL,
    "certification_freshness" INTEGER NOT NULL,
    "account_age_activity" INTEGER NOT NULL,
    "manual_buyer_flag" INTEGER NOT NULL,
    "risk_level" "RiskLevel" NOT NULL DEFAULT 'LOW',
    "scoring_factors" JSONB,
    "last_calculated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "trust_scores_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "trust_history_points" (
    "id" TEXT NOT NULL,
    "vendor_id" TEXT NOT NULL,
    "score" INTEGER NOT NULL,
    "recorded_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "trust_history_points_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "alerts" (
    "id" TEXT NOT NULL,
    "vendor_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "severity" "AlertSeverity" NOT NULL DEFAULT 'WARNING',
    "status" "AlertStatus" NOT NULL DEFAULT 'UNREAD',
    "is_resolved" BOOLEAN NOT NULL DEFAULT false,
    "resolved_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "alerts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vendor_events" (
    "id" TEXT NOT NULL,
    "vendor_id" TEXT NOT NULL,
    "kind" "VendorEventKind" NOT NULL,
    "title" TEXT NOT NULL,
    "detail" TEXT NOT NULL,
    "at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "vendor_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "supplier_relationships" (
    "id" TEXT NOT NULL,
    "vendor_a_id" TEXT NOT NULL,
    "vendor_b_id" TEXT NOT NULL,
    "type" "RelationshipType" NOT NULL,
    "value" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "supplier_relationships_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "rfqs" (
    "id" TEXT NOT NULL,
    "reference" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "status" "RfqStatus" NOT NULL DEFAULT 'DRAFT',
    "spec" JSONB NOT NULL,
    "free_text" TEXT,
    "suppliers_notified" INTEGER NOT NULL DEFAULT 0,
    "closes_at" TIMESTAMP(3) NOT NULL,
    "awarded_vendor_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "rfqs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bids" (
    "id" TEXT NOT NULL,
    "rfq_id" TEXT NOT NULL,
    "vendor_id" TEXT NOT NULL,
    "vendor_name" TEXT NOT NULL,
    "price_per_unit" DOUBLE PRECISION NOT NULL,
    "delivery_days" INTEGER NOT NULL,
    "trust_score_at_bid" INTEGER NOT NULL,
    "notes" TEXT,
    "submitted_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "bids_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "disruption_events" (
    "id" TEXT NOT NULL,
    "severity" "RiskLevel" NOT NULL,
    "title" TEXT NOT NULL,
    "category" "DisruptionCategory" NOT NULL,
    "region" TEXT NOT NULL,
    "summary" TEXT NOT NULL,
    "detected_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "source_url" TEXT,

    CONSTRAINT "disruption_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "disruption_targets" (
    "event_id" TEXT NOT NULL,
    "vendor_id" TEXT NOT NULL,

    CONSTRAINT "disruption_targets_pkey" PRIMARY KEY ("event_id","vendor_id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" TEXT NOT NULL,
    "vendor_id" TEXT,
    "kind" "NotificationKind" NOT NULL,
    "title" TEXT NOT NULL,
    "vendor_name" TEXT NOT NULL,
    "detail" TEXT NOT NULL,
    "read" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "vendors_email_key" ON "vendors"("email");

-- CreateIndex
CREATE UNIQUE INDEX "vendors_pan_key" ON "vendors"("pan");

-- CreateIndex
CREATE UNIQUE INDEX "vendors_gstin_key" ON "vendors"("gstin");

-- CreateIndex
CREATE UNIQUE INDEX "vendors_cin_key" ON "vendors"("cin");

-- CreateIndex
CREATE UNIQUE INDEX "vendors_udyam_number_key" ON "vendors"("udyam_number");

-- CreateIndex
CREATE INDEX "documents_vendor_id_idx" ON "documents"("vendor_id");

-- CreateIndex
CREATE INDEX "verification_records_vendor_id_type_idx" ON "verification_records"("vendor_id", "type");

-- CreateIndex
CREATE UNIQUE INDEX "trust_scores_vendor_id_key" ON "trust_scores"("vendor_id");

-- CreateIndex
CREATE INDEX "trust_history_points_vendor_id_recorded_at_idx" ON "trust_history_points"("vendor_id", "recorded_at");

-- CreateIndex
CREATE INDEX "alerts_vendor_id_idx" ON "alerts"("vendor_id");

-- CreateIndex
CREATE INDEX "vendor_events_vendor_id_at_idx" ON "vendor_events"("vendor_id", "at");

-- CreateIndex
CREATE INDEX "supplier_relationships_vendor_a_id_idx" ON "supplier_relationships"("vendor_a_id");

-- CreateIndex
CREATE INDEX "supplier_relationships_vendor_b_id_idx" ON "supplier_relationships"("vendor_b_id");

-- CreateIndex
CREATE UNIQUE INDEX "rfqs_reference_key" ON "rfqs"("reference");

-- CreateIndex
CREATE INDEX "bids_rfq_id_idx" ON "bids"("rfq_id");

-- CreateIndex
CREATE UNIQUE INDEX "bids_rfq_id_vendor_id_key" ON "bids"("rfq_id", "vendor_id");

-- CreateIndex
CREATE INDEX "disruption_events_detected_at_idx" ON "disruption_events"("detected_at");

-- CreateIndex
CREATE INDEX "notifications_read_created_at_idx" ON "notifications"("read", "created_at");

-- AddForeignKey
ALTER TABLE "documents" ADD CONSTRAINT "documents_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "verification_records" ADD CONSTRAINT "verification_records_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trust_scores" ADD CONSTRAINT "trust_scores_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trust_history_points" ADD CONSTRAINT "trust_history_points_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "alerts" ADD CONSTRAINT "alerts_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vendor_events" ADD CONSTRAINT "vendor_events_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "supplier_relationships" ADD CONSTRAINT "supplier_relationships_vendor_a_id_fkey" FOREIGN KEY ("vendor_a_id") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "supplier_relationships" ADD CONSTRAINT "supplier_relationships_vendor_b_id_fkey" FOREIGN KEY ("vendor_b_id") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bids" ADD CONSTRAINT "bids_rfq_id_fkey" FOREIGN KEY ("rfq_id") REFERENCES "rfqs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bids" ADD CONSTRAINT "bids_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "disruption_targets" ADD CONSTRAINT "disruption_targets_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "disruption_events"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "disruption_targets" ADD CONSTRAINT "disruption_targets_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_vendor_id_fkey" FOREIGN KEY ("vendor_id") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;
