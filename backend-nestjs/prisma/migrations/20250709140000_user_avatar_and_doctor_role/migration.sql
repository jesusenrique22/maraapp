-- avatar_url en users + rol DOCTOR (faltaban en migraciones anteriores)
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "avatar_url" TEXT;

ALTER TYPE "UserRole" ADD VALUE IF NOT EXISTS 'DOCTOR';
