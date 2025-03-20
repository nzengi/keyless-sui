module keyless::bls {
    use std::vector;
    use sui::hash;
    use sui::bls12381::{
        bls12381_min_sig_verify,
        bls12381_min_pk_verify
    };

    /// Error codes
    const E_INVALID_PUBLIC_KEY: u64 = 1;
    const E_INVALID_SIGNATURE: u64 = 2;
    const E_EMPTY_VECTOR: u64 = 3;

    /// BLS G1 point representing a signature
    struct G1Point has copy, drop, store {
        data: vector<u8>
    }

    /// BLS G2 point representing a public key
    struct G2Point has copy, drop, store {
        data: vector<u8>
    }

    /// Create a new G1 point from bytes
    public fun new_g1_point(data: vector<u8>): G1Point {
        // Verify signature format
        let bytes = &data;
        let len = vector::length(bytes);
        assert!(len == 48, E_INVALID_SIGNATURE);
        G1Point { data }
    }

    /// Create a new G2 point from bytes
    public fun new_g2_point(data: vector<u8>): G2Point {
        // Verify public key format
        let bytes = &data;
        let len = vector::length(bytes);
        assert!(len == 96, E_INVALID_PUBLIC_KEY);
        
        // Verify public key with empty message and signature
        let empty_msg = vector::empty<u8>();
        let empty_sig = vector::empty<u8>();
        assert!(bls12381_min_pk_verify(bytes, &empty_msg, &empty_sig), E_INVALID_PUBLIC_KEY);
        
        G2Point { data }
    }

    /// Verify a BLS signature
    public fun verify_signature(
        pubkey: &G2Point,
        message: &vector<u8>,
        signature: &G1Point
    ): bool {
        let msg_hash = hash::blake2b256(message);
        bls12381_min_sig_verify(&signature.data, &pubkey.data, &msg_hash)
    }

    /// Get the bytes of a G1 point
    public fun g1_to_bytes(point: &G1Point): vector<u8> {
        point.data
    }

    /// Get the bytes of a G2 point
    public fun g2_to_bytes(point: &G2Point): vector<u8> {
        point.data
    }

    /// Create a new G1 point from bytes
    public fun create_g1_point(data: vector<u8>): G1Point {
        new_g1_point(data)
    }

    /// Aggregate multiple signatures into one
    public fun aggregate_signatures(signatures: &vector<G1Point>): G1Point {
        let len = vector::length(signatures);
        assert!(len > 0, E_EMPTY_VECTOR);
        
        if (len == 1) {
            return *vector::borrow(signatures, 0)
        };

        // For now, just return the first signature
        // TODO: Implement proper BLS signature aggregation when API is available
        let first_sig = vector::borrow(signatures, 0);
        G1Point { data: first_sig.data }
    }

    /// Combine multiple public keys into one
    public fun combine_public_keys(keys: &vector<G2Point>): G2Point {
        let len = vector::length(keys);
        assert!(len > 0, E_EMPTY_VECTOR);
        
        if (len == 1) {
            return *vector::borrow(keys, 0)
        };

        // For now, just return the first public key
        // TODO: Implement proper BLS public key aggregation when API is available
        let first_key = vector::borrow(keys, 0);
        G2Point { data: first_key.data }
    }
} 