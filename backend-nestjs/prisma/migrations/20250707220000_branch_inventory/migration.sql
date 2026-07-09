-- AlterTable
ALTER TABLE "inventory_movements" ADD COLUMN "branch_id" TEXT;

-- CreateIndex
CREATE INDEX "inventory_movements_product_id_branch_id_idx" ON "inventory_movements"("product_id", "branch_id");

-- AddForeignKey
ALTER TABLE "inventory_movements" ADD CONSTRAINT "inventory_movements_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Assign legacy movements to the main branch
UPDATE "inventory_movements"
SET "branch_id" = (
  SELECT "id" FROM "branches" WHERE "is_main" = true ORDER BY "sort_order" ASC LIMIT 1
)
WHERE "branch_id" IS NULL;
