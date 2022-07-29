const hre = require("hardhat");
const ethers = require("ethers");

async function main() {
  const signer = new ethers.Wallet(
    "ae2543bfcb4fa37a2988acbbf5e0716c93146470b86ba0c57768c412dd9058bf"
  );

  console.log(signer.address);

  const BASE_MESSAGE = 1;

  const message = ethers.utils.hashMessage(BASE_MESSAGE);
  console.log(message);
  //   const message = ethers.utils.arrayify("hello");
  const sig = await signer.signMessage(BASE_MESSAGE);
  console.log(sig);

  console.log(ethers.utils.recoverAddress(message, sig));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
