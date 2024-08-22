// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
//https://sepolia.etherscan.io/address/0xa1bE3B124D421F894e1a7Ee77BE6893A1C802ad2#code
async function main() {
  const TokenPurcahseContract = await ethers.getContractFactory("FootballClubTrade");
  const tokenPurcahseContract = await TokenPurcahseContract.deploy("0x4632403a83fb736Ab2c76b4C32FAc9F81e2CfcE2", "0x06F0E389E27C6265bE18Abb584e9C9f54c512466", "0x8652Dad72ceD256516Ea48324b5Ae09568884f80");
  
  await tokenPurcahseContract.deployed();

  console.log("tokenPurcahseContract deployed:", tokenPurcahseContract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
