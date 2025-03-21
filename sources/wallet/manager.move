module keyless::manager {
    use std::vector;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::event;
    use sui::clock::Clock;
    
    use keyless::types::{Self, SecuredEnvelope};

    /// Error codes
    const E_UNAUTHORIZED: u64 = 1;
    const E_INVALID_DEVICE: u64 = 2;
    const E_ALREADY_CONNECTED: u64 = 3;

    /// Connected wallet information
    struct Wallet has key {
        id: UID,
        /// Owner address
        owner: address,
        /// Wallet name (e.g. "Petra", "Sui Wallet")
        name: vector<u8>,
        /// Device identifier
        device_id: vector<u8>,
        /// Platform info
        platform: vector<u8>,
        /// Public key
        pubkey: vector<u8>,
        /// Connected accounts
        accounts: vector<address>,
        /// Connection timestamp
        connected_at: u64
    }

    /// Events
    struct WalletConnected has copy, drop {
        wallet_id: ID,
        owner: address,
        name: vector<u8>,
        account_count: u64,
        timestamp: u64
    }

    struct AccountAdded has copy, drop {
        wallet_id: ID,
        account: address,
        timestamp: u64
    }

    struct AccountRemoved has copy, drop {
        wallet_id: ID,
        account: address,
        timestamp: u64
    }

    /// Connect a new wallet
    public entry fun connect_wallet(
        name: vector<u8>,
        device_id: vector<u8>,
        platform: vector<u8>,
        pubkey: vector<u8>,
        accounts: vector<address>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let owner = tx_context::sender(ctx);
        
        let wallet = Wallet {
            id: object::new(ctx),
            owner,
            name,
            device_id,
            platform,
            pubkey,
            accounts,
            connected_at: clock::timestamp_ms(clock)
        };

        event::emit(WalletConnected {
            wallet_id: object::uid_to_inner(&wallet.id),
            owner,
            name,
            account_count: vector::length(&accounts),
            timestamp: clock::timestamp_ms(clock)
        });

        transfer::transfer(wallet, owner);
    }

    /// Add account to wallet
    public entry fun add_account(
        wallet: &mut Wallet,
        account: address,
        clock: &Clock,
        ctx: &TxContext
    ) {
        assert!(tx_context::sender(ctx) == wallet.owner, E_UNAUTHORIZED);
        assert!(!vector::contains(&wallet.accounts, &account), E_ALREADY_CONNECTED);

        vector::push_back(&mut wallet.accounts, account);

        event::emit(AccountAdded {
            wallet_id: object::uid_to_inner(&wallet.id),
            account,
            timestamp: clock::timestamp_ms(clock)
        });
    }

    /// Remove account from wallet
    public entry fun remove_account(
        wallet: &mut Wallet,
        account: address,
        clock: &Clock,
        ctx: &TxContext
    ) {
        assert!(tx_context::sender(ctx) == wallet.owner, E_UNAUTHORIZED);
        
        let (exists, index) = vector::index_of(&wallet.accounts, &account);
        assert!(exists, E_INVALID_DEVICE);

        vector::remove(&mut wallet.accounts, index);

        event::emit(AccountRemoved {
            wallet_id: object::uid_to_inner(&wallet.id),
            account,
            timestamp: clock::timestamp_ms(clock)
        });
    }

    /// Get wallet info
    public fun get_wallet_info(wallet: &Wallet): (address, vector<u8>, vector<u8>, vector<address>) {
        (
            wallet.owner,
            wallet.name,
            wallet.pubkey,
            wallet.accounts
        )
    }

    /// Get connected accounts
    public fun get_accounts(wallet: &Wallet): &vector<address> {
        &wallet.accounts
    }
} 