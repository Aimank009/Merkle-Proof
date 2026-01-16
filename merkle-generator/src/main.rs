use rs_merkle::{Hasher, MerkleTree};
use serde::{Deserialize, Serialize};
use std::fs;
use tiny_keccak::{Hasher as keccakHasher, Keccak};

#[derive(Clone)]
pub struct Keccak256;

impl Hasher for Keccak256 {
    type Hash = [u8; 32];

    fn hash(data: &[u8]) -> Self::Hash {
        let mut keccak = Keccak::v256();
        let mut output = [0u8; 32];
        keccak.update(data);
        keccak.finalize(&mut output);
        output
    }
}

#[derive(Deserialize)]
struct Whitelist {
    addresses: Vec<String>,
}

#[derive(Serialize)]
struct ProofOutput {
    address: String,
    proof: Vec<String>,
}

#[derive(Serialize)]
struct Output {
    merkle_root: String,
    proofs: Vec<ProofOutput>,
}

fn main() {
    let whitelist_json =
        fs::read_to_string("whitelist.json").expect("Failed to parse whitelist.json");
    let whitelist: Whitelist =
        serde_json::from_str(&whitelist_json).expect("Failed to parse whitelist.json");
    println!("Loaded {} addresses ", whitelist.addresses.len());

    let leaves: Vec<[u8; 32]> = whitelist
        .addresses
        .iter()
        .map(|addr| {
            let addr_bytes = hex::decode(addr.trim_start_matches("0x")).expect("Invalid address");
            Keccak256::hash(&addr_bytes)
        })
        .collect();
    println!("Created {} leaves", leaves.len());

    let tree = MerkleTree::<Keccak256>::from_leaves(&leaves);
    let root = tree.root().expect("Failed to get the root");
    let mut proofs = Vec::new();
    for (i, addr) in whitelist.addresses.iter().enumerate() {
        let proof = tree.proof(&[i]);
        let proof_hashes: Vec<String> = proof
            .proof_hashes()
            .iter()
            .map(|h| format!("0x{}", hex::encode(h)))
            .collect();
        proofs.push(ProofOutput {
            address: addr.clone(),
            proof: proof_hashes,
        });
    }
    println!("Merkle Root: 0x{}", hex::encode(root));

    let output = Output {
        merkle_root: format!("0x{}", hex::encode(root)),
        proofs,
    };

    let output_json = serde_json::to_string_pretty(&output).expect("Failed to serialize output");

    fs::write("proofs.json", &output_json).expect("Failed to write proofs.json");

    println!("Proofs saved to proofs.json");
}
