#!/bin/bash

# Generate MLKEM certificates for different key sizes
set -e

echo "Generating MLKEM certificates..."

# Create certificates directory
mkdir -p certs

# Check if MLKEM is supported
echo "Checking MLKEM support in OpenSSL..."
/usr/local/ssl/bin/openssl list -public-key-algorithms | grep -i mlkem || {
    echo "MLKEM not found in OpenSSL, checking available algorithms..."
    /usr/local/ssl/bin/openssl list -public-key-algorithms
}

# Generate MLKEM-512 certificate
echo "Generating MLKEM-512 certificate..."
/usr/local/ssl/bin/openssl req -new -x509 -nodes -days 365 -newkey ml-kem-512 \
    -keyout certs/mlkem512.key -out certs/mlkem512.crt \
    -subj "/CN=MLKEM-512 Test" || {
    echo "Trying alternative MLKEM-512 syntax..."
    /usr/local/ssl/bin/openssl req -new -x509 -nodes -days 365 -newkey mlkem512 \
        -keyout certs/mlkem512.key -out certs/mlkem512.crt \
        -subj "/CN=MLKEM-512 Test"
}

# Generate MLKEM-768 certificate  
echo "Generating MLKEM-768 certificate..."
/usr/local/ssl/bin/openssl req -new -x509 -nodes -days 365 -newkey ml-kem-768 \
    -keyout certs/mlkem768.key -out certs/mlkem768.crt \
    -subj "/CN=MLKEM-768 Test" || {
    echo "Trying alternative MLKEM-768 syntax..."
    /usr/local/ssl/bin/openssl req -new -x509 -nodes -days 365 -newkey mlkem768 \
        -keyout certs/mlkem768.key -out certs/mlkem768.crt \
        -subj "/CN=MLKEM-768 Test"
}

# Generate MLKEM-1024 certificate
echo "Generating MLKEM-1024 certificate..."
/usr/local/ssl/bin/openssl req -new -x509 -nodes -days 365 -newkey ml-kem-1024 \
    -keyout certs/mlkem1024.key -out certs/mlkem1024.crt \
    -subj "/CN=MLKEM-1024 Test" || {
    echo "Trying alternative MLKEM-1024 syntax..."
    /usr/local/ssl/bin/openssl req -new -x509 -nodes -days 365 -newkey mlkem1024 \
        -keyout certs/mlkem1024.key -out certs/mlkem1024.crt \
        -subj "/CN=MLKEM-1024 Test"
}

# Verify certificates were created
echo "Verifying generated certificates..."
for cert in mlkem512 mlkem768 mlkem1024; do
    if [ -f "certs/${cert}.crt" ]; then
        echo "✓ ${cert}.crt created successfully"
        /usr/local/ssl/bin/openssl x509 -in "certs/${cert}.crt" -text -noout | grep -i "public key algorithm"
    else
        echo "✗ ${cert}.crt not found"
    fi
done

echo "Certificate generation complete."
ls -la certs/