-- ============================================================
-- IDT — Add stage, escrow_payment_url, agreed_price to enquiries
-- Run in: Supabase Dashboard → SQL Editor
-- ============================================================

ALTER TABLE public.enquiries
  ADD COLUMN IF NOT EXISTS stage text DEFAULT 'enquiry_sent',
  ADD COLUMN IF NOT EXISTS escrow_payment_url text,
  ADD COLUMN IF NOT EXISTS agreed_price numeric;

-- Backfill existing rows
UPDATE public.enquiries SET stage = 'enquiry_sent' WHERE stage IS NULL;

-- RLS: Admins can update stage/escrow fields (already covered by existing admin update policy)
-- No new policies needed — existing policies cover the new columns.
