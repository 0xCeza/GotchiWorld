// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token20 is ERC20 {

    mapping (address => uint256) public _balances;

    constructor() ERC20("tok","tok") {
    }

    function mint() public {
        _mint(msg.sender, (200*10**18));
    }

    function stakeGhst(uint256 _amount) external {
        _balances[msg.sender] += _amount;
        //transferFrom(msg.sender, address(this), _amount);
        // ^hardhat doesnt want this transfer to work, reverted with not enough allowance
        // console.log say msg.sender provided MAX_INT allowance to address(this)... Idk
    }

    function withdrawGhstStake(uint256 _amount) external {
        //require(_balances[msg.sender] >= _amount,"not enough to unstake");
        _balances[msg.sender] -= _amount;
    }

    function _who() external view returns (address) {
        return address(this);
    }
}