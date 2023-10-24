import "@nomicfoundation/hardhat-toolbox";
import "hardhat-circom";
import { HardhatUserConfig } from "hardhat/config";

import * as dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
          // viaIR: true,
        },
      },
    ],
  },
  circom: {
    inputBasePath: "./circuits",
    outputBasePath: "./circuitsOutput",
    ptau: "./powersOfTau28_hez_final_15.ptau",
    circuits: [
      {
        name: "permitPlonk",
        protocol: "plonk",
        circuit: "permit.circom",
        input: "permit.json",
        wasm: "plonk/plonk.wasm",
        zkey: "plonk/plonk.zkey",
        r1cs: "plonk/plonk.r1cs",
        vkey: "plonk/plonk_vkey.json",
      },
      {
        name: "permitGroth16",
        protocol: "groth16",
        circuit: "permitCopy.circom", // same as permit.circom, but needs to be separate file because of bug in hardhat circom
        input: "permit.json",
        wasm: "groth16/groth16.wasm",
        zkey: "groth16/groth16.zkey",
        r1cs: "groth16/groth16.r1cs",
        vkey: "groth16/groth16_vkey.json",
      },
    ],
  },
  networks: {
    sepolia: {
      url: process.env.ALCHEMY_API_URL_SEPOLIA,
      accounts: { mnemonic: process.env.MNEMONIC },
      chainId: 11155111,
    },
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY!,
    },
  },
  gasReporter: {
    enabled: true,
    coinmarketcap: process.env.COIN_MCAP_API_KEY, //API KEY unprotected
    currency: "EUR",
    showTimeSpent: true,
    outputFile: "gas-report.txt",
    noColors: true,
  },
};

export default config;
