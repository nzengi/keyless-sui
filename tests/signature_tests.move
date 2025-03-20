#[test_only]
module keyless::signature_tests {
    use sui::test_scenario::{Self as ts};
    use sui::test_utils;
    use keyless::bls;

    const TEST_ADDR: address = @0x1;

    #[test]
    fun test_basic_signature() {
        let scenario = ts::begin(TEST_ADDR);
        let ctx = ts::ctx(&mut scenario);
        
        // Test setup
        let message = b"test message";
        let (pubkey_bytes, sig_bytes) = test_utils::generate_bls_keypair_and_sign(&message);
        
        // Test logic
        let pubkey = bls::new_g2_point(pubkey_bytes);
        let sig = bls::new_g1_point(sig_bytes);
        
        assert!(bls::verify_signature(&pubkey, &message, &sig), 0);
        
        ts::end(scenario);
    }
} 