// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OasisToken is ERC20 {

    address public owner;

    constructor() ERC20("Oasis Token", "OAT") {
        owner = msg.sender;
    }
}