const { expect } = require("chai");
const { Contract } = require('ethers');
const contractABI = require('../artifacts/contracts/FootballClubTrade.sol/FootballClubTrade.json');
const { parseEther } = require("ethers/lib/utils");
const erc20ABI = require("../abi/erc20.json").abi;

//testcases
//  0. set position fee
//  0. set admin address
//  1. register clubs
//  2. get registered clubs
//  3. set club price
//  4. get club price
//  5. register future
//  6. get futures
//  7. update future
//  8. open position
//  9. close position
//  10. get open positions
//  11. get all positions
//  12. get portfolio
//  13. execute future

describe("FootballClubTrade", function () {
  let CONTRACT_ADDRESS //= "0x85A34427Fe78d5939Ed9ed1901b20A4648Fc9dBa"
  let TOKEN_ADDRESS //= "0x4632403a83fb736Ab2c76b4C32FAc9F81e2CfcE2"
  let ADMIN_ADDRESS //= "0x06F0E389E27C6265bE18Abb584e9C9f54c512466"
  let PROFIT_ADDRESS //= "0x8652Dad72ceD256516Ea48324b5Ae09568884f80"
  let USER_ADDRESS //= "0x3EDB9979e9f5755bDF71EE08ab2264BedEBBe980"
  const ZERO_ADDRESS = ethers.constants.AddressZero

  let tradeContract
  let tokenContract
  let futureIndex

  before(async ()=>{
    const [owner, user, wallet2, ] = await ethers.getSigners();
    ADMIN_ADDRESS = owner.address
    USER_ADDRESS = user.address
    PROFIT_ADDRESS = wallet2.address
    const TestToken = await ethers.getContractFactory("TestUSDT");
    tokenContract = await TestToken.deploy();
    await tokenContract.deployed();

    TOKEN_ADDRESS = tokenContract.address;

    const FootballClubTrade = await ethers.getContractFactory("FootballClubTrade");
    tradeContract = await FootballClubTrade.deploy(TOKEN_ADDRESS, ADMIN_ADDRESS, PROFIT_ADDRESS);
    await tradeContract.deployed();

    CONTRACT_ADDRESS = tradeContract.address;

    //send token to user
    await tokenContract.connect(owner).transfer(USER_ADDRESS, 100_000_000_000);

    // tradeContract =  new ethers.Contract(
    //   CONTRACT_ADDRESS,
    //   contractABI.abi,
    //   owner,
    // );

    // tokenContract = new ethers.Contract(
    //   TOKEN_ADDRESS,
    //   erc20ABI,
    //   owner
    // );

    console.log("contract", TOKEN_ADDRESS, CONTRACT_ADDRESS)
  })

  describe("Football Club Trading", () => {
    it("Should register clubs", async()=>{
      let tx = await tradeContract.registerClub("Real Madrid", "RMA")
      await tx.wait();
      let clubIndex = await tradeContract.getClubIndex();
      expect(clubIndex.toString()).to.equal("1");

      tx = await tradeContract.registerClub("FC Barcelona", "FCB")
      await tx.wait();
      clubIndex = await tradeContract.getClubIndex();
      expect(clubIndex.toString()).to.equal("2");
    })

    it("Should not register same club", async()=>{
      try {
        let tx = await tradeContract.registerClub("Real Madrid", "RMA")
        await tx.wait();
      } catch(e) {
        expect(e.message).include("Club already registered");
      }      
    })

    it("Should read all clubs", async()=>{
      let clubs = await tradeContract.getAllClubs()
      expect(clubs.length).to.equal(2);
      expect(clubs[0].name).to.equal("Real Madrid");
      expect(clubs[1].name).to.equal("FC Barcelona");
    })

    it("Should register future date", async()=>{
      let tx = await tradeContract.registerFutureDate(Math.round(new Date("2024-08-31T00:00:00Z").getTime()/1000))
      await tx.wait();
      futureIndex = await tradeContract.futureIndex();
      expect(futureIndex.toString()).to.equal("1");
    })

    it("Should update club price", async()=>{
      let price = await tradeContract.getClubStockPrice(0);
      expect(price.toString()).to.equal("100000000");
      let tx = await tradeContract.setClubStockPrice(0, 110_000_000)
      await tx.wait();
      price = await tradeContract.getClubStockPrice(0);
      expect(price.toString()).to.equal("110000000");
    })

    it("Should not open position because default accept date is 15 days", async ()=>{
      try {
        let tx = await tradeContract.openPosition(0, 5, 1, 100_000_000, 0)
        await tx.wait();
      } catch(e) {
        expect(e.message).include("Current time is not within the allowed acceptance period");
      }
    })

    it("Should open position after update future date", async ()=>{
      const [owner, user, wallet2, ] = await ethers.getSigners();

      let newDate = new Date()
      newDate.setDate(newDate.getDate()+16);

      console.log("contract balance", await tokenContract.balanceOf(tradeContract.address))
      console.log("user balance", await tokenContract.balanceOf(user.address))
      let tx = await tradeContract.updateFutureDate(0, Math.round(newDate.getTime()/1000))
      await tx.wait();
      tx = await tokenContract.connect(user).approve(tradeContract.address, ethers.constants.MaxUint256);
      await tx.wait();

      tx = await tradeContract.connect(user).openPosition(0, 5, 1, 100_000_000, 0)
      await tx.wait();

      console.log("contract balance", await tokenContract.balanceOf(tradeContract.address))
      console.log("user balance", await tokenContract.balanceOf(user.address))

      let position = await tradeContract.getOpenPosition(0);
      expect(position.clubId.toString()).to.equal("0");
      expect(position.positionType.toString()).to.equal("1");
      expect(position.userAddress).to.equal(user.address);
    })
    it("Should get user's open positions", async ()=>{
      const [owner, user, wallet2, ] = await ethers.getSigners();
      const positions = await tradeContract.getUserOpenPositions(user.address)
      expect(positions.length).to.equal(1);
    })
    it("Should not close position by other user", async ()=>{
      const [owner, user, wallet2, ] = await ethers.getSigners();
      try {
        const tx = await tradeContract.closePosition(0);
        await tx.wait();
      } catch(e) {
        expect(e.message).include("No privilege to close this position");
      }
    })
    it("Should close position by user", async ()=>{
      const [owner, user, wallet2, ] = await ethers.getSigners();
      console.log("contract balance", await tokenContract.balanceOf(tradeContract.address))
      console.log("user balance", await tokenContract.balanceOf(user.address))
      const tx = await tradeContract.connect(user).closePosition(0);
      await tx.wait();
      const positions = await tradeContract.getUserOpenPositions(user.address)
      expect(positions.length).to.equal(0);
      console.log("contract balance", await tokenContract.balanceOf(tradeContract.address))
      console.log("user balance", await tokenContract.balanceOf(user.address))
    })

    it("Should open long position and process it", async ()=>{
      const [owner, user, wallet2, ] = await ethers.getSigners();

      let newDate = new Date()
      newDate.setDate(newDate.getDate()+16);

      console.log("contract balance", await tokenContract.balanceOf(tradeContract.address))
      console.log("user balance", await tokenContract.balanceOf(user.address))
      tx = await tradeContract.connect(user).openPosition(0, 5, 1, 120_000_000, 0)
      await tx.wait();

      let positions = await tradeContract.getUserOpenPositions(user.address)
      expect(positions.length).to.equal(1);

      console.log("contract balance", await tokenContract.balanceOf(tradeContract.address))
      console.log("user balance", await tokenContract.balanceOf(user.address))
      let userStocks = await  tradeContract.getUserStock(user.address);
      expect(userStocks[0].toString()).to.equal("0");
      expect(userStocks[1].toString()).to.equal("0");

      tx = await tradeContract.executeFuture(0)
      await tx.wait();

      positions = await tradeContract.getUserOpenPositions(user.address)
      expect(positions.length).to.equal(0);
      console.log("contract balance", await tokenContract.balanceOf(tradeContract.address))
      console.log("user balance", await tokenContract.balanceOf(user.address))
      userStocks = await  tradeContract.getUserStock(user.address);
      expect(userStocks[0].toString()).to.equal("5");
      expect(userStocks[1].toString()).to.equal("0");
    })
  })
});
