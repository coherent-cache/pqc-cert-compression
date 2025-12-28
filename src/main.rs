use std::fs;
use std::path::Path;
use std::io::Write;
use zstd;
use flate2::write::GzEncoder;
use flate2::Compression;
use brotli;
use serde::{Deserialize, Serialize};
use clap::Parser;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Directory containing certificates
    #[arg(short, long, default_value = "certs")]
    cert_dir: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct CompressionResult {
    algorithm: String,
    original_size: usize,
    compressed_size: usize,
    compression_ratio: f64,
}

#[derive(Debug, Serialize, Deserialize)]
struct BenchmarkResult {
    certificate: String,
    key_size: String,
    results: Vec<CompressionResult>,
}

fn compress_zstd(data: &[u8]) -> Vec<u8> {
    zstd::encode_all(data, 3).unwrap()
}

fn compress_zlib(data: &[u8]) -> Vec<u8> {
    let mut encoder = GzEncoder::new(Vec::new(), Compression::default());
    encoder.write_all(data).unwrap();
    encoder.finish().unwrap()
}

fn compress_brotli(data: &[u8]) -> Vec<u8> {
    let mut input = data;
    let mut output = Vec::new();
    brotli::BrotliCompress(&mut input, &mut output, &brotli::enc::BrotliEncoderParams::default()).unwrap();
    output
}

fn benchmark_certificate(cert_path: &Path, key_size: &str) -> BenchmarkResult {
    let cert_data = fs::read(cert_path).expect("Failed to read certificate");
    let original_size = cert_data.len();
    
    let mut results = Vec::new();
    
    // Zstd compression
    let zstd_compressed = compress_zstd(&cert_data);
    results.push(CompressionResult {
        algorithm: "zstd".to_string(),
        original_size,
        compressed_size: zstd_compressed.len(),
        compression_ratio: zstd_compressed.len() as f64 / original_size as f64,
    });
    
    // Zlib compression
    let zlib_compressed = compress_zlib(&cert_data);
    results.push(CompressionResult {
        algorithm: "zlib".to_string(),
        original_size,
        compressed_size: zlib_compressed.len(),
        compression_ratio: zlib_compressed.len() as f64 / original_size as f64,
    });
    
    // Brotli compression
    let brotli_compressed = compress_brotli(&cert_data);
    results.push(CompressionResult {
        algorithm: "brotli".to_string(),
        original_size,
        compressed_size: brotli_compressed.len(),
        compression_ratio: brotli_compressed.len() as f64 / original_size as f64,
    });
    
    BenchmarkResult {
        certificate: cert_path.file_name().unwrap().to_string_lossy().to_string(),
        key_size: key_size.to_string(),
        results,
    }
}

fn print_results_table(results: &[BenchmarkResult]) {
    println!("\nCertificate Compression Benchmark Results");
    println!("==========================================");
    println!("{:<15} {:<10} {:<12} {:<12} {:<12} {:<12}", 
             "Certificate", "Key Size", "Original", "Zstd", "Zlib", "Brotli");
    println!("{:<15} {:<10} {:<12} {:<12} {:<12} {:<12}", 
             "Name", "(bits)", "Size (bytes)", "Size (bytes)", "Size (bytes)", "Size (bytes)");
    println!("{}", "-".repeat(85));
    
    for result in results {
        let zstd_result = result.results.iter().find(|r| r.algorithm == "zstd").unwrap();
        let zlib_result = result.results.iter().find(|r| r.algorithm == "zlib").unwrap();
        let brotli_result = result.results.iter().find(|r| r.algorithm == "brotli").unwrap();
        
        println!("{:<15} {:<10} {:<12} {:<12} {:<12} {:<12}",
                 result.certificate,
                 result.key_size,
                 zstd_result.original_size,
                 zstd_result.compressed_size,
                 zlib_result.compressed_size,
                 brotli_result.compressed_size);
    }
    
    println!("\nCompression Ratios (compressed/original):");
    println!("{:<15} {:<10} {:<12} {:<12} {:<12}", 
             "Certificate", "Key Size", "Zstd", "Zlib", "Brotli");
    println!("{}", "-".repeat(55));
    
    for result in results {
        let zstd_result = result.results.iter().find(|r| r.algorithm == "zstd").unwrap();
        let zlib_result = result.results.iter().find(|r| r.algorithm == "zlib").unwrap();
        let brotli_result = result.results.iter().find(|r| r.algorithm == "brotli").unwrap();
        
        println!("{:<15} {:<10} {:<12.3} {:<12.3} {:<12.3}",
                 result.certificate,
                 result.key_size,
                 zstd_result.compression_ratio,
                 zlib_result.compression_ratio,
                 brotli_result.compression_ratio);
    }
}

fn main() {
    let args = Args::parse();
    
    let cert_dir = Path::new(&args.cert_dir);
    
    if !cert_dir.exists() {
        eprintln!("Certificate directory '{}' does not exist", args.cert_dir);
        eprintln!("Please run ./generate_certs.sh first");
        std::process::exit(1);
    }
    
    let mut results = Vec::new();
    
    // Look for certificate files
    let cert_files = [
        ("sample512.crt", "512"),
        ("sample768.crt", "768"), 
        ("sample1024.crt", "1024"),
        ("mlkem512.crt", "512"),
        ("mlkem768.crt", "768"),
        ("mlkem1024.crt", "1024"),
    ];
    
    for (cert_file, key_size) in &cert_files {
        let cert_path = cert_dir.join(cert_file);
        if cert_path.exists() {
            println!("Benchmarking {}...", cert_file);
            let result = benchmark_certificate(&cert_path, key_size);
            results.push(result);
        } else {
            println!("Warning: {} not found", cert_file);
        }
    }
    
    if results.is_empty() {
        eprintln!("No certificates found to benchmark");
        std::process::exit(1);
    }
    
    print_results_table(&results);
    
    // Save results to JSON
    let json_output = serde_json::to_string_pretty(&results).unwrap();
    fs::write("benchmark_results.json", json_output).unwrap();
    println!("\nResults saved to benchmark_results.json");
}