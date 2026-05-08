-- ============================================================
-- IDT — Enquiries table + RLS policies
-- Run in: Supabase Dashboard → SQL Editor
-- ============================================================

-- ── 1. Enquiries table ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.enquiries (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  listing_id uuid REFERENCES public.listings(id) ON DELETE CASCADE,
  buyer_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  supplier_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  contact_name text,
  company_name text,
  email text,
  quantity_needed text,
  budget text,
  message text,
  response_message text,
  responded_at timestamptz,
  status text DEFAULT 'new',
  created_at timestamptz DEFAULT now()
);

-- ── 2. Enable RLS ──────────────────────────────────────────
ALTER TABLE public.enquiries ENABLE ROW LEVEL SECURITY;

-- ── 3. RLS Policies ────────────────────────────────────────

-- Buyers can insert their own enquiries
CREATE POLICY "Buyers can insert own enquiries"
  ON public.enquiries
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = buyer_id);

-- Buyers can view their own enquiries
CREATE POLICY "Buyers can view own enquiries"
  ON public.enquiries
  FOR SELECT
  TO authenticated
  USING (auth.uid() = buyer_id);

-- Suppliers can view enquiries directed to them
CREATE POLICY "Suppliers can view their enquiries"
  ON public.enquiries
  FOR SELECT
  TO authenticated
  USING (auth.uid() = supplier_id);

-- Suppliers can update enquiries directed to them (to respond / mark as read)
CREATE POLICY "Suppliers can update their enquiries"
  ON public.enquiries
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = supplier_id)
  WITH CHECK (auth.uid() = supplier_id);

-- Admins can view all enquiries
CREATE POLICY "Admins can view all enquiries"
  ON public.enquiries
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can update all enquiries
CREATE POLICY "Admins can update all enquiries"
  ON public.enquiries
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
