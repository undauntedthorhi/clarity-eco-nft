import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure cannot mint with zero values",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('eco_nft', 'mint', [
        types.uint(0),
        types.uint(500)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectErr(108); // Zero value error
  }
});

Clarinet.test({
  name: "Ensure cannot mint beyond max supply",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    for (let i = 0; i <= 10000; i++) {
      let block = chain.mineBlock([
        Tx.contractCall('eco_nft', 'mint', [
          types.uint(50),
          types.uint(500)
        ], deployer.address)
      ]);
      
      if (i === 10000) {
        block.receipts[0].result.expectErr(107); // Max supply error
      }
    }
  }
});

Clarinet.test({
  name: "Verify reward calculation caps",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // Test reward calculation with maximum values
    let block = chain.mineBlock([
      Tx.contractCall('eco_nft', 'set-reward-rate', [
        types.uint(200)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectErr(106); // Invalid params error
  }
});
