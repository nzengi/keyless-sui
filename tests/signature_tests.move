#[test_only]
module keyless::signature_tests {
    use std::vector;
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::test_utils;
    use sui::clock;
    
    use keyless::bls::{Self, G1Point, G2Point};
    use keyless::types::{Self, ValidatorSet};
    use keyless::validator;
    use keyless::registry::{Self, DApp};
    use keyless::manager::{Self, Wallet};
    use keyless::request::{Self, SigningRequest};

    const TEST_ADDR1: address = @0x1;
    const TEST_ADDR2: address = @0x2;
    const TEST_ADDR3: address = @0x3;

    #[test]
    fun test_full_flow() {
        let scenario = ts::begin(TEST_ADDR1);
        
        // Setup test data
        let (pubkey_bytes, sig_bytes) = test_utils::generate_bls_keypair_and_sign(b"test");
        let test_clock = clock::create_for_testing(ts::ctx(&mut scenario));

        // 1. Register dApp
        register_test_dapp(&mut scenario, &test_clock);
        
        // 2. Connect wallet
        connect_test_wallet(&mut scenario, &test_clock);
        
        // 3. Create signing request
        create_test_request(&mut scenario, &test_clock);
        
        // 4. Respond to request
        respond_to_test_request(&mut scenario, &test_clock);

        clock::destroy_for_testing(test_clock);
        ts::end(scenario);
    }

    fun register_test_dapp(scenario: &mut Scenario, clock: &clock::Clock) {
        ts::next_tx(scenario, TEST_ADDR1);
        {
            registry::register_dapp(
                b"test.domain",
                b"test_pubkey",
                clock,
                ts::ctx(scenario)
            );
        };

        ts::next_tx(scenario, TEST_ADDR1);
        {
            let dapp = ts::take_from_sender<DApp>(scenario);
            registry::verify_dapp(&mut dapp, clock, ts::ctx(scenario));
            ts::return_to_sender(scenario, dapp);
        };
    }

    fun connect_test_wallet(scenario: &mut Scenario, clock: &clock::Clock) {
        ts::next_tx(scenario, TEST_ADDR2);
        {
            let accounts = vector::empty();
            vector::push_back(&mut accounts, TEST_ADDR2);
            
            manager::connect_wallet(
                b"Test Wallet",
                b"device_id",
                b"platform",
                b"wallet_pubkey",
                accounts,
                clock,
                ts::ctx(scenario)
            );
        };
    }

    fun create_test_request(scenario: &mut Scenario, clock: &clock::Clock) {
        ts::next_tx(scenario, TEST_ADDR1);
        {
            let dapp = ts::take_from_sender<DApp>(scenario);
            
            request::create_request(
                &dapp,
                0, // SIGN_MESSAGE
                b"test message",
                TEST_ADDR2,
                clock,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, dapp);
        };
    }

    fun respond_to_test_request(scenario: &mut Scenario, clock: &clock::Clock) {
        ts::next_tx(scenario, TEST_ADDR2);
        {
            let wallet = ts::take_from_sender<Wallet>(scenario);
            let request = ts::take_shared<SigningRequest>(scenario);
            
            request::respond_to_request(
                &mut request,
                &wallet,
                1, // STATUS_APPROVED
                clock,
                ts::ctx(scenario)
            );

            ts::return_to_sender(scenario, wallet);
            ts::return_shared(request);
        };
    }
} 