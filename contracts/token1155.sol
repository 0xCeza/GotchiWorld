// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Token1155 is ERC1155 {

    constructor() ERC1155("this is the uri") {
    }

    function mint(address _to) external {
        _mint(_to, 0, 10, "");
    }

    function claimTickets(uint256[] calldata _Ids, uint256[] calldata _values) external {
        uint256 id = _Ids[0];
        uint256 val = _values[0];
        _mint(msg.sender, id, val, "");
    }

    function balanceOfAll(address _owner) external view returns (uint256[] memory) {
        uint256[] memory balances_ = new uint256[](7);
        for (uint256 i; i < 7; i++) {
            balances_[i] = balanceOf(_owner, i);
        }
        return balances_;
    }

    function balanceOfCommon(address _owner) external view returns (uint256) {
        return balanceOf(_owner, 0);
    }
}