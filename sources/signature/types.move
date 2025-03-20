module keyless::types {
    use std::vector;
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::event;
    use keyless::bls::{G1Point, G2Point};
    
    /// Signature share from a validator
    struct SignatureShare has store {
        /// Index of the validator
        index: u64,
        /// BLS signature share
        value: G1Point
    }

    /// Validator set configuration
    struct ValidatorSet has key {
        /// Unique identifier
        id: UID,
        /// List of validator addresses
        validators: vector<address>,
        /// Minimum signatures required
        threshold: u64,
        /// BLS public keys of validators
        public_keys: vector<G2Point>
    }

    /// Events
    struct ValidatorSetCreated has copy, drop {
        /// Number of validators in the set
        validator_count: u64,
        /// Required threshold
        threshold: u64,
        /// Whether the set is properly configured
        is_valid: bool
    }

    /// Create a new validator set
    public fun new_validator_set(
        validators: vector<address>,
        threshold: u64,
        public_keys: vector<G2Point>,
        ctx: &mut TxContext
    ): ValidatorSet {
        let validator_count = vector::length(&validators);
        let is_valid = threshold > 0 && 
                      threshold <= validator_count &&
                      validator_count == vector::length(&public_keys);
        
        event::emit(ValidatorSetCreated {
            validator_count,
            threshold,
            is_valid
        });

        ValidatorSet {
            id: object::new(ctx),
            validators,
            threshold,
            public_keys
        }
    }

    /// Create a new signature share
    public fun create_share(index: u64, value: G1Point): SignatureShare {
        SignatureShare {
            index,
            value
        }
    }

    // Getter functions
    public fun get_threshold(set: &ValidatorSet): u64 { 
        set.threshold 
    }

    public fun get_validators(set: &ValidatorSet): &vector<address> { 
        &set.validators 
    }

    public fun get_public_keys(set: &ValidatorSet): &vector<G2Point> { 
        &set.public_keys 
    }

    public fun get_share_index(share: &SignatureShare): u64 { 
        share.index 
    }

    public fun get_share_value(share: &SignatureShare): &G1Point { 
        &share.value 
    }

    /// Validate validator set configuration
    public fun is_valid_config(
        validators: &vector<address>,
        threshold: u64,
        public_keys: &vector<G2Point>
    ): bool {
        let validator_count = vector::length(validators);
        threshold > 0 && 
        threshold <= validator_count &&
        validator_count == vector::length(public_keys)
    }
} 