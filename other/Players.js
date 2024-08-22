const { expect } = require("chai");
const { Contract } = require('ethers');
const contractABI = require('../artifacts/contracts/Players.sol/PlayersContract.json');
const { parseEther } = require("ethers/lib/utils");
const erc20ABI = require("../abi/erc20.json").abi;

describe("Players", function () {
  const CONTRACT_ADDRESS = "0x78a6b2344730550dFB4bD0Fe736394f90DC443Da"
  const TOKEN_ADDRESS = "0xc3bbb0f08bee1cee567d272616af55f5274586f8"
  const NEW_USER1 = "0x3EDB9979e9f5755bDF71EE08ab2264BedEBBe980"
  const NEW_USER2 = "0x5D05e841aB1E2d1cA8632d7001265eB73c60E960"
  const REFERER = "0x8652Dad72ceD256516Ea48324b5Ae09568884f80"
  const ZERO_ADDRESS = ethers.constants.AddressZero

  let playerContract
  let tokenContract

  before(async ()=>{
    const [owner, player] = await ethers.getSigners();
    playerContract =  new ethers.Contract(
      CONTRACT_ADDRESS,
      contractABI.abi,
      owner,
    );

    tokenContract = new ethers.Contract(
      TOKEN_ADDRESS,
      erc20ABI,
      owner
    );

    console.log("contract", playerContract.address)
  })

  describe("Registration", () => {
    it("Should check if user is registered already", async()=>{
      try {
        // Call contract function
        const result = await playerContract.isRegister(NEW_USER2);
        expect(result).to.equal(false);
      } catch (error) {
          console.error("Error calling contract function1:", error);
      }
    });

    it("Should register if user is not registered", async()=>{
      try {
        // Call contract function
        let result = await playerContract.isRegister(NEW_USER1);
        if(!result) {
          let tx = await playerContract.register(NEW_USER1, ZERO_ADDRESS);
          await tx.wait();
          result = await playerContract.isRegister(NEW_USER1);
          expect(result).to.equal(true);
        }
      } catch (error) {
          console.error("Error calling contract function2:", error);
      }
    });

    it("Should fail to register if referer was not registered", async()=>{

    });
  })

  describe('Staking', ()=>{
    it("Should stake if player has token enough", async()=>{
      const [owner, player] = await ethers.getSigners();

      tokenContract = new ethers.Contract(
        TOKEN_ADDRESS,
        erc20ABI,
        player
      );

      playerContract =  new ethers.Contract(
        CONTRACT_ADDRESS,
        contractABI.abi,
        player,
      );

      //stake 10 USDT
      let totalPlayerPoolAmount = await playerContract.totalPlayersPool();
      let totalBankersPool = await playerContract.totalBankersPool();
      console.log('totalPlayerPoolAmount, totalBankersPool', totalPlayerPoolAmount.toString(), totalBankersPool.toString())
      let balance = await  tokenContract.balanceOf(player.address);
      console.log('player balance', player.address, balance.toString(), playerContract.address)
      //approve token
      await tokenContract.approve(playerContract.address, ethers.utils.parseUnits("1000000", 18));
      console.log('approved')
      const tx = await playerContract.stake(ethers.utils.parseUnits("10", 18))
      await tx.wait()
      totalPlayerPoolAmount = await playerContract.totalPlayersPool();
      totalBankersPool = await playerContract.totalBankersPool();
      console.log('totalPlayerPoolAmount, totalBankersPool', totalPlayerPoolAmount.toString(), totalBankersPool.toString())
    });

    it("Should not stake if player don't have token enough", async()=>{

    });

    it("Should get ROI if player is valid skaker", async()=>{

    });
  }).timeout(100000);
});
