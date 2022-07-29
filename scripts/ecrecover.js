const ethers = require("ethers");

const types = {
  Order: [
    { name: "makerToken", type: "address" },
    { name: "takerToken", type: "address" },
    { name: "sourceChainId", type: "uint8" },
    { name: "destinationChainId", type: "uint8" },
    { name: "makingAmount", type: "uint256" },
    { name: "takingAmount", type: "uint256" },
    { name: "expireTime", type: "uint256" },
    { name: "salt", type: "uint256" },
  ],
};

const sign = async (order, signer) => {
  const domain = {
    name: "CXExchange",
    version: "1.0",
    chainId: 97,
    verifyingContract: "0xf9c0fCFce8EeA9216ed5ca322ccfAfe66CA133e0",
  };

  signature = await signer._signTypedData(domain, types, order);

  console.log(signature);
};

a = {
  makerToken: "0x0000000000000000000000000000000000000000",
  takerToken: "0x0000000000000000000000000000000000000000",
  sourceChainId: 4,
  destinationChainId: 97,
  makingAmount: "10000000000000000",
  takingAmount: "100000000000000000",
  expireTime: 1879521925,
  salt: 1658769925,
};

const pk = "4a55fea249176f7d9043b9db9d00a451f84cc3b1fa0a6e71beca0e834e3f9577";

account = new ethers.Wallet(pk);

sign(a, account);

//rinkeby
// token: 0xA191B8605D549E149E2bAB81e01Ea53B5E9657E1
// exchange: 0x970bC92DEdA14C4E6bBeA3C4288Ff4807822731f

//testBSC
// token: 0xA635399Fd3827d21826B22ca9dE42585Ea664bF6
// exchange: 0xf9c0fCFce8EeA9216ed5ca322ccfAfe66CA133e0
