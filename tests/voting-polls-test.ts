import { Clarinet, Tx, Chain, Account, types } from "clarinet";

Clarinet.test({
  name: "Voting Polls - Full Workflow",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet1 = accounts.get("wallet_1")!;
    const wallet2 = accounts.get("wallet_2")!;

    // 1️⃣ Create a poll (admin)
    let block = chain.mineBlock([
      Tx.contractCall(
        "voting-polls",
        "create-poll",
        [
          types.ascii("Which is the best blockchain?"),
          types.list([types.ascii("Bitcoin"), types.ascii("Stacks"), types.ascii("Ethereum")])
        ],
        deployer.address
      )
    ]);
    block.receipts[0].result.expectOk().expectUint(1);

    // 2️⃣ Wallet 1 votes (Stacks)
    block = chain.mineBlock([
      Tx.contractCall(
        "voting-polls",
        "vote",
        [types.uint(1), types.uint(1)],
        wallet1.address
      )
    ]);
    block.receipts[0].result.expectOk();

    // 3️⃣ Wallet 2 votes (Ethereum)
    block = chain.mineBlock([
      Tx.contractCall(
        "voting-polls",
        "vote",
        [types.uint(1), types.uint(2)],
        wallet2.address
      )
    ]);
    block.receipts[0].result.expectOk();

    // 4️⃣ Admin votes (Bitcoin)
    block = chain.mineBlock([
      Tx.contractCall(
        "voting-polls",
        "vote",
        [types.uint(1), types.uint(0)],
        deployer.address
      )
    ]);
    block.receipts[0].result.expectOk();

    // 5️⃣ Check results
    let poll = chain.callReadOnlyFn("voting-polls", "get-poll", [types.uint(1)], deployer.address);
    poll.result.expectSome();
    
    let bitcoinVotes = chain.callReadOnlyFn("voting-polls", "get-result", [types.uint(1), types.uint(0)], deployer.address);
    bitcoinVotes.result.expectUint(1);

    let stacksVotes = chain.callReadOnlyFn("voting-polls", "get-result", [types.uint(1), types.uint(1)], deployer.address);
    stacksVotes.result.expectUint(1);

    let ethereumVotes = chain.callReadOnlyFn("voting-polls", "get-result", [types.uint(1), types.uint(2)], deployer.address);
    ethereumVotes.result.expectUint(1);
  }
});
