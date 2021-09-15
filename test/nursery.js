// We import Chai to use its asserting functions here.
const { expect } = require("chai");

/** */
describe("DEPLOYEMENT", function () {

  let NurseryTest;
  let Token20;
  let Token1155;
  let nurseryContract;
  let token20Contract;
  let token1155Contract;
  let owner;
  let addr1;
  let addr2;
  let addr3;
  let addrs;
  let stakingAmount;
  let stakedAmount;
  let stakingFees;
  let doubleStakingFees;

  // Deployement process
  beforeEach(async function () {
    // Get the signers
    [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();

    // Setup values
    stakingAmount = ethers.utils.parseUnits("69.0", 18);
    stakedAmount = ethers.utils.parseUnits("68.0", 18); 
    stakingFees = ethers.utils.parseUnits("1.0", 18);
    doubleStakingFees = ethers.utils.parseUnits("2.0", 18);
    bigStake = ethers.utils.parseUnits("100.0", 18);
    bigStaked = ethers.utils.parseUnits("99.0", 18);

    // Get the ContractFactory.
    NurseryTest = await ethers.getContractFactory("NurseryTest");
    Token20 = await ethers.getContractFactory("Token20");
    Token1155 = await ethers.getContractFactory("Token1155");

    // Get deployed contracts
    token20Contract = await Token20.deploy(); // Deployed with no args
    token1155Contract = await Token1155.deploy(); // Deployed with no args
    nurseryContract = await NurseryTest.deploy(
      token1155Contract.address,
      token1155Contract.address,
      token20Contract.address,
      token20Contract.address); // Deployer with args

    // Mints 200 ERC20
    await token20Contract.connect(owner).mint();
    await token20Contract.connect(addr1).mint();
    await token20Contract.connect(addr2).mint();
    await token20Contract.connect(addr3).mint();

    // Allow the contract to move users ERC20
    await token20Contract.connect(addr1).approve(nurseryContract.address,bigStake);
    await token20Contract.connect(addr2).approve(nurseryContract.address,stakingAmount);
    await token20Contract.connect(addr3).approve(nurseryContract.address,stakingAmount);

    // Allow staking the contracts GHST into ERC20 using stakeGHST();
    await nurseryContract.approveGhst();

    /* Used to understand why ERC20 transferFrom nursery to ERC20 reverts, didnt find why.
    const nuseryToERC20Allowance = (await token20Contract.allowance(nurseryContract.address, token20Contract.address));
    console.log(`nuseryToERC20Allowance : ${nuseryToERC20Allowance}`)

    const addr3ToNurseryAllowance = (await token20Contract.allowance(addr3.address, nurseryContract.address));
    console.log(`addr3ToNurseryAllowance : ${addr3ToNurseryAllowance}`)

    console.log(`addr3 = ${addr3.address} \nnursery = ${nurseryContract.address} \nerc20 = ${token20Contract.address} `)
    */ 

    // Addr3 will always have GHST Staked
    await nurseryContract.connect(addr3).stakeGhst(stakingAmount);
  });

  it("Contract: Should set all token address", async function () {
    expect(await nurseryContract.diamond()).to.be.equal(token1155Contract.address);
    expect(await nurseryContract.ghstDiamond()).to.be.equal(token1155Contract.address);
    expect(await nurseryContract.ghstERC20()).to.be.equal(token20Contract.address);
    expect(await nurseryContract.petContract()).to.be.equal(token20Contract.address);
  });

  it("Addr1 & 2 & Owner: Should all have 200 token", async function () {
    expect(await token20Contract.balanceOf(addr1.address)).to.be.equal(ethers.utils.parseUnits("200.0", 18));
    expect(await token20Contract.balanceOf(addr2.address)).to.be.equal(ethers.utils.parseUnits("200.0", 18));
    expect(await token20Contract.balanceOf(owner.address)).to.be.equal(ethers.utils.parseUnits("200.0", 18));
  });

  it("Addr3: Should all have 200 - 99 token", async function () {
    expect(await token20Contract.balanceOf(addr3.address)).to.be.equal(ethers.utils.parseUnits("131.0", 18));
  });

  it("Addr1 & 2: Allowed to use 99 token", async function () {
    expect(await token20Contract.allowance(addr1.address,nurseryContract.address)).to.be.equal(bigStake);
    expect(await token20Contract.allowance(addr2.address,nurseryContract.address)).to.be.equal(stakingAmount);
  });

  it("Addr3: Already staked, should have 0 Allowance", async function () {
    expect(await token20Contract.allowance(addr3.address,nurseryContract.address)).to.be.equal(0);
  });

  it("totalMember = 2", async function () {
    expect(await nurseryContract.totalMembers()).to.be.equal(2);
  });

  describe("STAKING", function () {
    beforeEach(async function () {
      await nurseryContract.connect(addr1).stakeGhst(bigStake);
    })  

    it("totalMember = 3", async function () {
      expect(await nurseryContract.totalMembers()).to.be.equal(3);
    });

    it("Addr1: Should revert stacking twice", async function() {
      await expect(nurseryContract.connect(addr1).stakeGhst(bigStake)).to.be.reverted;
    })

    it("Addr2: Should revert unstacking, did not stake anything", async function() {
      await expect(nurseryContract.connect(addr2).unstakeGhst()).to.be.reverted;
    })

    it("Addr1: Balance = 68 GHST", async function () {
      expect(await nurseryContract.connect(addr1).stakedAmount()).to.be.equal(bigStaked);
    })

    it("Addr2: Balance = 0 GHST", async function () {
      expect(await nurseryContract.connect(addr2).stakedAmount()).to.be.equal(0);
    })

    it("Addr1: hasStaked is true", async function () {
      expect(await nurseryContract.hasStaked(addr1.address)).to.be.true;
    })

    it("Addr2: hasStaked is false", async function () {
      expect(await nurseryContract.hasStaked(addr2.address)).to.be.false;
    })

    it("Addr1: shouldPet is true", async function () {
      expect(await nurseryContract.shouldPet(addr1.address)).to.be.true;
    })

    it("Addr2: shouldPet is false", async function () {
      expect(await nurseryContract.shouldPet(addr2.address)).to.be.false;
    })

    it("Contract: collected fees should = 2", async function () {
      expect(await nurseryContract.collectedFees()).to.be.equal(doubleStakingFees);
    })

    describe("CLAIMING TICKETS", function() {
      beforeEach(async function () {
        await nurseryContract.connect(owner).claimTicketsAndWithdraw([0],[1]);
      })

      it("Owner: Owns 1 Common ticket", async function () {
        expect(await token1155Contract.balanceOfCommon(owner.address)).to.equal(1);
      })

      it("Addr1: Cannot claim tickets", async function () {
        await expect(nurseryContract.connect(addr1).claimTicketsAndWithdraw([0],[1])).to.be.reverted;
      })
    })

    describe("WITHDRAWALS AND UNSTAKINGS", function () {
      beforeEach(async function () {
        await nurseryContract.connect(owner).withdrawCollectedFees();
        await nurseryContract.connect(addr1).unstakeGhst();
      })

      it("totalMember = 2", async function () {
        expect(await nurseryContract.totalMembers()).to.be.equal(2);
      });

      it("Contract: Balance = 98 GHST, because ADDR3 + ERC20 transferFrom KO", async function () {
        expect((await token20Contract.balanceOf(nurseryContract.address))).to.be.equal(stakedAmount);
      })

      it("Contract: collected fees = 0", async function () {
        expect((await nurseryContract.collectedFees()).toNumber()).to.be.equal(0);
      })

      it("Addr1: Balance = 0 GHST", async function () {
        expect((await nurseryContract.connect(addr1).stakedAmount()).toNumber()).to.be.equal(0);
      })
  
      it("Addr1: hasStaked is false", async function () {
        expect(await nurseryContract.hasStaked(addr1.address)).to.be.false;
      })
  
      it("Addr1: shouldPet is false", async function () {
        expect(await nurseryContract.shouldPet(addr1.address)).to.be.false;
      })

    })
  })
});
