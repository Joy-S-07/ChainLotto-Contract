# 🚀 ChainLotto

**Beginner-friendly on‑chain lottery contract**

A simple Solidity smart contract that lets users enter a lottery by paying a fixed entry fee. The contract collects entries each round and allows the owner to pick a winner who receives the contract balance. This repository is designed for learning and experimentation — perfect if you're just getting started with Solidity and Ethereum development.

---

<img width="1919" height="1035" alt="Screenshot_10" src="https://github.com/user-attachments/assets/0964cc83-ff38-4e8c-bcb3-f73f7cead362" />


## 📁 Project Description

**ChainLotto** is a tiny, easy-to-read Solidity project that demonstrates how to:

* accept ETH payments from users (lottery tickets),
* store participants on-chain,
* generate a (simple, *insecure*) pseudo-random winner selection using on-chain block data,
* transfer the accumulated prize to a winner,
* and reset the game for the next round.

The goal is educational: to show core Solidity patterns (storage, payable functions, events, modifiers) in a compact, readable contract.

---

## 🔎 What it does

* Users call `enter()` and send exactly `entryFee` wei to join the current round.
* The contract stores each participant's address in an array.
* The contract owner calls `pickWinner()` to pick one of the participants randomly and send them the full contract balance.
* The contract exposes helper functions and events so you can inspect participants, winner history, and round data.

Key public variables and functions (examples from the contract):

* `owner` — the contract deployer with privilege to run draws and change settings.
* `entryFee` — amount (in wei) required to enter a round.
* `enter()` — payable function to join the current round.
* `getPlayers()` — view function that returns the current list of players.
* `pickWinner()` — owner-only function that chooses a winner (with on-chain randomness) and transfers the prize.
* `setEntryFee(uint)` and `withdraw(uint)` — owner utility functions.

---

## ✨ Features

* ✅ Simple and minimal: easy to read and modify
* ✅ Payable `enter()` function and secure transfer pattern using `call` return-checking
* ✅ Events: `Entered` and `WinnerPicked` for easy off-chain tracking
* ✅ Helper views: get players, last winner, last prize, last draw timestamp
* ⚠️ Note: Uses block-based pseudo-randomness (insecure) — see Security section.

---

## 🔧 Deployed Smart Contract Link

