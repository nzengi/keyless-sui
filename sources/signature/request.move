module keyless::request {
    use std::vector;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::event;
    use sui::clock::Clock;
    
    use keyless::types::{Self, SecuredEnvelope};
    use keyless::manager::{Self, Wallet};
    use keyless::registry::{Self, DApp};

    /// Error codes
    const E_UNAUTHORIZED: u64 = 1;
    const E_INVALID_REQUEST: u64 = 2;
    const E_ALREADY_PROCESSED: u64 = 3;
    const E_EXPIRED: u64 = 4;

    /// Request types
    const SIGN_MESSAGE: u8 = 0;
    const SIGN_TRANSACTION: u8 = 1;
    const SIGN_AND_SUBMIT: u8 = 2;

    /// Request status
    const STATUS_PENDING: u8 = 0;
    const STATUS_APPROVED: u8 = 1;
    const STATUS_REJECTED: u8 = 2;
    const STATUS_INVALID: u8 = 3;

    /// Signing request object
    struct SigningRequest has key {
        id: UID,
        /// Request type
        request_type: u8,
        /// Message/transaction to sign
        payload: vector<u8>,
        /// Requesting dApp
        dapp: address,
        /// Target account
        account: address,
        /// Request status
        status: u8,
        /// Creation timestamp
        created_at: u64,
        /// Response timestamp
        responded_at: u64
    }

    /// Events
    struct RequestCreated has copy, drop {
        request_id: ID,
        request_type: u8,
        dapp: address,
        account: address,
        timestamp: u64
    }

    struct RequestResponded has copy, drop {
        request_id: ID,
        status: u8,
        timestamp: u64
    }

    /// Create a new signing request
    public entry fun create_request(
        dapp: &DApp,
        request_type: u8,
        payload: vector<u8>,
        account: address,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(registry::is_verified(dapp), E_UNAUTHORIZED);
        assert!(request_type <= SIGN_AND_SUBMIT, E_INVALID_REQUEST);

        let request = SigningRequest {
            id: object::new(ctx),
            request_type,
            payload,
            dapp: tx_context::sender(ctx),
            account,
            status: STATUS_PENDING,
            created_at: clock::timestamp_ms(clock),
            responded_at: 0
        };

        event::emit(RequestCreated {
            request_id: object::uid_to_inner(&request.id),
            request_type,
            dapp: tx_context::sender(ctx),
            account,
            timestamp: clock::timestamp_ms(clock)
        });

        transfer::share_object(request);
    }

    /// Respond to a signing request
    public entry fun respond_to_request(
        request: &mut SigningRequest,
        wallet: &Wallet,
        status: u8,
        clock: &Clock,
        ctx: &TxContext
    ) {
        // Verify wallet owns the account
        assert!(vector::contains(manager::get_accounts(wallet), &request.account), E_UNAUTHORIZED);
        assert!(request.status == STATUS_PENDING, E_ALREADY_PROCESSED);
        assert!(status <= STATUS_INVALID, E_INVALID_REQUEST);
        
        // Check request hasn't expired (5 minutes)
        let current_time = clock::timestamp_ms(clock);
        assert!(current_time - request.created_at <= 300000, E_EXPIRED);

        request.status = status;
        request.responded_at = current_time;

        event::emit(RequestResponded {
            request_id: object::uid_to_inner(&request.id),
            status,
            timestamp: current_time
        });
    }

    /// Get request info
    public fun get_request_info(request: &SigningRequest): (u8, address, address, u8) {
        (
            request.request_type,
            request.dapp,
            request.account,
            request.status
        )
    }

    /// Get request payload
    public fun get_payload(request: &SigningRequest): &vector<u8> {
        &request.payload
    }
} 