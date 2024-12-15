// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SnowmenToken is ERC20 {
    uint256 private constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18;

    constructor() ERC20("Snowmen", "SNOW") {
        _mint(msg.sender, MAX_SUPPLY);
    }
}