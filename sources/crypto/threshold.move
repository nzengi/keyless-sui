module keyless::threshold {
    use std::vector;
    use sui::clock::{Self, Clock};
    use keyless::bls::{Self, G2Point};

    /// Error codes
    const E_INVALID_THRESHOLD: u64 = 1;
    const E_INVALID_VALIDATOR_COUNT: u64 = 2;
    const E_INVALID_PUBLIC_KEYS: u64 = 3;

    /// Default timeout in milliseconds (5 minutes)
    const DEFAULT_TIMEOUT_MS: u64 = 300000;

    /// Threshold signature scheme configuration
    struct ThresholdScheme has store {
        /// Number of signatures required
        threshold: u64,
        /// Total number of validators
        validator_count: u64,
        /// Combined public key for verification
        verification_key: G2Point,
        /// Timestamp when the scheme was created
        created_at: u64,
        /// Timeout in milliseconds
        timeout_ms: u64
    }

    /// Create a new threshold scheme
    public fun new_scheme(
        threshold: u64,
        validator_count: u64,
        public_keys: vector<G2Point>,
        clock: &Clock
    ): ThresholdScheme {
        // Validate parameters
        assert!(threshold > 0 && threshold <= validator_count, E_INVALID_THRESHOLD);
        assert!(validator_count > 0, E_INVALID_VALIDATOR_COUNT);
        assert!(vector::length(&public_keys) == validator_count, E_INVALID_PUBLIC_KEYS);

        // Combine public keys for verification
        let verification_key = bls::combine_public_keys(&public_keys);
        
        ThresholdScheme {
            threshold,
            validator_count,
            verification_key,
            created_at: clock::timestamp_ms(clock),
            timeout_ms: DEFAULT_TIMEOUT_MS
        }
    }

    /// Create a new threshold scheme with custom timeout
    public fun new_scheme_with_timeout(
        threshold: u64,
        validator_count: u64,
        public_keys: vector<G2Point>,
        timeout_ms: u64,
        clock: &Clock
    ): ThresholdScheme {
        let scheme = new_scheme(threshold, validator_count, public_keys, clock);
        scheme.timeout_ms = timeout_ms;
        scheme
    }

    /// Check if the scheme has expired
    public fun is_expired(scheme: &ThresholdScheme, clock: &Clock): bool {
        let current_time = clock::timestamp_ms(clock);
        let expiry_time = scheme.created_at + scheme.timeout_ms;
        current_time > expiry_time
    }

    /// Get the threshold value
    public fun get_threshold(scheme: &ThresholdScheme): u64 {
        scheme.threshold
    }

    /// Get the validator count
    public fun get_validator_count(scheme: &ThresholdScheme): u64 {
        scheme.validator_count
    }

    /// Get the verification key
    public fun get_verification_key(scheme: &ThresholdScheme): &G2Point {
        &scheme.verification_key
    }

    /// Get the creation timestamp
    public fun get_created_at(scheme: &ThresholdScheme): u64 {
        scheme.created_at
    }

    /// Get the timeout duration
    public fun get_timeout_ms(scheme: &ThresholdScheme): u64 {
        scheme.timeout_ms
    }
} 