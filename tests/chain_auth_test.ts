import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test identity registration",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('chain-auth', 'register-identity', [
        types.ascii("Test User 1 Metadata")
      ], user1.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Verify registration
    let checkBlock = chain.mineBlock([
      Tx.contractCall('chain-auth', 'is-registered', [
        types.principal(user1.address)
      ], deployer.address)
    ]);
    
    assertEquals(checkBlock.receipts[0].result.expectOk(), true);
  },
});

Clarinet.test({
  name: "Test tiered verifier management and identity verification",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const verifier = accounts.get('wallet_1')!;
    const user = accounts.get('wallet_2')!;
    
    let block = chain.mineBlock([
      // Add tier 2 verifier
      Tx.contractCall('chain-auth', 'add-verifier', [
        types.principal(verifier.address),
        types.uint(2)
      ], deployer.address),
      
      // Register identity
      Tx.contractCall('chain-auth', 'register-identity', [
        types.ascii("Test User Metadata")
      ], user.address),
      
      // Verify identity with tier 2
      Tx.contractCall('chain-auth', 'verify-identity', [
        types.principal(user.address),
        types.uint(2)
      ], verifier.address)
    ]);
    
    block.receipts[0].result.expectOk();
    block.receipts[1].result.expectOk();
    block.receipts[2].result.expectOk();
    
    // Check verification and tier
    let tierBlock = chain.mineBlock([
      Tx.contractCall('chain-auth', 'get-identity-tier', [
        types.principal(user.address)
      ], deployer.address)
    ]);
    
    assertEquals(tierBlock.receipts[0].result.expectOk(), types.uint(2));
  },
});

Clarinet.test({
  name: "Test tier restrictions",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const verifier = accounts.get('wallet_1')!;
    const user = accounts.get('wallet_2')!;
    
    let block = chain.mineBlock([
      // Add tier 1 verifier
      Tx.contractCall('chain-auth', 'add-verifier', [
        types.principal(verifier.address),
        types.uint(1)
      ], deployer.address),
      
      // Register identity
      Tx.contractCall('chain-auth', 'register-identity', [
        types.ascii("Test User Metadata")
      ], user.address),
      
      // Try to verify with tier 2 (should fail)
      Tx.contractCall('chain-auth', 'verify-identity', [
        types.principal(user.address),
        types.uint(2)
      ], verifier.address)
    ]);
    
    block.receipts[0].result.expectOk();
    block.receipts[1].result.expectOk();
    block.receipts[2].result.expectErr(types.uint(106)); // err-insufficient-tier
  },
});
