-- ============================================================
-- IDT — International Diamond Trade
-- Supabase Schema
-- Run in: Supabase Dashboard → SQL Editor
-- ============================================================

-- ── 1. Listings table ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.listings (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  supplier_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  shape text NOT NULL,
  carat numeric(6,2) NOT NULL,
  color text NOT NULL,
  clarity text NOT NULL,
  cut text,
  polish text,
  symmetry text,
  fluorescence text,
  cert text NOT NULL,
  cert_num text,
  origin text,
  diamond_type text NOT NULL DEFAULT 'Natural',
  seller_name text,
  seller_country text,
  price_per_carat numeric(10,2) NOT NULL,
  total_price numeric(12,2),
  dispatch text,
  trade_terms text,
  payment_terms text,
  status text DEFAULT 'active',
  created_at timestamptz DEFAULT now()
);

-- ── 2. Enable RLS on listings ──────────────────────────────
ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;

-- ── 3. RLS Policies — listings ─────────────────────────────

-- Any authenticated user can view active listings
CREATE POLICY "Anyone authenticated can view active listings"
  ON public.listings
  FOR SELECT
  TO authenticated
  USING (status = 'active');

-- Suppliers can also view their own listings regardless of status
CREATE POLICY "Suppliers can view their own listings"
  ON public.listings
  FOR SELECT
  TO authenticated
  USING (auth.uid() = supplier_id);

-- Suppliers can insert their own listings
CREATE POLICY "Suppliers can insert own listings"
  ON public.listings
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = supplier_id);

-- Suppliers can update their own listings
CREATE POLICY "Suppliers can update own listings"
  ON public.listings
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = supplier_id)
  WITH CHECK (auth.uid() = supplier_id);

-- Suppliers can delete their own listings
CREATE POLICY "Suppliers can delete own listings"
  ON public.listings
  FOR DELETE
  TO authenticated
  USING (auth.uid() = supplier_id);

-- ── 4. Offers table ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.offers (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  listing_id uuid REFERENCES public.listings(id) ON DELETE CASCADE,
  buyer_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  buyer_email text,
  buyer_name text,
  offer_price_per_carat numeric(10,2),
  quantity_carats numeric(6,2),
  total_amount numeric(12,2),
  message text,
  escrow_transaction_id text,
  escrow_offer_url text,
  status text DEFAULT 'pending',
  created_at timestamptz DEFAULT now()
);

-- ── 5. Enable RLS on offers ────────────────────────────────
ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;

-- Buyers can insert their own offers
CREATE POLICY "Buyers can insert own offers"
  ON public.offers
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = buyer_id);

-- Buyers can view their own offers
CREATE POLICY "Buyers can view own offers"
  ON public.offers
  FOR SELECT
  TO authenticated
  USING (auth.uid() = buyer_id);

-- Suppliers can view offers on their own listings
CREATE POLICY "Suppliers can view offers on their listings"
  ON public.offers
  FOR SELECT
  TO authenticated
  USING (
    listing_id IN (
      SELECT id FROM public.listings WHERE supplier_id = auth.uid()
    )
  );

-- Admins can view all offers (requires profiles table with role column)
CREATE POLICY "Admins can view all offers"
  ON public.offers
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can update offer status
CREATE POLICY "Admins can update offer status"
  ON public.offers
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ── 6. Seed 8 demo listings (only if table is empty) ───────
INSERT INTO public.listings (
  supplier_id, shape, carat, color, clarity, cut, polish, symmetry, fluorescence,
  cert, cert_num, origin, diamond_type, seller_name, seller_country,
  price_per_carat, total_price, dispatch, trade_terms, payment_terms, status
)
SELECT
  (SELECT id FROM public.profiles WHERE role = 'supplier' LIMIT 1),
  shape, carat, color, clarity, cut, polish, symmetry, fluorescence,
  cert, cert_num, origin, diamond_type, seller_name, seller_country,
  price_per_carat, total_price, dispatch, trade_terms, payment_terms, 'active'
FROM (VALUES
  ('Round Brilliant',   2.54, 'D', 'VVS1', 'Excellent',  'Excellent',  'Excellent', 'None',   'GIA', 'GIA 6147711913', 'Botswana',    'Natural',   'Al-Rashid Gems',           'UAE',          14800, 37592, 'Immediate', 'FOB', '100% TT Advance'),
  ('Oval Cut',          3.12, 'E', 'VS1',  'Excellent',  'Very Good',  'Very Good', 'Faint',  'GIA', 'GIA 2141438741', 'South Africa','Natural',   'Cape Diamond Co.',         'South Africa', 11200, 34944, '1 Week',    'CIF', '50/50'),
  ('Emerald Cut',       5.08, 'F', 'VVS2', 'Excellent',  'Excellent',  'Excellent', 'None',   'GIA', 'GIA 5182691333', 'Russia',      'Natural',   'Alrosa Partners',          'Russia',        9400, 47752, '2 Weeks',   'EXW', 'LC at Sight'),
  ('Princess Cut',      1.85, 'G', 'VS2',  'Very Good',  'Very Good',  'Good',      'Medium', 'IGI', 'IGI 456123789',  'Canada',      'Natural',   'Canadian Diamond Exchange','Canada',        7200, 13320, '1 Week',    'DAP', '100% TT Advance'),
  ('Cushion Brilliant', 4.00, 'D', 'IF',   'Excellent',  'Excellent',  'Excellent', 'None',   'IGI', 'IGI 987654321',  'India (Lab)', 'Lab-Grown', 'Radiant Grown India',      'India',         4200, 16800, 'Immediate', 'FOB', '50/50'),
  ('Pear Shape',        1.50, 'H', 'SI1',  'Very Good',  'Good',       'Very Good', 'Strong', 'HRD', 'HRD 112233445',  'Angola',      'Natural',   'Luanda Diamond Corp',      'Angola',        5800,  8700, '1 Month',   'CIF', 'Net 30'),
  ('Round Brilliant',   0.75, 'E', 'VS1',  'Excellent',  'Excellent',  'Excellent', 'None',   'GIA', 'GIA 7251369080', 'Botswana',    'Natural',   'Al-Rashid Gems',           'UAE',           8600,  6450, 'Immediate', 'FOB', '100% TT Advance'),
  ('Marquise Cut',      2.20, 'F', 'VVS1', 'Excellent',  'Excellent',  'Excellent', 'None',   'GIA', 'GIA 6391274850', 'Zimbabwe',    'Natural',   'Harare Diamond House',     'Zimbabwe',     10400, 22880, '2 Weeks',   'EXW', 'LC at Sight')
) AS v(shape, carat, color, clarity, cut, polish, symmetry, fluorescence,
       cert, cert_num, origin, diamond_type, seller_name, seller_country,
       price_per_carat, total_price, dispatch, trade_terms, payment_terms)
WHERE NOT EXISTS (SELECT 1 FROM public.listings LIMIT 1)
  AND (SELECT id FROM public.profiles WHERE role = 'supplier' LIMIT 1) IS NOT NULL;
