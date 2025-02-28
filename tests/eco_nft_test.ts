import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous tests remain the same]

// Adding new tests
Clarinet.test({
  name: "Ensure cannot mint beyond max supply",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // Try to mint beyond max supply
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

// [Add more new tests...]
