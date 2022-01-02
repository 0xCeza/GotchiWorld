// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/*****************************
*     CONTRACT GAME ITEMS
_____________________________*/

contract GameItems is ERC1155Supply {
    uint256 public constant FARMERS_ID = 0;
    uint256 public constant FARMERS_MAX = 10;

    constructor() public ERC1155("nometadata") {
        
    }

    function mintFarmers(uint _amount) public {
        require(totalSupply(FARMERS_ID) + _amount <= FARMERS_MAX, "MAIN: Farmers supply limit reached");
        _mint(msg.sender, FARMERS_ID, _amount, "");
    }        

    function getFarmersId() public pure returns(uint256) {
        return FARMERS_ID;
    }

}

/*****************************
*     CONTRACT MATERIALS
_____________________________*/

contract Materials is ERC20Burnable {

    address public farmAddress;

    constructor() public ERC20("Materials", "MAT") {
        
    }

    function setFarmAddress(address _farmAddress) external /** Only owner */ {
        farmAddress = _farmAddress;
    }

    function mintMaterials(address _to, uint256 _amount) external {
        require(msg.sender == farmAddress, "Materials: Only farm contract can mint");
        _mint(_to,_amount);
    }
}

/*****************************
*     CONTRACT FARMS
_____________________________*/

interface IGameItems {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
    function getFarmersId() external pure returns(uint256);
}

interface IMaterials {
    function mintMaterials(address _to, uint256 _amount) external;
}

contract Farms {

    IGameItems private immutable gameItems;
    IMaterials private immutable materials;
    
    uint256 private farmerId;

    mapping (address => mapping (uint256 => uint256)) public ownerAndIdToAmountStaked;
    mapping (address => uint256) public ownerToPreviousTimestamp;
    mapping (address => uint256) public ownerToClaimableMaterials;

    constructor(address _gameItemsAddress, address _materialsAddress) {
        gameItems = IGameItems(_gameItemsAddress);
        materials = IMaterials(_materialsAddress);

        farmerId = gameItems.getFarmersId();
    }

    function materialsToClaim(address _owner) public view returns (uint256) {
        uint256 claimableMaterials = ownerToClaimableMaterials[_owner];
        uint256 lastTimestamp = ownerToPreviousTimestamp[_owner];
        uint256 lastAmountFarmer = ownerAndIdToAmountStaked[_owner][farmerId];

        // claimableMaterials += (((block.timestamp - lastTimestamp) / 24 hours) * 5) * lastAmountFarmer;

        claimableMaterials += (block.timestamp - lastTimestamp) * lastAmountFarmer;
        return claimableMaterials;
    }

    function _updateClaimableMaterials(address _owner) internal {
        /*
        uint256 claimableMaterials = ownerToClaimableMaterials[_owner];
        uint256 lastTimestamp = ownerToPreviousTimestamp[_owner];
        uint256 lastAmountFarmer = ownerAndIdToAmountStaked[_owner][farmerId];

        claimableMaterials += (((block.timestamp - lastTimestamp) / 24 hours) * 5) * lastAmountFarmer;
        */

        uint256 claimableMaterials = materialsToClaim(msg.sender);

        ownerToPreviousTimestamp[_owner] = block.timestamp;
        ownerToClaimableMaterials[_owner] += claimableMaterials;
    }

    function claimFarmedMaterials() external {        
        // 0. Require materials available
        require(materialsToClaim(msg.sender) > 0, "Farms: Not enough Mat to claim");

        // 1. Update updateClaimableMaterials
        _updateClaimableMaterials(msg.sender);

        // 3. Mint tokens & reset value to earn
        uint256 earnedMaterials = ownerToClaimableMaterials[msg.sender];
        ownerToClaimableMaterials[msg.sender] = 0;
        materials.mintMaterials(msg.sender, earnedMaterials);
    }

    // staking
    function addFarmersToMaterials(uint256 _amountOfFarmers) public {
        // 0. Require approval + have enough Farmers

        // 1. Update updateClaimableMaterials
        _updateClaimableMaterials(msg.sender);

        // 2. Change ownership of _amountOfFarmers to this contract 
        gameItems.safeTransferFrom(msg.sender, address(this), farmerId, _amountOfFarmers, "");

        // 3. Update Mapping used for stopFarming
        ownerAndIdToAmountStaked[msg.sender][farmerId] += _amountOfFarmers;
    }

    // unstaking
    function removeFarmersFromMaterials(uint _amountOfFarmers) public {
        // 0. Require have enough Farmers
        require(ownerAndIdToAmountStaked[msg.sender][farmerId] >= _amountOfFarmers, "Farms: Don't have enough farmers");

        // 1. Update updateClaimableMaterials
        _updateClaimableMaterials(msg.sender);

        // 2. Update mapping with amount of farmers 
        ownerAndIdToAmountStaked[msg.sender][farmerId] -= _amountOfFarmers;

        // 3. transfer from contract to owner 
        gameItems.safeTransferFrom(address(this), msg.sender, farmerId, _amountOfFarmers, "");
    }

    /************************************************
     * 
     *   ERC1155Receiver 
     * 
     ************************************************/
    /**
     * @dev both function in ERC1155Receiver are used so that the contract can own ERC1155 tokens
     */
    function onERC1155Received(
    address /*operator*/,
    address /*from*/,
    uint256 /*id*/,
    uint256 /*value*/,
    bytes calldata /*data*/
    )
    external
    pure
    returns(bytes4)
    {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
    address /*operator*/,
    address /*from*/,
    uint256[] calldata /*ids*/,
    uint256[] calldata /*values*/,
    bytes calldata /*data*/
    )
    external
    pure
    returns(bytes4)
    {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}

/*****************************
*     CONTRACT UTILITY
*____________________________*/

contract Utility {

    function getCurrentTimestamp() public view returns(uint256) {
        return block.timestamp;
    }

}
