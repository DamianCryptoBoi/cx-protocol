require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
// require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");
// require("@nomiclabs/hardhat-truffle5");
// require("solidity-docgen");

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.13",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {
      gas: 120000000,
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true,
      timeout: 1800000,
      chainId: 69,
    },
    rinkeby: {
      url: process.env.PROVIDER_URL,
      accounts: [process.env.PRIVATE_KEY],
      gas: 12000000,
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true,
      timeout: 1800000,
      chainId: 4,
    },
    bscTestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",

      accounts: [process.env.PRIVATE_KEY],
      gas: 12000000,
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true,
      timeout: 100000000,
      chainId: 97,
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: {
      rinkeby: "E2DE24B9RAGAGAPH7HP69FYIUIITI2HGQN",
      bscTestnet: "9E36GDSJK15GYXXN85186T5GDQI32B29MF",
    },
  },
};
