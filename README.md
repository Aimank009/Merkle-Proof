# NFT Merkle Pool - Whitelist Minting System

A gas-efficient whitelist minting system using Merkle trees. Only whitelisted addresses can mint NFTs during the whitelist phase.

## How It Works

1. Admin creates a whitelist of addresses
2. Rust tool generates Merkle tree and proofs
3. Merkle root is stored on-chain (32 bytes only)
4. Users provide their proof when minting
5. Contract verifies proof against root

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Rust Generator │────▶│  Merkle Root     │────▶│  NFT Merkle     │
│  (Off-chain)    │     │  + Proofs JSON   │     │  Pool Contract  │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                                                          │
                                                          ▼
                                                 ┌─────────────────┐
                                                 │  NFT Collection │
                                                 │  Contract       │
                                                 └─────────────────┘
```

## Project Structure

```
NFTMerklePool/
├── src/
│   ├── NFTMerkelPool.sol       # Main whitelist minting contract
│   ├── interfaces/
│   │   ├── IMerklePool.sol     # Interface for Merkle Pool
│   │   └── INFTCollection.sol  # Interface for NFT minting
│   └── events/
│       └── MerklePoolEvents.sol
├── merkle-generator/           # Rust CLI tool
│   ├── Cargo.toml
│   ├── src/main.rs
│   ├── whitelist.json          # Input: addresses to whitelist
│   └── proofs.json             # Output: root + proofs
└── test/
    └── NFTMerklePool.t.sol
```

## Smart Contract Functions

### User Functions

| Function | Description |
|----------|-------------|
| `whitelistMint(proof)` | Mint NFT with Merkle proof (requires payment) |
| `isWhitelisted(user, proof)` | Check if user is on whitelist |

### Admin Functions

| Function | Description |
|----------|-------------|
| `setMerkleRoot(root)` | Update the whitelist |
| `setWhiteListEnabled(bool)` | Enable/disable whitelist minting |
| `withdraw()` | Withdraw collected ETH |

### View Functions

| Function | Description |
|----------|-------------|
| `merkleRoot()` | Current Merkle root |
| `mintPrice()` | Price per mint |
| `hasMinted(user)` | Check if user already minted |
| `whitelistMintEnabled()` | Check if whitelist is active |

## Rust Merkle Generator

### Usage

```bash
cd merkle-generator

# Edit whitelist.json with your addresses
# Run generator
cargo run

# Output:
# - Merkle Root (use in contract deployment)
# - proofs.json (distribute to whitelisted users)
```

### Input Format (whitelist.json)

```json
{
    "addresses": [
        "0x1111111111111111111111111111111111111111",
        "0x2222222222222222222222222222222222222222"
    ]
}
```

### Output Format (proofs.json)

```json
{
    "merkle_root": "0xabc123...",
    "proofs": [
        {
            "address": "0x1111...",
            "proof": ["0xdef...", "0x456..."]
        }
    ]
}
```

## Deployment Steps

1. Deploy NFT Collection contract
2. Run Rust generator to get Merkle root
3. Deploy NFT Merkle Pool with:
   - NFT Collection address
   - Merkle root from Rust tool
   - Mint price in wei
4. Set Merkle Pool as minter on NFT Collection
5. Enable whitelist minting

## Gas Efficiency

| Approach | Gas Cost (1000 addresses) |
|----------|--------------------------|
| Store all addresses on-chain | ~20,000,000 gas |
| Store Merkle root only | ~20,000 gas |

Merkle trees are **1000x more gas efficient** for whitelists.

## How Merkle Verification Works

```
User provides: address + proof[]
Contract computes: leaf = keccak256(address)
Contract verifies: proof + leaf = stored root
```

Each proof is O(log n) hashes, where n = number of whitelisted addresses.

## Build & Test

```bash
# Build
forge build

# Test
forge test

# Test with verbosity
forge test -vvv
```

## Dependencies

- Solidity: OpenZeppelin Contracts v5.0
- Rust: rs_merkle, tiny-keccak, serde_json

## License

MIT
