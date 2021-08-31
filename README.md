# GotchiWorld

To test, copy Nursery.sol, create NurseryTest.sol
In NurseryTest.sol modify the following :

1. Deplace function line 24: function claimTickets(uint256[] calldata _ids, uint256[] calldata _values) external;
**from** interface IStakingFacet 
**to** interface ITicketsFacet
DO NOT LEAVE EMPTY LINE (otherwise add 1 to future instructions :D)

2. Modify line 46
**from** contract Nursery is Ownable, ERC1155Receiver {
**to** contract NurseryTest is Ownable, ERC1155Receiver {

3. Modify line 92 
**from** stakingFacet = IStakingFacet(ghstDiamond); // is immutable
**to** stakingFacet = IStakingFacet(ghstERC20); // is immutable

4. Modify line 179
**from**  stakingFacet.claimTickets(_ids, _values);
**to** ticketsFacet.claimTickets(_ids, _values);

5. Modify line 306 
**from** if(hasApprovedGotchiInteraction(_member) && hasStaked(_member) && hasMembership(_member)) {
**to** if(/*hasApprovedGotchiInteraction(_member) &&*/ hasStaked(_member) && hasMembership(_member)) {


Execute using npx hardhat test
