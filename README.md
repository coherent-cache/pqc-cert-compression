# PQC Certificate Compression Benchmark

A benchmarking tool for measuring compression algorithms (zstd, zlib, brotli) on MLKEM certificates of different sizes.

## Features

- Generates MLKEM certificates (512, 768, 1024 bit)
- Benchmarks compression with zstd, zlib, and brotli
- Docker-based reproducible environment
- Rust implementation for performance
- JSON output for further analysis

## Usage

### Using Docker

```bash
# Build the Docker image
docker build -t pqc-cert-compression .

# Generate certificates and run benchmarks
docker run --rm -v "$(pwd):/app" pqc-cert-compression bash -c "cd /app && ./generate_certs.sh && cargo run --release"
```

### Manual Setup

1. Install Rust and required system dependencies
2. Install OpenSSL with MLKEM support
3. Run the certificate generation script
4. Build and run the benchmark

## Output

The tool produces:
- Console table with compression results
- `benchmark_results.json` with detailed metrics

## Algorithms Tested

- **zstd**: Facebook's Zstandard compression
- **zlib**: DEFLATE-based compression
- **brotli**: Google's Brotli compression

## MLKEM Variants

- MLKEM-512 (128-bit security)
- MLKEM-768 (192-bit security)  
- MLKEM-1024 (256-bit security)