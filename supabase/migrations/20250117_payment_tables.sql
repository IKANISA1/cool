-- ═══════════════════════════════════════════════════════════════════════
-- PAYMENT TABLES MIGRATION
-- Sub-Saharan Africa Mobility Platform
-- Created: 2025-01-17
-- ═══════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════
-- NFC TAGS TABLE - Registered NFC tags for payments and identity
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS nfc_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    tag_id VARCHAR(100) UNIQUE NOT NULL,
    tag_type VARCHAR(20) CHECK (tag_type IN ('payment', 'identity', 'vehicle')),
    label VARCHAR(100), -- User-friendly name like "My Payment Card"
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_nfc_tags_user ON nfc_tags(user_id);
CREATE INDEX idx_nfc_tags_tag_id ON nfc_tags(tag_id);

-- ═══════════════════════════════════════════════════════════════════════
-- PAYMENT TRANSACTIONS TABLE - All payment records
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_user UUID REFERENCES users(id),
    to_user UUID REFERENCES users(id),
    amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'RWF',
    payment_method VARCHAR(20) CHECK (payment_method IN ('nfc', 'qr', 'mobile_money', 'cash')),
    status VARCHAR(20) CHECK (status IN ('pending', 'completed', 'failed', 'refunded', 'cancelled')),
    ride_request_id UUID REFERENCES ride_requests(id),
    nfc_tag_id UUID REFERENCES nfc_tags(id),
    metadata JSONB,
    failure_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_transactions_from ON transactions(from_user);
CREATE INDEX idx_transactions_to ON transactions(to_user);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_created ON transactions(created_at DESC);
CREATE INDEX idx_transactions_ride ON transactions(ride_request_id);