**Deployed Smart Contract Link:** [Deployed Contract](https://celo-sepolia.blockscout.com/address/0x268911e379092f427A0DADd4a588C8f22F46EFF7?tab=index)

(Replace `XXX` with the real contract explorer URL once you deploy to a testnet or mainnet — e.g. Etherscan / Polygonscan / Snowtrace link.)

---

## 🛠️ Getting Started (quick)

### Prerequisites

* A browser and [Remix IDE](https://remix.ethereum.org) (recommended for beginners)
* MetaMask or another Web3 wallet to test on testnets
* Some testnet ETH (Goerli / Sepolia) if you deploy off local devchain

### Quickly test with Remix

1. Create a new file `ChainLotto.sol` and paste the contract code.
2. Set the `pragma` in the contract to match your compiler version (see Security note about `block.prevrandao`).
3. Compile the contract.
4. Deploy with a small `entryFee` constructor value (example: `10000000000000000` for 0.01 ETH).
5. From other accounts in Remix, call `enter()` and send exactly the `entryFee` value.
6. As the owner account, call `pickWinner()` and observe the transfer.

---

## ⚠️ Security & Important Notes (READ)

* **The contract uses on-chain pseudo-randomness** (`keccak256(abi.encodePacked(...))` with block data). This is **not secure** for real-money lotteries because miners/validators can influence or predict these values. **Do not use this contract for high-value prizes.**

* **Recommended for production:** Use a verifiable randomness source such as **Chainlink VRF**. If you want, I can convert the contract to Chainlink VRF for you.

* Always audit and test thoroughly before sending real funds.

---

## 🧪 Tests & Development suggestions

* Try deploying to a local Hardhat or Ganache chain and write tests that:

  * simulate multiple accounts entering,
  * verify only the owner can call `pickWinner`,
  * check that the winner receives the exact contract balance,
  * ensure `players` resets after a draw.

* Add unit tests for edge cases (no players, incorrect entry fee, transfer failures).

---

## 💡 Ideas for improvements (next steps)

* Integrate **Chainlink VRF** for secure randomness
* Add ticket counts so users can buy multiple entries at once
* Take a small fee/commission for the contract owner or treasury
* Add multiple rounds and timestamps/automated draws via a keeper/oracle
* Add front-end UI that interacts with the contract (React + ethers.js)

---

## 📜 License

This project is provided for learning and experimentation. Use at your own risk.

---

## 🧾 Use this code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title ChainLotto — a beginner-friendly lottery contract
/// @notice Users enter by paying `entryFee`. Owner can pick a winner and send the full contract balance to them.
/// @dev IMPORTANT: This contract uses block-based pseudo-randomness (keccak256 on block data) — NOT SECURE FOR
///      PRODUCTION. Use Chainlink VRF or another off-chain verifiable RNG in real deployments.
contract ChainLotto {
    address public owner;
    uint public entryFee;             // amount required to enter (in wei)
    address[] private players;        // current round participants

    address public lastWinner;        // most recent winner
    uint public lastPrize;            // last prize amount (in wei)
    uint public lastDrawTimestamp;    // when the last draw happened

    event Entered(address indexed player);
    event WinnerPicked(address indexed winner, uint amount, uint timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "ChainLotto: caller is not owner");
        _;
    }

    /// @param _entryFee entry fee in wei (for example: 0.01 ether == 10**16 wei)
    constructor(uint _entryFee) {
        owner = msg.sender;
        entryFee = _entryFee;
    }

    /// @notice Enter the lottery by sending exactly `entryFee` wei
    function enter() external payable {
        require(msg.value == entryFee, "ChainLotto: incorrect entry fee");
        players.push(msg.sender);
        emit Entered(msg.sender);
    }

    /// @notice Returns players for the current round
    function getPlayers() external view returns (address[] memory) {
        return players;
    }

    /// @notice Owner picks a winner — transfers entire contract balance to the winner and resets players
    /// @dev Uses insecure on-chain randomness. Do NOT use this for real money/production.
    function pickWinner() external onlyOwner {
        require(players.length > 0, "ChainLotto: no players");

        // INSECURE randomness: do not use this for real money/production.
        uint random = uint(keccak256(abi.encodePacked(
            block.timestamp,
            // Use block.prevrandao for post-merge chains (Solidity >= 0.8.19). If you compile with an older
            // compiler, replace `block.prevrandao` with `block.difficulty`.
            block.prevrandao,
            players.length,
            blockhash(block.number - 1),
            msg.sender
        )));

        uint index = random % players.length;
        address payable winner = payable(players[index]);

        uint prize = address(this).balance;

        // record last draw data
        lastWinner = winner;
        lastPrize = prize;
        lastDrawTimestamp = block.timestamp;

        // reset players for the next round
        delete players;

        // send prize (use call to avoid gas-limit issues)
        (bool sent, ) = winner.call{value: prize}("");
        require(sent, "ChainLotto: prize transfer failed");

        emit WinnerPicked(winner, prize, block.timestamp);
    }

    /// @notice Owner can change the entry fee
    function setEntryFee(uint _fee) external onlyOwner {
        entryFee = _fee;
    }

    /// @notice Owner can withdraw any stuck funds (useful for testing)
    function withdraw(uint _amount) external onlyOwner {
        require(_amount <= address(this).balance, "ChainLotto: insufficient balance");
        (bool sent, ) = payable(owner).call{value: _amount}("");
        require(sent, "ChainLotto: withdraw failed");
    }

    // Allow the contract to receive plain ETH
    receive() external payable {}
    fallback() external payable {}
}
```

---


