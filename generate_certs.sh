#!/bin/bash

# Generate MLKEM certificates for different key sizes using CA approach
set -e

echo "Generating MLKEM certificates..."

# Create certificates directory
mkdir -p certs

# Use custom OpenSSL 3.6.0 installation
OPENSSL_CMD="/usr/local/ssl/bin/openssl"
export LD_LIBRARY_PATH="/usr/local/ssl/lib:$LD_LIBRARY_PATH"

echo "Using custom OpenSSL 3.6.0 with MLKEM support..."
$OPENSSL_CMD version

# Check MLKEM algorithm availability
echo "Checking MLKEM algorithms..."
$OPENSSL_CMD list -public-key-algorithms | grep -i kem || {
    echo "ERROR: MLKEM algorithms not found. Checking available algorithms:"
    $OPENSSL_CMD list -public-key-algorithms
    exit 1
}

# Generate CA using ML-DSA (supported for signing)
echo "Generating ML-DSA CA for certificate signing..."

# Use ML-DSA-87 (higher security level)
$OPENSSL_CMD genpkey -algorithm ml-dsa-87 -out certs/ca.mldsa.key

# Create CA extensions
cat > certs/ca_ext.cnf <<'EOF'
[v3_ca]
basicConstraints = critical, CA:TRUE, pathlen:0
keyUsage = critical, keyCertSign, cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
EOF

# Self-signed CA certificate
$OPENSSL_CMD req -new -x509 \
    -key certs/ca.mldsa.key \
    -subj "/CN=Test ML-DSA CA" \
    -days 3650 \
    -out certs/ca.mldsa.crt \
    -config certs/ca_ext.cnf -extensions v3_ca

echo "CA certificate generated successfully"

# Generate ML-KEM certificates for each key size
for kem_size in 512 768 1024; do
    echo ""
    echo "Generating ML-KEM-${kem_size} key pair..."
    
    # Generate ML-KEM key pair
    $OPENSSL_CMD genpkey -algorithm ml-kem-${kem_size} -out certs/mlkem${kem_size}.key
    
    # Extract public key
    $OPENSSL_CMD pkey -in certs/mlkem${kem_size}.key -pubout -out certs/mlkem${kem_size}.pub
    
    echo "Creating ML-KEM-${kem_size} certificate with KEM public key..."
    
    # Create EE extensions for KEM key
    cat > certs/ee_ext_${kem_size}.cnf <<EOF
[v3_ee_kem]
basicConstraints = CA:FALSE
keyUsage = critical, keyEncipherment
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
EOF
    
    # Issue certificate with KEM public key (using force_pubkey)
    $OPENSSL_CMD x509 -new \
        -CA certs/ca.mldsa.crt -CAkey certs/ca.mldsa.key -CAcreateserial \
        -subj "/CN=End-Entity ML-KEM-${kem_size}" \
        -days 825 \
        -force_pubkey certs/mlkem${kem_size}.pub \
        -out certs/mlkem${kem_size}.crt \
        -extfile certs/ee_ext_${kem_size}.cnf -extensions v3_ee_kem
    
    # Verify certificate
    $OPENSSL_CMD verify -CAfile certs/ca.mldsa.crt certs/mlkem${kem_size}.crt
    
    echo "✓ ML-KEM-${kem_size} certificate and key generated"
    
    # Check sizes
    cert_size=$(wc -c < "certs/mlkem${kem_size}.crt")
    key_size=$(wc -c < "certs/mlkem${kem_size}.key")
    echo "  Certificate size: ${cert_size} bytes"
    echo "  Private key size: ${key_size} bytes"
    
    # Display certificate info
    $OPENSSL_CMD x509 -in "certs/mlkem${kem_size}.crt" -noout -text | grep -A5 "Public Key Algorithm" || echo "  Certificate contains ML-KEM public key"
    
    echo ""
done

echo "MLKEM certificate generation complete."
ls -la certs/