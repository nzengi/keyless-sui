module keyless::registry {
    use std::vector;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::event;
    use sui::clock::Clock;
    
    /// Error codes
    const E_UNAUTHORIZED: u64 = 1;
    const E_INVALID_DOMAIN: u64 = 2;
    const E_ALREADY_REGISTERED: u64 = 3;

    /// Registered dApp information
    struct DApp has key {
        id: UID,
        /// Owner address
        owner: address,
        /// Domain name
        domain: vector<u8>,
        /// Public key
        pubkey: vector<u8>,
        /// Registration timestamp
        registered_at: u64,
        /// Whether domain is verified
        is_verified: bool
    }

    /// Events
    struct DAppRegistered has copy, drop {
        dapp_id: ID,
        owner: address,
        domain: vector<u8>,
        timestamp: u64
    }

    struct DAppVerified has copy, drop {
        dapp_id: ID,
        domain: vector<u8>,
        timestamp: u64
    }

    /// Register a new dApp
    public entry fun register_dapp(
        domain: vector<u8>,
        pubkey: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let owner = tx_context::sender(ctx);
        
        let dapp = DApp {
            id: object::new(ctx),
            owner,
            domain,
            pubkey,
            registered_at: clock::timestamp_ms(clock),
            is_verified: false
        };

        event::emit(DAppRegistered {
            dapp_id: object::uid_to_inner(&dapp.id),
            owner,
            domain: domain,
            timestamp: clock::timestamp_ms(clock)
        });

        transfer::transfer(dapp, owner);
    }

    /// Verify dApp domain ownership
    public entry fun verify_dapp(
        dapp: &mut DApp,
        clock: &Clock,
        ctx: &TxContext
    ) {
        assert!(tx_context::sender(ctx) == dapp.owner, E_UNAUTHORIZED);
        
        dapp.is_verified = true;

        event::emit(DAppVerified {
            dapp_id: object::uid_to_inner(&dapp.id),
            domain: dapp.domain,
            timestamp: clock::timestamp_ms(clock)
        });
    }

    /// Get dApp info
    public fun get_dapp_info(dapp: &DApp): (address, vector<u8>, vector<u8>, bool) {
        (
            dapp.owner,
            dapp.domain,
            dapp.pubkey,
            dapp.is_verified
        )
    }

    /// Check if dApp is verified
    public fun is_verified(dapp: &DApp): bool {
        dapp.is_verified
    }
} 