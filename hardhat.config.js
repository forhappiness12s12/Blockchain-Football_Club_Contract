require('dotenv').config();
// require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");
require("@nomicfoundation/hardhat-verify")
const { API_URL, ADMIN_PRIVATE_KEY, USER_PRIVATE_KEY, PROFIT_PRIVATE_KEY } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  defaultNetwork: "plume_testnet",
  networks: {
    hardhat: {},
    plume_testnet: {
      url: API_URL,
      accounts: [`0x${ADMIN_PRIVATE_KEY}`, `0x${USER_PRIVATE_KEY}`, `0x${PROFIT_PRIVATE_KEY}`]
    },
  },
  etherscan: {
    apiKey: {
      plume_testnet: 'FAY2VK4QQFCSEMVMCNXSXUIDNC696DEWYS',
    }
  }
};
