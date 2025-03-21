module keyless::types {
    friend keyless::validator;
    
    use std::vector;
    use sui::object::{Self, ID, UID};
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::event;
    use sui::clock::{Self, Clock};
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

    /// Pairing between dApp and wallet
    struct Pairing has key {
        id: UID,
        dapp_pubkey: vector<u8>,
        wallet_pubkey: vector<u8>,
        accounts: vector<address>,
        created_at: u64,
        is_anonymous: bool
    }

    /// Events for pairing
    #[allow(unused_field)]
    struct PairingCreated has copy, drop {
        dapp_id: ID,
        is_anonymous: bool,
        account_count: u64,
        timestamp: u64
    }

    #[allow(unused_field)]
    struct PairingFinalized has copy, drop {
        pairing_id: ID,
        wallet_name: vector<u8>,
        platform: vector<u8>,
        device_id: vector<u8>
    }

    /// Secured envelope for message passing
    struct SecuredEnvelope has store {
        encrypted_msg: vector<u8>,
        public_msg: vector<u8>,
        signature: vector<u8>,
        sender_pubkey: vector<u8>,
        receiver_pubkey: vector<u8>,
        sequence: u64,
        timestamp: u64
    }

    /// Message types for secured envelopes
    #[allow(unused_field)]
    struct MessageMetadata has store {
        sequence: u64,
        timestamp: u64,
        sender_pubkey: vector<u8>,
        receiver_pubkey: vector<u8>
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

    /// Create a new pairing
    public fun new_pairing(
        dapp_pubkey: vector<u8>,
        wallet_pubkey: vector<u8>,
        accounts: vector<address>,
        is_anonymous: bool,
        clock: &Clock,
        ctx: &mut TxContext
    ): Pairing {
        Pairing {
            id: object::new(ctx),
            dapp_pubkey,
            wallet_pubkey,
            accounts,
            created_at: clock::timestamp_ms(clock),
            is_anonymous
        }
    }

    /// Create a new secured envelope
    public fun new_secured_envelope(
        encrypted_msg: vector<u8>,
        public_msg: vector<u8>,
        signature: vector<u8>,
        sender_pubkey: vector<u8>,
        receiver_pubkey: vector<u8>,
        sequence: u64,
        timestamp: u64
    ): SecuredEnvelope {
        SecuredEnvelope {
            encrypted_msg,
            public_msg,
            signature,
            sender_pubkey,
            receiver_pubkey,
            sequence,
            timestamp
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

    /// Get pairing info
    public fun get_pairing_info(pairing: &Pairing): (vector<u8>, vector<u8>, vector<address>, bool) {
        (
            pairing.dapp_pubkey,
            pairing.wallet_pubkey,
            pairing.accounts,
            pairing.is_anonymous
        )
    }

    /// Get envelope info
    public fun get_envelope_info(envelope: &SecuredEnvelope): (vector<u8>, vector<u8>, u64) {
        (
            envelope.sender_pubkey,
            envelope.receiver_pubkey,
            envelope.sequence
        )
    }

    // SecuredEnvelope için getter'lar
    public fun get_envelope_timestamp(envelope: &SecuredEnvelope): u64 {
        envelope.timestamp
    }

    public fun get_envelope_public_msg(envelope: &SecuredEnvelope): &vector<u8> {
        &envelope.public_msg
    }

    public fun get_envelope_encrypted_msg(envelope: &SecuredEnvelope): &vector<u8> {
        &envelope.encrypted_msg
    }

    public fun get_envelope_sender_pubkey(envelope: &SecuredEnvelope): &vector<u8> {
        &envelope.sender_pubkey
    }

    public fun get_envelope_signature(envelope: &SecuredEnvelope): &vector<u8> {
        &envelope.signature
    }

    // Pairing için getter'lar
    public fun get_pairing_is_anonymous(pairing: &Pairing): bool {
        pairing.is_anonymous
    }

    public fun get_pairing_id(pairing: &Pairing): &UID {
        &pairing.id
    }

    /// Transfer a pairing to the sender
    public(friend) fun transfer_pairing(pairing: Pairing, recipient: address) {
        transfer::transfer(pairing, recipient);
    }
} 