-- ═══════════════════════════════════════════════════════════════════════
-- QR CODES TABLE - Generated QR codes for various purposes
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS qr_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    code_type VARCHAR(20) CHECK (code_type IN ('payment', 'identity', 'trip', 'promo')),
    payload TEXT NOT NULL,
    amount DECIMAL(12,2), -- For payment QR codes
    currency VARCHAR(3) DEFAULT 'RWF',
    expires_at TIMESTAMP WITH TIME ZONE,
    is_single_use BOOLEAN DEFAULT false,
    is_used BOOLEAN DEFAULT false,
    used_at TIMESTAMP WITH TIME ZONE,
    used_by UUID REFERENCES users(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_qr_codes_user ON qr_codes(user_id);
CREATE INDEX idx_qr_codes_payload ON qr_codes(payload);
CREATE INDEX idx_qr_codes_type ON qr_codes(code_type);
CREATE INDEX idx_qr_codes_expires ON qr_codes(expires_at) WHERE expires_at IS NOT NULL;

-- ═══════════════════════════════════════════════════════════════════════
-- WALLETS TABLE - User balance tracking
-- ═══════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    balance DECIMAL(12,2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'RWF',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_wallets_user ON wallets(user_id);

-- ═══════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════════════

ALTER TABLE nfc_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

-- NFC Tags policies
CREATE POLICY "Users can view own NFC tags" ON nfc_tags
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own NFC tags" ON nfc_tags
    FOR ALL USING (auth.uid() = user_id);

-- Transactions policies
CREATE POLICY "Users can view own transactions" ON transactions
    FOR SELECT USING (auth.uid() IN (from_user, to_user));

CREATE POLICY "Users can create transactions as sender" ON transactions
    FOR INSERT WITH CHECK (auth.uid() = from_user);

-- QR Codes policies
CREATE POLICY "Users can view own QR codes" ON qr_codes
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own QR codes" ON qr_codes
    FOR ALL USING (auth.uid() = user_id);

-- Public can view active payment QR codes (for scanning)
CREATE POLICY "Public can view active payment QR codes" ON qr_codes
    FOR SELECT USING (
        code_type = 'payment' 
        AND is_active = true 
        AND (expires_at IS NULL OR expires_at > NOW())
        AND (is_single_use = false OR is_used = false)
    );

-- Wallets policies
CREATE POLICY "Users can view own wallet" ON wallets
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own wallet" ON wallets
    FOR UPDATE USING (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════════════════
-- REALTIME CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════════

ALTER PUBLICATION supabase_realtime ADD TABLE transactions;
ALTER PUBLICATION supabase_realtime ADD TABLE wallets;

ALTER TABLE transactions REPLICA IDENTITY FULL;
ALTER TABLE wallets REPLICA IDENTITY FULL;

-- ═══════════════════════════════════════════════════════════════════════
-- DATABASE FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════

-- Function to create a new wallet for a user
CREATE OR REPLACE FUNCTION create_user_wallet()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO wallets (user_id, balance, currency)
    VALUES (NEW.id, 0, 'RWF')
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create wallet on user creation
CREATE OR REPLACE TRIGGER on_user_created_wallet
    AFTER INSERT ON users
    FOR EACH ROW EXECUTE PROCEDURE create_user_wallet();

-- Function to process a payment transaction
CREATE OR REPLACE FUNCTION process_payment(
    p_from_user UUID,
    p_to_user UUID,
    p_amount DECIMAL,
    p_currency VARCHAR DEFAULT 'RWF',
    p_method VARCHAR DEFAULT 'nfc',
    p_ride_request_id UUID DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_from_balance DECIMAL;
    v_transaction_id UUID;
    v_result JSONB;
BEGIN
    -- Check sender balance
    SELECT balance INTO v_from_balance
    FROM wallets
    WHERE user_id = p_from_user AND currency = p_currency;
    
    IF v_from_balance IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Sender wallet not found'
        );
    END IF;
    
    IF v_from_balance < p_amount THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Insufficient balance'
        );
    END IF;
    
    -- Create transaction record
    INSERT INTO transactions (
        from_user, to_user, amount, currency, payment_method,
        status, ride_request_id, metadata
    )
    VALUES (
        p_from_user, p_to_user, p_amount, p_currency, p_method,
        'pending', p_ride_request_id, p_metadata
    )
    RETURNING id INTO v_transaction_id;
    
    -- Deduct from sender
    UPDATE wallets
    SET balance = balance - p_amount,
        updated_at = NOW()
    WHERE user_id = p_from_user AND currency = p_currency;
    
    -- Add to receiver
    UPDATE wallets
    SET balance = balance + p_amount,
        updated_at = NOW()
    WHERE user_id = p_to_user AND currency = p_currency;
    
    -- Mark transaction as completed
    UPDATE transactions
    SET status = 'completed',
        completed_at = NOW()
    WHERE id = v_transaction_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'transaction_id', v_transaction_id
    );
    
EXCEPTION WHEN OTHERS THEN
    -- Mark transaction as failed if it exists
    IF v_transaction_id IS NOT NULL THEN
        UPDATE transactions
        SET status = 'failed',
            failure_reason = SQLERRM
        WHERE id = v_transaction_id;
    END IF;
    
    RETURN jsonb_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user transaction history
CREATE OR REPLACE FUNCTION get_transaction_history(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    direction VARCHAR,
    other_user JSONB,
    amount DECIMAL,
    currency VARCHAR,
    payment_method VARCHAR,
    status VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        CASE 
            WHEN t.from_user = p_user_id THEN 'sent'::VARCHAR
            ELSE 'received'::VARCHAR
        END AS direction,
        CASE 
            WHEN t.from_user = p_user_id THEN row_to_json(p2.*)::JSONB
            ELSE row_to_json(p1.*)::JSONB
        END AS other_user,
        t.amount,
        t.currency,
        t.payment_method,
        t.status,
        t.created_at
    FROM transactions t
    LEFT JOIN profiles p1 ON p1.id = t.from_user
    LEFT JOIN profiles p2 ON p2.id = t.to_user
    WHERE t.from_user = p_user_id OR t.to_user = p_user_id
    ORDER BY t.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════
-- UPDATE TRIGGERS
-- ═══════════════════════════════════════════════════════════════════════

CREATE TRIGGER update_nfc_tags_updated_at
    BEFORE UPDATE ON nfc_tags
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_wallets_updated_at
    BEFORE UPDATE ON wallets
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
