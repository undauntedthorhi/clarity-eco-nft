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
  name: "Test NFT staking",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // First mint an NFT
    let mintBlock = chain.mineBlock([
      Tx.contractCall('eco_nft', 'mint', [
        types.uint(50),
        types.uint(500)
      ], deployer.address)
    ]);

    // Stake the NFT
    let stakeBlock = chain.mineBlock([
      Tx.contractCall('eco_nft', 'stake', [
        types.uint(0)
      ], deployer.address)
    ]);

    stakeBlock.receipts[0].result.expectOk();

    // Verify staking data
    let stakingDataBlock = chain.mineBlock([
      Tx.contractCall('eco_nft', 'get-staking-data', [
        types.uint(0)
      ], deployer.address)
    ]);

    const stakingData = stakingDataBlock.receipts[0].result.expectOk().expectSome();
    assertEquals(stakingData['staked'], types.bool(true));
  }
});

Clarinet.test({
  name: "Test NFT unstaking",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // Mint and stake NFT
    let mintBlock = chain.mineBlock([
      Tx.contractCall('eco_nft', 'mint', [
        types.uint(50),
        types.uint(500)
      ], deployer.address)
    ]);

    let stakeBlock = chain.mineBlock([
      Tx.contractCall('eco_nft', 'stake', [
        types.uint(0)
      ], deployer.address)
    ]);

    // Advance chain
    chain.mineEmptyBlock(10);

    // Unstake NFT
    let unstakeBlock = chain.mineBlock([
      Tx.contractCall('eco_nft', 'unstake', [
        types.uint(0)
      ], deployer.address)
    ]);

    unstakeBlock.receipts[0].result.expectOk();

    // Verify unstaked
    let stakingDataBlock = chain.mineBlock([
      Tx.contractCall('eco_nft', 'get-staking-data', [
        types.uint(0)
      ], deployer.address)
    ]);

    const stakingData = stakingDataBlock.receipts[0].result.expectOk().expectSome();
    assertEquals(stakingData['staked'], types.bool(false));
  }
});
