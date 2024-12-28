import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can mint eco-friendly NFT",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;

    let block = chain.mineBlock([
      Tx.contractCall('eco_nft', 'mint', [
        types.uint(50), // carbon footprint below limit
        types.uint(500) // energy consumed
      ], deployer.address)
    ]);

    // Mint should succeed
    block.receipts[0].result.expectOk();
    // Should return token ID 0
    assertEquals(block.receipts[0].result, types.ok(types.uint(0)));

    // Verify token data
    let tokenDataBlock = chain.mineBlock([
      Tx.contractCall('eco_nft', 'get-token-data', [
        types.uint(0)
      ], deployer.address)
    ]);

    const tokenData = tokenDataBlock.receipts[0].result.expectOk().expectSome();
    assertEquals(tokenData['carbon-footprint'], types.uint(50));
    assertEquals(tokenData['energy-consumed'], types.uint(500));
    assertEquals(tokenData['green-certified'], types.bool(true));
  }
});

Clarinet.test({
  name: "Ensure cannot mint NFT exceeding carbon limit",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;

    let block = chain.mineBlock([
      Tx.contractCall('eco_nft', 'mint', [
        types.uint(150), // carbon footprint above limit
        types.uint(500)
      ], deployer.address)
    ]);

    // Mint should fail
    block.receipts[0].result.expectErr(types.uint(103)); // err-exceeds-carbon-limit
  }
});

Clarinet.test({
  name: "Test NFT transfer",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;

    // First mint an NFT
    let mintBlock = chain.mineBlock([
      Tx.contractCall('eco_nft', 'mint', [
        types.uint(50),
        types.uint(500)
      ], deployer.address)
    ]);

    // Then transfer it
    let transferBlock = chain.mineBlock([
      Tx.contractCall('eco_nft', 'transfer', [
        types.uint(0),
        types.principal(wallet1.address)
      ], deployer.address)
    ]);

    transferBlock.receipts[0].result.expectOk();

    // Verify new owner
    let tokenDataBlock = chain.mineBlock([
      Tx.contractCall('eco_nft', 'get-token-data', [
        types.uint(0)
      ], deployer.address)
    ]);

    const tokenData = tokenDataBlock.receipts[0].result.expectOk().expectSome();
    assertEquals(tokenData['owner'], wallet1.address);
  }
});