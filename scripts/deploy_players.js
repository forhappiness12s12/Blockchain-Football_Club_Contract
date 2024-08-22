// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const contract = await ethers.getContractFactory("PlayersContract");
  const playerContract = await contract.deploy("0xC3bbB0f08bEe1cEE567D272616Af55f5274586F8", "0x06F0E389E27C6265bE18Abb584e9C9f54c512466");
  
  //https://sepolia.etherscan.io/address/0x8ba4E39c907636a51DbEf276b22dBF218b9cCEBf#code
  await playerContract.deployed();
  console.log("Contract deployed:", playerContract.address);
  console.log(await playerContract.owner());
  console.log(await playerContract.managementWallet());
  console.log(await playerContract.stakingToken());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
