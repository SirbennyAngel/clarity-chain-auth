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
  name: "Test verifier management and identity verification",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const verifier = accounts.get('wallet_1')!;
    const user = accounts.get('wallet_2')!;
    
    let block = chain.mineBlock([
      // Add verifier
      Tx.contractCall('chain-auth', 'add-verifier', [
        types.principal(verifier.address)
      ], deployer.address),
      
      // Register identity
      Tx.contractCall('chain-auth', 'register-identity', [
        types.ascii("Test User Metadata")
      ], user.address),
      
      // Verify identity
      Tx.contractCall('chain-auth', 'verify-identity', [
        types.principal(user.address)
      ], verifier.address)
    ]);
    
    block.receipts[0].result.expectOk();
    block.receipts[1].result.expectOk();
    block.receipts[2].result.expectOk();
    
    // Check verification status
    let verifyBlock = chain.mineBlock([
      Tx.contractCall('chain-auth', 'is-verified', [
        types.principal(user.address)
      ], deployer.address)
    ]);
    
    assertEquals(verifyBlock.receipts[0].result.expectOk(), true);
  },
});

Clarinet.test({
  name: "Test error cases",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      // Try to verify without being a verifier
      Tx.contractCall('chain-auth', 'verify-identity', [
        types.principal(user1.address)
      ], user1.address),
      
      // Try to add verifier without being owner
      Tx.contractCall('chain-auth', 'add-verifier', [
        types.principal(user1.address)
      ], user1.address)
    ]);
    
    block.receipts[0].result.expectErr(types.uint(103)); // err-not-verifier
    block.receipts[1].result.expectErr(types.uint(100)); // err-owner-only
  },
});