// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestUSDT is ERC20 {
    constructor() ERC20("TestUSDT", "TUSDT") {
        _mint(msg.sender, 1000000 * 10 ** decimals()); // Mint 1,000,000 tokens and assign them to the deployer
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
