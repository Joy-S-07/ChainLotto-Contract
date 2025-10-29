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
    /// @dev Uses insecure on-chain randomness. Do NOT use in production as-is.
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

