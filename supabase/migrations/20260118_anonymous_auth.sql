-- Create whatsapp_info table
CREATE TABLE IF NOT EXISTS public.whatsapp_info (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  phone_number TEXT NOT NULL,
  country_code TEXT NOT NULL,
  country_name TEXT NOT NULL,
  dial_code TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Ensure one WhatsApp number per user
  CONSTRAINT unique_user_whatsapp UNIQUE (user_id)
);

-- Create index for faster lookups
CREATE INDEX idx_whatsapp_info_user_id ON public.whatsapp_info(user_id);

-- Enable Row Level Security
ALTER TABLE public.whatsapp_info ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own WhatsApp info
CREATE POLICY "Users can view own whatsapp_info"
ON public.whatsapp_info
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Policy: Users can insert their own WhatsApp info
CREATE POLICY "Users can insert own whatsapp_info"
ON public.whatsapp_info
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own WhatsApp info
CREATE POLICY "Users can update own whatsapp_info"
ON public.whatsapp_info
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own WhatsApp info
CREATE POLICY "Users can delete own whatsapp_info"
ON public.whatsapp_info
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS '
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
' LANGUAGE plpgsql;

-- Trigger for whatsapp_info table
DROP TRIGGER IF EXISTS set_updated_at ON public.whatsapp_info;
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON public.whatsapp_info
FOR EACH ROW
EXECUTE FUNCTION public.handle_updated_at();
