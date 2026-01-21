-- ═══════════════════════════════════════════════════════════════════════
-- MIGRATION: Mobile Money Multi-Country Support
-- Migration ID: 004_mobile_money_countries
-- Created: 2026-01-17
-- Description: Countries, networks, USSD formats for 28 African countries
-- ═══════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════
-- COUNTRIES TABLE
-- Core country reference data with currency and phone info
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS countries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code_alpha2 CHAR(2) UNIQUE NOT NULL,
    code_alpha3 CHAR(3) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    currency_symbol VARCHAR(10),
    phone_prefix VARCHAR(5) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_countries_alpha2 ON countries(code_alpha2);
CREATE INDEX IF NOT EXISTS idx_countries_alpha3 ON countries(code_alpha3);
CREATE INDEX IF NOT EXISTS idx_countries_phone_prefix ON countries(phone_prefix);
CREATE INDEX IF NOT EXISTS idx_countries_active ON countries(is_active) WHERE is_active = true;

COMMENT ON TABLE countries IS 'Reference table for supported countries with currency and phone prefix info';

-- ═══════════════════════════════════════════════════════════════════════
-- MOBILE MONEY NETWORKS TABLE
-- Payment providers per country
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS mobile_money_networks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_id UUID NOT NULL REFERENCES countries(id) ON DELETE CASCADE,
    network_name VARCHAR(100) NOT NULL,
    network_code VARCHAR(20) NOT NULL,
    short_name VARCHAR(20) NOT NULL,
    logo_url TEXT,
    is_primary BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(country_id, network_code)
);

CREATE INDEX IF NOT EXISTS idx_networks_country ON mobile_money_networks(country_id);
CREATE INDEX IF NOT EXISTS idx_networks_code ON mobile_money_networks(network_code);
CREATE INDEX IF NOT EXISTS idx_networks_active ON mobile_money_networks(is_active) WHERE is_active = true;

COMMENT ON TABLE mobile_money_networks IS 'Mobile money providers/networks per country';

-- ═══════════════════════════════════════════════════════════════════════
-- USSD DIAL FORMATS TABLE
-- USSD templates per network with placeholders
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS ussd_dial_formats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    network_id UUID NOT NULL REFERENCES mobile_money_networks(id) ON DELETE CASCADE,
    dial_template VARCHAR(100) NOT NULL,
    format_type VARCHAR(30) DEFAULT 'merchant_payment' 
        CHECK (format_type IN ('merchant_payment', 'p2p_transfer', 'balance_check', 'withdrawal')),
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(network_id, format_type)
);

CREATE INDEX IF NOT EXISTS idx_ussd_network ON ussd_dial_formats(network_id);
CREATE INDEX IF NOT EXISTS idx_ussd_type ON ussd_dial_formats(format_type);

COMMENT ON TABLE ussd_dial_formats IS 'USSD dial format templates with {MERCHANT}, {PHONE}, {AMOUNT} placeholders';
COMMENT ON COLUMN ussd_dial_formats.dial_template IS 'Template string with placeholders: {MERCHANT}, {PHONE}, {AMOUNT}';

-- ═══════════════════════════════════════════════════════════════════════
-- PAYMENT TRANSACTIONS TABLE
-- Mobile money transaction records
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS mobile_money_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    country_id UUID REFERENCES countries(id),
    network_id UUID REFERENCES mobile_money_networks(id),
    phone_number VARCHAR(20) NOT NULL,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    currency_code CHAR(3) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' 
        CHECK (status IN ('pending', 'initiated', 'processing', 'completed', 'failed', 'cancelled', 'expired')),
    ussd_string VARCHAR(150),
    merchant_code VARCHAR(50),
    reference VARCHAR(100),
    external_transaction_id VARCHAR(100),
    error_code VARCHAR(50),
    error_message TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_mm_tx_user ON mobile_money_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_mm_tx_country ON mobile_money_transactions(country_id);
CREATE INDEX IF NOT EXISTS idx_mm_tx_network ON mobile_money_transactions(network_id);
CREATE INDEX IF NOT EXISTS idx_mm_tx_status ON mobile_money_transactions(status);
CREATE INDEX IF NOT EXISTS idx_mm_tx_phone ON mobile_money_transactions(phone_number);
CREATE INDEX IF NOT EXISTS idx_mm_tx_created ON mobile_money_transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_mm_tx_reference ON mobile_money_transactions(reference);

COMMENT ON TABLE mobile_money_transactions IS 'Mobile money payment transaction records';

-- ═══════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════════════

