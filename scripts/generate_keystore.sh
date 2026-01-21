#!/bin/bash
# ═══════════════════════════════════════════════════════════
# ANDROID KEYSTORE GENERATION SCRIPT
# ═══════════════════════════════════════════════════════════
#
# This script helps you generate a new Android signing keystore
# for Play Store releases.
#
# Usage: ./scripts/generate_keystore.sh
#
# ⚠️  IMPORTANT: 
#   - Store the keystore and passwords securely
#   - You CANNOT update your app without this keystore
#   - Back up to a secure location (password manager, vault)
# ═══════════════════════════════════════════════════════════

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "═══════════════════════════════════════════════════════════"
echo "           ANDROID KEYSTORE GENERATION"
echo "═══════════════════════════════════════════════════════════"
echo -e "${NC}"

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo -e "${RED}❌ Error: keytool not found. Please install Java JDK.${NC}"
    exit 1
fi

# Configuration
KEYSTORE_DIR="android/app"
KEYSTORE_FILE="keystore.jks"
KEYSTORE_PATH="${KEYSTORE_DIR}/${KEYSTORE_FILE}"
KEY_PROPERTIES_PATH="android/key.properties"

# Check if keystore already exists
if [ -f "$KEYSTORE_PATH" ]; then
    echo -e "${YELLOW}⚠️  Keystore already exists at ${KEYSTORE_PATH}${NC}"
    read -p "Do you want to overwrite it? (y/N): " overwrite
    if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
        echo "Aborting."
        exit 0
    fi
fi

echo ""
echo -e "${BLUE}📝 Enter keystore details:${NC}"
echo ""

# Get input from user
read -p "Key alias (default: ridelink): " KEY_ALIAS
KEY_ALIAS=${KEY_ALIAS:-ridelink}

read -p "Validity in days (default: 10000): " VALIDITY
VALIDITY=${VALIDITY:-10000}

echo ""
echo -e "${YELLOW}Now enter certificate details...${NC}"
echo ""

read -p "Your name (CN): " CN
read -p "Organizational Unit (OU): " OU
read -p "Organization (O): " O
read -p "City/Locality (L): " L
read -p "State/Province (ST): " ST
read -p "Country code (C, e.g., US, RW): " C

# Generate secure passwords
echo ""
echo -e "${BLUE}🔐 Password setup:${NC}"
echo ""

while true; do
    read -sp "Store password (min 6 chars): " STORE_PASSWORD
    echo ""
    if [ ${#STORE_PASSWORD} -lt 6 ]; then
        echo -e "${RED}Password must be at least 6 characters${NC}"
        continue
    fi
    read -sp "Confirm store password: " STORE_PASSWORD_CONFIRM
    echo ""
    if [ "$STORE_PASSWORD" = "$STORE_PASSWORD_CONFIRM" ]; then
        break
    else
        echo -e "${RED}Passwords do not match. Try again.${NC}"
    fi
done

while true; do
    read -sp "Key password (min 6 chars, or press Enter to use store password): " KEY_PASSWORD
    echo ""
    if [ -z "$KEY_PASSWORD" ]; then
        KEY_PASSWORD=$STORE_PASSWORD
        break
    fi
    if [ ${#KEY_PASSWORD} -lt 6 ]; then
        echo -e "${RED}Password must be at least 6 characters${NC}"
        continue
    fi
    read -sp "Confirm key password: " KEY_PASSWORD_CONFIRM
    echo ""
    if [ "$KEY_PASSWORD" = "$KEY_PASSWORD_CONFIRM" ]; then
        break
    else
        echo -e "${RED}Passwords do not match. Try again.${NC}"
    fi
done

# Generate keystore
echo ""
echo -e "${BLUE}🔨 Generating keystore...${NC}"

DNAME="CN=${CN}, OU=${OU}, O=${O}, L=${L}, ST=${ST}, C=${C}"

keytool -genkey -v \
    -keystore "$KEYSTORE_PATH" \
    -keyalg RSA \
    -keysize 2048 \
    -validity "$VALIDITY" \
    -alias "$KEY_ALIAS" \
    -storepass "$STORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "$DNAME"

echo ""
echo -e "${GREEN}✅ Keystore generated successfully!${NC}"
echo -e "   Location: ${KEYSTORE_PATH}"
echo ""

# Create key.properties
echo -e "${BLUE}📝 Creating key.properties...${NC}"

cat > "$KEY_PROPERTIES_PATH" << EOF
# ═══════════════════════════════════════════════════════════
# ANDROID RELEASE SIGNING CONFIGURATION
# ═══════════════════════════════════════════════════════════
# 
# ⚠️ NEVER COMMIT THIS FILE TO VERSION CONTROL ⚠️
#
# Generated on: $(date)
# ═══════════════════════════════════════════════════════════

storePassword=${STORE_PASSWORD}
keyPassword=${KEY_PASSWORD}
keyAlias=${KEY_ALIAS}
storeFile=${KEYSTORE_FILE}
EOF

echo -e "${GREEN}✅ key.properties created!${NC}"
echo ""

# Generate base64 for CI/CD
echo -e "${BLUE}🔒 Generating base64 for CI/CD...${NC}"
KEYSTORE_BASE64=$(base64 -i "$KEYSTORE_PATH")

# Show summary
echo ""
echo -e "${GREEN}"
echo "═══════════════════════════════════════════════════════════"
echo "           KEYSTORE GENERATION COMPLETE"
echo "═══════════════════════════════════════════════════════════"
echo -e "${NC}"
echo ""
echo -e "${YELLOW}📋 NEXT STEPS:${NC}"
echo ""
echo "1. Add these secrets to GitHub Actions:"
echo "   ─────────────────────────────────────"
echo "   ANDROID_KEYSTORE_BASE64: (see keystore_base64.txt)"
echo "   KEYSTORE_PASSWORD: ${STORE_PASSWORD}"
echo "   KEY_PASSWORD: ${KEY_PASSWORD}"
echo "   KEY_ALIAS: ${KEY_ALIAS}"
echo ""
echo "2. Back up these files securely:"
echo "   ─────────────────────────────────────"
echo "   - ${KEYSTORE_PATH}"
echo "   - ${KEY_PROPERTIES_PATH}"
echo ""
echo "3. Test release build:"
echo "   ─────────────────────────────────────"
echo "   flutter build appbundle --release"
echo ""

# Save base64 to file (for copying to GitHub secrets)
BASE64_FILE="keystore_base64.txt"
echo "$KEYSTORE_BASE64" > "$BASE64_FILE"
echo -e "${GREEN}✅ Base64 encoded keystore saved to: ${BASE64_FILE}${NC}"
echo -e "${RED}⚠️  Delete ${BASE64_FILE} after copying to GitHub secrets!${NC}"
echo ""
echo -e "${YELLOW}🔐 Store these credentials in a password manager!${NC}"
echo ""
