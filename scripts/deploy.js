const hre = require("hardhat");

async function main() {
  [owner, a1, a2] = await ethers.getSigners();
  // Token = await ethers.getContractFactory("MockERC20");
  // token = await Token.deploy();
  // token.deployed();
  // console.log("token: " + token.address);

  Exchange = await ethers.getContractFactory("CXExchange");
  exchange = await Exchange.deploy(owner.address);
  await exchange.deployed();
  console.log("exchange: " + exchange.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

//rinkeby
// token: 0xA191B8605D549E149E2bAB81e01Ea53B5E9657E1
// exchange: 0x970bC92DEdA14C4E6bBeA3C4288Ff4807822731f

//testBSC
// token: 0xA635399Fd3827d21826B22ca9dE42585Ea664bF6
// exchange: 0xf9c0fCFce8EeA9216ed5ca322ccfAfe66CA133e0
