# PQC Certificate Compression Benchmark

A comprehensive benchmarking tool for measuring compression algorithms (zstd, zlib, brotli) on actual MLKEM certificates of different security levels.

## Features

- Generates **actual MLKEM certificates** (512, 768, 1024 security levels)
- Benchmarks compression with zstd, zlib, and brotli
- Docker-based reproducible environment with OpenSSL 3.6.0
- Rust implementation for performance
- JSON output and comprehensive markdown analysis

## Quick Start

```bash
# Build MLKEM-enabled Docker image
docker build -t pqc-cert-compression-mlkem .

# Generate MLKEM certificates and run benchmarks
docker run --rm -v "$(pwd):/app" pqc-cert-compression-mlkem bash -c "cd /app && ./generate_certs.sh && cargo run --release"

# View results
cat results.md
```



## Requirements

- Docker with build support
- Git for cloning repository
- Sufficient disk space (~500MB for Docker image + certificates)

## Architecture

### Certificate Generation
- **OpenSSL 3.6.0** with MLKEM algorithm support
- **ML-DSA-87** Certificate Authority for signing
- **ML-KEM** key pairs (512, 768, 1024 security levels)
- **X.509** certificates with ML-KEM public keys

### Compression Algorithms
- **zstd**: Facebook's Zstandard (level 3)
- **zlib**: DEFLATE-based compression (default level)  
- **brotli**: Google's Brotli (default parameters)

## Output Files

- `certs/mlkem*.crt` - Generated MLKEM certificates
- `certs/mlkem*.key` - MLKEM private keys
- `certs/ca.mldsa.*` - Certificate Authority files
- `benchmark_results.json` - Machine-readable results
- `results.md` - Comprehensive analysis and recommendations

## Benchmark Results Summary

The latest benchmarks show:

| Certificate | Security Level | Original Size | Best Compressed | Compression Ratio |
|-------------|----------------|----------------|------------------|-------------------|
| mlkem512.crt | 128-bit | 7,777 bytes | 5,854 bytes (brotli) | 0.753 |
| mlkem768.crt | 192-bit | 8,297 bytes | 6,250 bytes (brotli) | 0.753 |
| mlkem1024.crt | 256-bit | 8,821 bytes | 6,648 bytes (brotli) | 0.754 |

**Winner**: Brotli consistently provides the best compression ratio (~25% size reduction)

## MLKEM Security Levels

- **MLKEM-512**: 128-bit security level (7,777 bytes)
- **MLKEM-768**: 192-bit security level (8,297 bytes)
- **MLKEM-1024**: 256-bit security level (8,821 bytes)



## Manual Setup (Advanced)

For non-Docker setups:

1. Install **OpenSSL 3.6.0** with MLKEM support
2. Install **Rust** toolchain
3. Install system dependencies: `libssl-dev libzstd-dev libbrotli-dev`
4. Run certificate generation: `./generate_certs.sh`
5. Build benchmark: `cargo build --release`
6. Run: `cargo run --release`

## Analysis and Recommendations

See [`results.md`](results.md) for:
- Detailed algorithm performance analysis
- Security level recommendations
- Production deployment guidance
- Network transmission optimization strategies
- Future considerations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add new compression algorithms or certificate types
4. Update documentation
5. Submit a pull request

## License

This project is provided for research and educational purposes. Use appropriate security practices in production deployments.

---

*Last updated: December 28, 2025*