const { expect } = require("chai");
const { ethers } = require("hardhat");

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

describe("CXExchange", async function () {
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

  const sign = async (order, exchangeAddress, signer) => {
    const domain = {
      name: "CXExchange",
      version: "1.0",
      chainId: network.config.chainId,
      verifyingContract: exchangeAddress,
    };

    signature = await signer._signTypedData(domain, types, order);

    return signature;
  };

  beforeEach(async function () {
    [owner, a1, a2] = await ethers.getSigners();
    TokenA = await ethers.getContractFactory("MockERC20");
    tokenA = await TokenA.deploy();
    tokenA.deployed();

    TokenB = await ethers.getContractFactory("MockERC20");
    tokenB = await TokenB.deploy();
    await tokenB.deployed();

    Exchange = await ethers.getContractFactory("CXExchange");
    exchange = await Exchange.deploy(owner.address);
    await exchange.deployed();

    await tokenA.transfer(a1.address, 10000);
    await tokenB.transfer(a2.address, 10000);

    await tokenA.connect(a1).approve(exchange.address, 10000000000);
    await tokenB.connect(a2).approve(exchange.address, 10000000000);
  });

  it("Simple exchange", async function () {
    const order = {
      makerToken: tokenA.address,
      takerToken: tokenB.address,
      sourceChainId: 69,
      destinationChainId: 69,
      makingAmount: 10000,
      takingAmount: 10000,
      expireTime: 999999999999999,
      salt: 1,
    };
    sig1 = await sign(order, exchange.address, a1);
    await exchange.connect(a1).createOrder(order, sig1);
    sig2 = await sign(order, exchange.address, a2);
    await exchange.connect(a2).acceptOrder(order, sig2);
    operatorSig = await sign(order, exchange.address, owner);
    await exchange
      .connect(a2)
      .takerClaimOrder(a1.address, order, sig1, operatorSig);
    await exchange
      .connect(a1)
      .makerClaimOrder(a2.address, order, sig2, operatorSig);
    expect((await tokenA.balanceOf(a2.address)).toNumber()).to.equal(10000);
    expect((await tokenB.balanceOf(a1.address)).toNumber()).to.equal(10000);
  });
  it("Simple exchange w/Native", async function () {
    const order = {
      makerToken: ZERO_ADDRESS,
      takerToken: tokenB.address,
      sourceChainId: 69,
      destinationChainId: 69,
      makingAmount: 10000,
      takingAmount: 10000,
      expireTime: 999999999999999,
      salt: 1,
    };
    sig1 = await sign(order, exchange.address, a1);
    await exchange.connect(a1).createOrder(order, sig1, { value: 10000 });
    sig2 = await sign(order, exchange.address, a2);
    await exchange.connect(a2).acceptOrder(order, sig2);
    operatorSig = await sign(order, exchange.address, owner);
    await exchange
      .connect(a2)
      .takerClaimOrder(a1.address, order, sig1, operatorSig);
    await exchange
      .connect(a1)
      .makerClaimOrder(a2.address, order, sig2, operatorSig);
    // expect((await tokenA.balanceOf(a2.address)).toNumber()).to.equal(10000);
    expect((await tokenB.balanceOf(a1.address)).toNumber()).to.equal(10000);
  });
});
