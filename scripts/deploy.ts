import hre, { ethers } from "hardhat";

async function main() {
  // const accounts = await hre.ethers.getSigners();
  const ERC20ZK = await ethers.getContractFactory("ERC20ZK");
  const erc20ZK = await ERC20ZK.deploy();
  await erc20ZK.deployed();

  console.log(
    `erc20ZK contract is deployed to ${hre.network.name} at address ${erc20ZK.address}`
  );
  // erc20ZK contract is deployed to sepolia at address 0x33dB6af053C189e07cC65E5317e7b449fb1BbA7e

  await hre.run("verify:verify", {
    address: erc20ZK.address,
  });
  // https://sepolia.etherscan.io/address/0x33db6af053c189e07cc65e5317e7b449fb1bba7e#code
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