ALTER TABLE countries ENABLE ROW LEVEL SECURITY;
ALTER TABLE mobile_money_networks ENABLE ROW LEVEL SECURITY;
ALTER TABLE ussd_dial_formats ENABLE ROW LEVEL SECURITY;
ALTER TABLE mobile_money_transactions ENABLE ROW LEVEL SECURITY;

-- Countries: publicly readable (reference data)
CREATE POLICY "Countries are publicly readable" ON countries
    FOR SELECT USING (true);

-- Networks: publicly readable (reference data)
CREATE POLICY "Networks are publicly readable" ON mobile_money_networks
    FOR SELECT USING (true);

-- USSD formats: publicly readable (reference data)
CREATE POLICY "USSD formats are publicly readable" ON ussd_dial_formats
    FOR SELECT USING (true);

-- Transactions: users can view/create own
CREATE POLICY "Users can view own transactions" ON mobile_money_transactions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create transactions" ON mobile_money_transactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Service role full access to transactions" ON mobile_money_transactions
    FOR ALL USING (auth.role() = 'service_role');

-- ═══════════════════════════════════════════════════════════════════════
-- TRIGGERS FOR UPDATED_AT
-- ═══════════════════════════════════════════════════════════════════════

CREATE TRIGGER update_countries_updated_at
    BEFORE UPDATE ON countries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_networks_updated_at
    BEFORE UPDATE ON mobile_money_networks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ussd_formats_updated_at
    BEFORE UPDATE ON ussd_dial_formats
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mm_transactions_updated_at
    BEFORE UPDATE ON mobile_money_transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ═══════════════════════════════════════════════════════════════════════
-- SEED DATA: COUNTRIES (28 African Countries)
-- ═══════════════════════════════════════════════════════════════════════
INSERT INTO countries (code_alpha2, code_alpha3, name, currency_code, currency_symbol, phone_prefix) VALUES
-- East Africa
('BI', 'BDI', 'Burundi', 'BIF', 'FBu', '+257'),
('RW', 'RWA', 'Rwanda', 'RWF', 'RF', '+250'),
('TZ', 'TZA', 'Tanzania', 'TZS', 'TSh', '+255'),
('MG', 'MDG', 'Madagascar', 'MGA', 'Ar', '+261'),
('KM', 'COM', 'Comoros', 'KMF', 'CF', '+269'),
('SC', 'SYC', 'Seychelles', 'SCR', 'SR', '+248'),
('DJ', 'DJI', 'Djibouti', 'DJF', 'Fdj', '+253'),
-- Southern Africa
('ZW', 'ZWE', 'Zimbabwe', 'ZWL', 'Z$', '+263'),
('ZM', 'ZMB', 'Zambia', 'ZMW', 'ZK', '+260'),
('MW', 'MWI', 'Malawi', 'MWK', 'MK', '+265'),
('NA', 'NAM', 'Namibia', 'NAD', 'N$', '+264'),
-- West Africa
('GH', 'GHA', 'Ghana', 'GHS', 'GH₵', '+233'),
('CM', 'CMR', 'Cameroon', 'XAF', 'FCFA', '+237'),
('BJ', 'BEN', 'Benin', 'XOF', 'CFA', '+229'),
('BF', 'BFA', 'Burkina Faso', 'XOF', 'CFA', '+226'),
('CI', 'CIV', 'Cote d''Ivoire', 'XOF', 'CFA', '+225'),
('GN', 'GIN', 'Guinea', 'GNF', 'FG', '+224'),
('ML', 'MLI', 'Mali', 'XOF', 'CFA', '+223'),
('MR', 'MRT', 'Mauritania', 'MRU', 'UM', '+222'),
('NE', 'NER', 'Niger', 'XOF', 'CFA', '+227'),
('SN', 'SEN', 'Senegal', 'XOF', 'CFA', '+221'),
('TG', 'TGO', 'Togo', 'XOF', 'CFA', '+228'),
-- Central Africa
('CF', 'CAF', 'Central African Republic', 'XAF', 'FCFA', '+236'),
('TD', 'TCD', 'Chad', 'XAF', 'FCFA', '+235'),
('CG', 'COG', 'Congo (Republic)', 'XAF', 'FCFA', '+242'),
('CD', 'COD', 'DR Congo', 'CDF', 'FC', '+243'),
('GQ', 'GNQ', 'Equatorial Guinea', 'XAF', 'FCFA', '+240'),
('GA', 'GAB', 'Gabon', 'XAF', 'FCFA', '+241')
ON CONFLICT (code_alpha2) DO NOTHING;

-- ═══════════════════════════════════════════════════════════════════════
-- SEED DATA: MOBILE MONEY NETWORKS
-- ═══════════════════════════════════════════════════════════════════════

