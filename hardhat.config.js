require('hardhat-deploy');
require('hardhat-deploy-ethers');

const deployer = ['0xb5b3864c7233254981eb6900393ba4ad43c4462540d31311b89fba131a60dce6']; // อย่าลืมเติม JBC ไว้จ่ายค่า gas

module.exports = {
  solidity: {
    version: '0.8.20',
    settings: {
      optimizer: {
        enabled: true // optional, occasionally make tx gas cheaper.
      }
    }
  },
  namedAccounts: {
    deployer: 0,
  },
  networks: {
    JBC: {
      url: "https://rpc-l1.jibchain.net",
      chainId: 8899,
      accounts: deployer
    }
  }
};