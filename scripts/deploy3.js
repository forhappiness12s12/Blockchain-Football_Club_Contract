// Import the Hardhat Runtime Environment explicitly
const hre = require("hardhat");

async function main() {
  // Get the contract factory using hre.ethers instead of just ethers
  const TokenPurchaseContract = await hre.ethers.getContractFactory("FootballClubTrade");
  
  // Deploy the contract with the necessary constructor arguments
  const tokenPurchaseContract = await TokenPurchaseContract.deploy(
    "0x4632403a83fb736Ab2c76b4C32FAc9F81e2CfcE2", 
    "0x06F0E389E27C6265bE18Abb584e9C9f54c512466", 
    "0x8652Dad72ceD256516Ea48324b5Ae09568884f80"
  );
  
  // Wait for the deployment to be complete
  await tokenPurchaseContract.deployed();

  console.log("tokenPurchaseContract deployed:", tokenPurchaseContract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