-- Helper: Insert network and return its ID via DO block
DO $$
DECLARE
    v_country_id UUID;
    v_network_id UUID;
BEGIN
    -- BURUNDI: Econet EcoCash
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'BI';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'Econet EcoCash', 'ECOCASH', 'EcoCash', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*151*1*1*{PHONE}*{AMOUNT}#', 'merchant_payment', 'Merchant payment with phone and amount');

    -- CAMEROON: MTN MoMo
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'CM';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'MTN Mobile Money', 'MTN_MOMO', 'MTN MoMo', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*126*4*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- MADAGASCAR: Telma MVola
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'MG';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'Telma MVola', 'MVOLA', 'MVola', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '#111*4*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- RWANDA: MTN MoMo
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'RW';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'MTN Mobile Money', 'MTN_MOMO', 'MTN MoMo', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*182*8*1*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- SEYCHELLES: Airtel Money
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'SC';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'Airtel Money', 'AIRTEL_MONEY', 'Airtel', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*202*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- TANZANIA: Vodacom M-Pesa
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'TZ';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'Vodacom M-Pesa', 'MPESA', 'M-Pesa', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*150*00*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Lipa Namba');

    -- ZAMBIA: MTN MoMo
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'ZM';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'MTN Mobile Money', 'MTN_MOMO', 'MTN MoMo', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*115*5*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- ZIMBABWE: Econet EcoCash
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'ZW';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'Econet EcoCash', 'ECOCASH', 'EcoCash', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*151*2*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- MALAWI: Airtel Money
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'MW';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'Airtel Money', 'AIRTEL_MONEY', 'Airtel', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*211*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- NAMIBIA: MTC Money
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'NA';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'MTC Money', 'MTC_MONEY', 'MTC', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*140*682*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- GHANA: MTN MoMo
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'GH';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'MTN Mobile Money', 'MTN_MOMO', 'MTN MoMo', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*170*2*1*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- BENIN: MTN MoMo
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'BJ';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'MTN Mobile Money', 'MTN_MOMO', 'MTN MoMo', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*880*3*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- BURKINA FASO: Orange Money
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'BF';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'Orange Money', 'ORANGE_MONEY', 'Orange', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*144*4*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- CENTRAL AFRICAN REPUBLIC: Orange Money
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'CF';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'Orange Money', 'ORANGE_MONEY', 'Orange', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '#150*4*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- CHAD: Airtel Money
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'TD';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'Airtel Money', 'AIRTEL_MONEY', 'Airtel', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*211*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- COMOROS: Telma MVola
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'KM';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'Telma MVola', 'MVOLA', 'MVola', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*150*01*1*2*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- CONGO (REPUBLIC): MTN MoMo
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'CG';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'MTN Mobile Money', 'MTN_MOMO', 'MTN MoMo', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*133*5*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- COTE D'IVOIRE: Orange Money
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'CI';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'Orange Money', 'ORANGE_MONEY', 'Orange', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*144*4*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- DR CONGO: Orange Money
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'CD';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'Orange Money', 'ORANGE_MONEY', 'Orange', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*144*4*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- DJIBOUTI: D-Money
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'DJ';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'D-Money', 'DMONEY', 'D-Money', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*133*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- EQUATORIAL GUINEA: GETESA
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'GQ';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'GETESA Mobile Money', 'GETESA', 'GETESA', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*222*4*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- GABON: Airtel Money
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'GA';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'Airtel Money', 'AIRTEL_MONEY', 'Airtel', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*150*4*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- GUINEA: Orange Money
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'GN';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'Orange Money', 'ORANGE_MONEY', 'Orange', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*144*4*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- MALI: Orange Money
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'ML';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'Orange Money', 'ORANGE_MONEY', 'Orange', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '#144#*2*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- MAURITANIA: Moov Money
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'MR';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'Moov Money', 'MOOV_MONEY', 'Moov', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*900*4*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- NIGER: Airtel Money
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'NE';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'Airtel Money', 'AIRTEL_MONEY', 'Airtel', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*400*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- SENEGAL: Orange Money
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'SN';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'Orange Money', 'ORANGE_MONEY', 'Orange', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '#144*2*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

    -- TOGO: T-Money
    SELECT id INTO v_country_id FROM countries WHERE code_alpha2 = 'TG';
    INSERT INTO mobile_money_networks (country_id, network_name, network_code, short_name, is_primary)
    VALUES (v_country_id, 'T-Money', 'TMONEY', 'T-Money', true)
    RETURNING id INTO v_network_id;
    INSERT INTO ussd_dial_formats (network_id, dial_template, format_type, description)
    VALUES (v_network_id, '*145*3*{MERCHANT}*{AMOUNT}#', 'merchant_payment', 'Merchant payment');

