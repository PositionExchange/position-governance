require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-ethers")
require("dotenv").config();
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.4",
     settings: {
      optimizer: {
          enabled: true,
          runs: 200,
        },
  },
  },
  networks: {
    bsctestnet: {
      url: process.env.BSCTESTNET_NETWORK_URL,
      chainId: 97,
      gasPrice: 20000000000,
      accounts: [process.env.BSCTESTNET_PRIVATE_KEY],
    },
    bscmainnet: {
      url: process.env.BSCMAINNET_NETWORK_URL,
      chainId: 56,
      gasPrice: 20000000000,
      accounts: [process.env.BSCMAINNET_PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: 'TEMK85WIQR8NGI74AZBCJ3J88FI49XRHJN',
  },
  
  
};
