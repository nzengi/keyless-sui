module keyless::validator {
    use std::vector;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use sui::clock::Clock;
    use sui::event;
    
    use keyless::types::{Self, ValidatorSet, SignatureShare};
    use keyless::threshold::{Self, ThresholdScheme};
    use keyless::bls::{Self, G1Point};
    
    /// Error codes
    const E_INVALID_SHARE: u64 = 1;
    const E_DUPLICATE_SHARE: u64 = 2;
    const E_TIMEOUT: u64 = 3;
    const E_INSUFFICIENT_SHARES: u64 = 4;
    const E_ALREADY_COMPLETED: u64 = 5;
    
    /// Signature aggregator object
    struct SignatureAggregator has key {
        id: UID,
        /// Message to be signed
        message: vector<u8>,
        /// Collected signature shares
        shares: vector<SignatureShare>,
        /// Threshold scheme configuration
        scheme: ThresholdScheme,
        /// Used share indices to prevent duplicates
        used_indices: vector<u64>,
        /// Whether signature aggregation is completed
        completed: bool
    }

    /// Events
    struct AggregatorCreated has copy, drop {
        threshold: u64,
        message_length: u64
    }

    struct ShareAdded has copy, drop {
        validator: address,
        index: u64,
        total_shares: u64
    }

    struct SignatureCompleted has copy, drop {
        total_shares: u64,
        verification_result: bool
    }

    /// Create a new signature aggregator
    public entry fun create_aggregator(
        validator_set: &ValidatorSet,
        message: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let scheme = threshold::new_scheme(
            types::get_threshold(validator_set),
            vector::length(types::get_validators(validator_set)),
            *types::get_public_keys(validator_set),
            clock
        );

        event::emit(AggregatorCreated {
            threshold: threshold::get_threshold(&scheme),
            message_length: vector::length(&message)
        });

        let aggregator = SignatureAggregator {
            id: object::new(ctx),
            message,
            shares: vector::empty(),
            scheme,
            used_indices: vector::empty(),
            completed: false
        };

        transfer::share_object(aggregator);
    }

    /// Add a signature share to the aggregator
    public entry fun add_signature_share(
        aggregator: &mut SignatureAggregator,
        index: u64,
        value: vector<u8>,
        validator: address,
        clock: &Clock,
        _ctx: &TxContext
    ) {
        // Validate state
        assert!(!aggregator.completed, E_ALREADY_COMPLETED);
        assert!(!threshold::is_expired(&aggregator.scheme, clock), E_TIMEOUT);
        assert!(!vector::contains(&aggregator.used_indices, &index), E_DUPLICATE_SHARE);
        assert!(index < threshold::get_validator_count(&aggregator.scheme), E_INVALID_SHARE);

        // Create and add signature share
        let share = create_signature_share(index, value);
        vector::push_back(&mut aggregator.shares, share);
        vector::push_back(&mut aggregator.used_indices, index);

        let total_shares = vector::length(&aggregator.shares);
        event::emit(ShareAdded {
            validator,
            index,
            total_shares
        });

        // Check if we have enough shares
        if (total_shares >= threshold::get_threshold(&aggregator.scheme)) {
            aggregator.completed = true;
            
            let verification_result = verify_aggregate(aggregator);
            event::emit(SignatureCompleted {
                total_shares,
                verification_result
            });
        };
    }

    /// Verify the aggregated signature
    public fun verify_aggregate(
        aggregator: &SignatureAggregator
    ): bool {
        assert!(aggregator.completed, E_INSUFFICIENT_SHARES);
        
        let signatures = vector::empty<G1Point>();
        let i = 0;
        let len = vector::length(&aggregator.shares);
        
        while (i < len) {
            let share = vector::borrow(&aggregator.shares, i);
            vector::push_back(&mut signatures, *types::get_share_value(share));
            i = i + 1;
        };

        let combined_sig = bls::aggregate_signatures(&signatures);
        bls::verify_signature(
            threshold::get_verification_key(&aggregator.scheme),
            &aggregator.message,
            &combined_sig
        )
    }

    /// Create a signature share from raw bytes
    fun create_signature_share(index: u64, value: vector<u8>): SignatureShare {
        types::create_share(
            index,
            bls::create_g1_point(value)
        )
    }
} 