END $$;

-- ═══════════════════════════════════════════════════════════════════════
-- DATABASE FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════

-- Function: Generate USSD dial string from template
CREATE OR REPLACE FUNCTION generate_ussd_dial_string(
    p_network_id UUID,
    p_merchant_code VARCHAR,
    p_amount DECIMAL,
    p_phone VARCHAR DEFAULT NULL,
    p_format_type VARCHAR DEFAULT 'merchant_payment'
)
RETURNS TEXT AS $$
DECLARE
    v_template VARCHAR;
    v_result TEXT;
BEGIN
    SELECT dial_template INTO v_template
    FROM ussd_dial_formats
    WHERE network_id = p_network_id 
      AND format_type = p_format_type
      AND is_active = true
    LIMIT 1;

    IF v_template IS NULL THEN
        RETURN NULL;
    END IF;

    v_result := v_template;
    v_result := REPLACE(v_result, '{MERCHANT}', COALESCE(p_merchant_code, ''));
    v_result := REPLACE(v_result, '{AMOUNT}', p_amount::TEXT);
    v_result := REPLACE(v_result, '{PHONE}', COALESCE(p_phone, ''));

    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION generate_ussd_dial_string IS 'Generate USSD dial string by replacing template placeholders';

-- Function: Detect country from phone number prefix
CREATE OR REPLACE FUNCTION detect_country_from_phone(p_phone VARCHAR)
RETURNS TABLE (
    country_id UUID,
    code_alpha2 CHAR(2),
    code_alpha3 CHAR(3),
    country_name VARCHAR,
    phone_prefix VARCHAR
) AS $$
DECLARE
    v_cleaned VARCHAR;
BEGIN
    -- Remove non-digit characters except leading +
    v_cleaned := regexp_replace(p_phone, '[^0-9+]', '', 'g');
    
    -- Ensure starts with +
    IF NOT v_cleaned LIKE '+%' THEN
        v_cleaned := '+' || v_cleaned;
    END IF;

    RETURN QUERY
    SELECT 
        c.id,
        c.code_alpha2::CHAR(2),
        c.code_alpha3::CHAR(3),
        c.name::VARCHAR,
        c.phone_prefix::VARCHAR
    FROM countries c
    WHERE v_cleaned LIKE c.phone_prefix || '%'
    AND c.is_active = true
    ORDER BY LENGTH(c.phone_prefix) DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION detect_country_from_phone IS 'Detect country from international phone number prefix';

-- Function: Get primary network for a country
CREATE OR REPLACE FUNCTION get_primary_network(p_country_code VARCHAR)
RETURNS TABLE (
    network_id UUID,
    network_name VARCHAR,
    network_code VARCHAR,
    short_name VARCHAR,
    dial_template VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        n.id,
        n.network_name::VARCHAR,
        n.network_code::VARCHAR,
        n.short_name::VARCHAR,
        u.dial_template::VARCHAR
    FROM mobile_money_networks n
    JOIN countries c ON c.id = n.country_id
    LEFT JOIN ussd_dial_formats u ON u.network_id = n.id AND u.format_type = 'merchant_payment'
    WHERE (c.code_alpha2 = UPPER(p_country_code) OR c.code_alpha3 = UPPER(p_country_code))
    AND n.is_primary = true
    AND n.is_active = true
    LIMIT 1;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_primary_network IS 'Get primary mobile money network for a country by ISO code';

-- Function: Get all networks for a country
CREATE OR REPLACE FUNCTION get_networks_for_country(p_country_code VARCHAR)
RETURNS TABLE (
    network_id UUID,
    network_name VARCHAR,
    network_code VARCHAR,
    short_name VARCHAR,
    is_primary BOOLEAN,
    dial_template VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        n.id,
        n.network_name::VARCHAR,
        n.network_code::VARCHAR,
        n.short_name::VARCHAR,
        n.is_primary,
        u.dial_template::VARCHAR
    FROM mobile_money_networks n
    JOIN countries c ON c.id = n.country_id
    LEFT JOIN ussd_dial_formats u ON u.network_id = n.id AND u.format_type = 'merchant_payment'
    WHERE (c.code_alpha2 = UPPER(p_country_code) OR c.code_alpha3 = UPPER(p_country_code))
    AND n.is_active = true
    ORDER BY n.is_primary DESC, n.network_name;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_networks_for_country IS 'Get all active mobile money networks for a country';
