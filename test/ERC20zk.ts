import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { circuitTest, ethers, snarkjs } from "hardhat";
const {
  BigNumber,
  utils: { hexZeroPad },
  constants,
} = ethers;

type GrothProof = [
  a: ERC20ZK.GrothProofStruct["A"],
  b: ERC20ZK.GrothProofStruct["B"],
  c: ERC20ZK.GrothProofStruct["C"]
];

// import permitDefaultInputs from "../circuits/permit.json";
import groth16Vkey from "../circuitsOutput/groth16/groth16_vkey.json";
import plonkVkey from "../circuitsOutput/plonk/plonk_vkey.json";
import { ERC20ZK } from "../typechain-types";

import { buildPoseidon } from "circomlibjs";

const permitWasmPlonk = "./circuitsOutput/plonk/plonk.wasm";
const permitZkeyPlonk = "./circuitsOutput/plonk/plonk.zkey";

const permitWasmGroth16 = "./circuitsOutput/groth16/groth16.wasm";
const permitZkeyGroth16 = "./circuitsOutput/groth16/groth16.zkey";

const MAX_FIELD_SIZE = BigNumber.from(
  "21888242871839275222246405745257275088548364400416034343698204186575808495617"
);

describe("ERC20 Zero-Knowledge Proof", function () {
  async function deployERC20ZKFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, spender, ...otherAccount] = await ethers.getSigners();

    const ZKPermitPlonk = await ethers.getContractFactory("PlonkVerifier");
    const zkPermitPlonk = await ZKPermitPlonk.deploy();

    const ERC20ZK = await ethers.getContractFactory("ERC20ZK");
    const ERC20zk = await ERC20ZK.deploy();

    const circuitPlonk = await circuitTest.setup("permitPlonk");
    const circuitGroth16 = await circuitTest.setup("permitGroth16");

    const poseidon = await buildPoseidon();

    const domainValues = {
      name: hexZeroPad("0x" + Buffer.from("ZK-Coin").toString("hex"), 32),
      version: hexZeroPad("0x" + Buffer.from("1").toString("hex"), 32),
      chainId: (await owner.getChainId()).toString(),
      contractAddress: ERC20zk.address,
    };
    const userValues = {
      password: hexZeroPad("0x" + Buffer.from("password").toString("hex"), 32),
      salt: hexZeroPad("0x" + Buffer.from("salt").toString("hex"), 32),
      ownerAddress: owner.address,
    };

    const transferRequestValues = {
      spenderAddress: spender.address,
      value: "9",
      deadline: MAX_FIELD_SIZE.sub(1).toString(),
      nonce: (await ERC20zk.zkNonce(owner.address)).toString(),
    };

    const domainHash = poseidon.F.toString(
      poseidon([
        domainValues.name,
        domainValues.version,
        domainValues.chainId,
        domainValues.contractAddress,
      ])
    );
    const userHash = poseidon.F.toString(
      poseidon([userValues.password, userValues.salt, userValues.ownerAddress])
    );
    const transferRequestHash = poseidon.F.toString(
      poseidon([
        transferRequestValues.spenderAddress,
        transferRequestValues.value,
        transferRequestValues.deadline,
        transferRequestValues.nonce,
      ])
    );
    const compoundHash = poseidon.F.toString(
      poseidon([domainHash, userHash, transferRequestHash])
    );

    const permitInput = {
      ...domainValues,
      ...userValues,
      ...transferRequestValues,
      userHash: hexZeroPad(BigNumber.from(userHash).toHexString(), 32),
      compoundHash: hexZeroPad(BigNumber.from(compoundHash).toHexString(), 32),
    };

    const permitInnerSignal = {
      domainPosHash: domainHash,
      userPosHash: undefined, // Get's removed in final output (optimization?)
      transferRequestPosHash: transferRequestHash,
      compoundPosHash: undefined, // Get's removed in final output (optimization?)
    };

    return {
      zkPermitPlonk,
      ERC20zk,
      owner,
      spender,
      otherAccount,
      circuitPlonk,
      circuitGroth16,
      permitInput,
      permitInnerSignal,
      poseidon,
    };
  }

  describe("Deployment", function () {
    describe("Checking permit circuit", function () {
      it("Checking the compilation of permit circuit (Plonk)", async function () {
        const { circuitPlonk, permitInput } = await loadFixture(
          deployERC20ZKFixture
        );

        const witnessPlonk = await circuitPlonk.calculateWitness(
          permitInput,
          true
        );
        await circuitPlonk.checkConstraints(witnessPlonk);
      });

      it("Checking the compilation of permit circuit (Groth16)", async function () {
        const { circuitGroth16, permitInput } = await loadFixture(
          deployERC20ZKFixture
        );

        const witnessGroth16 = await circuitGroth16.calculateWitness(
          permitInput,
          true
        );
        await circuitGroth16.checkConstraints(witnessGroth16);
      });

      it("Checking the inputs of permit circuit (Groth16)", async function () {
        const { circuitGroth16, permitInput } = await loadFixture(
          deployERC20ZKFixture
        );

        const witnessGroth16 = await circuitGroth16.calculateLabeledWitness(
          permitInput,
          true
        );
        // console.log(Object.keys(permitInput));
        const Permitkeys = Object.keys(permitInput);
        for (const key of Permitkeys) {
          // console.log(witnessGroth16[`main.${key}`]);

          expect(witnessGroth16[`main.${key}`]).to.eq(
            BigNumber.from(
              permitInput[key as keyof typeof permitInput]
            ).toString()
          );
        }
      });

      it("Checking the inner signal of permit circuit (Groth16)", async function () {
        const { circuitGroth16, permitInput, permitInnerSignal } =
          await loadFixture(deployERC20ZKFixture);
        const witnessGroth16 = await circuitGroth16.calculateLabeledWitness(
          permitInput,
          true
        );

        const PermitInnerkeys = Object.keys(permitInnerSignal);
        for (const key of PermitInnerkeys) {
          // console.log(key, witnessGroth16[`main.${key}`]);

          expect(witnessGroth16[`main.${key}`]).to.eq(
            permitInnerSignal[key as keyof typeof permitInnerSignal]
          );
        }
      });

      it("Checking the inputs of permit circuit (Plonk)", async function () {
        const { circuitPlonk, permitInput } = await loadFixture(
          deployERC20ZKFixture
        );

        const witnessGroth16 = await circuitPlonk.calculateLabeledWitness(
          permitInput,
          true
        );
        // console.log(Object.keys(permitInput));
        const Permitkeys = Object.keys(permitInput);
        for (const key of Permitkeys) {
          // console.log(witnessGroth16[`main.${key}`]);

          expect(witnessGroth16[`main.${key}`]).to.eq(
            BigNumber.from(
              permitInput[key as keyof typeof permitInput]
            ).toString()
          );
        }
      });

      it("Checking the output of permit circuit (Plonk)", async function () {
        const { circuitPlonk, permitInput } = await loadFixture(
          deployERC20ZKFixture
        );

        const witnessGroth16 = await circuitPlonk.calculateWitness(
          permitInput,
          true
        );
        await circuitPlonk.assertOut(witnessGroth16, {});
      });

      it("Checking the output of permit circuit (Groth16)", async function () {
        const { circuitGroth16, permitInput } = await loadFixture(
          deployERC20ZKFixture
        );

        const witnessGroth16 = await circuitGroth16.calculateWitness(
          permitInput,
          true
        );
        await circuitGroth16.assertOut(witnessGroth16, {});
      });
    });

    describe("Checking deployed contract", function () {
      async function ERC20ZKWithGrothProofFixture() {
        const {
          zkPermitPlonk,
          ERC20zk,
          owner,
          spender,
          otherAccount,
          circuitPlonk,
          circuitGroth16,
          permitInput,
          permitInnerSignal,
          poseidon,
        } = await loadFixture(deployERC20ZKFixture);

        const { proof, publicSignals } = await snarkjs.groth16.fullProve(
          permitInput,
          permitWasmGroth16,
          permitZkeyGroth16
        );

        await ERC20zk.connect(owner).setUserHash(permitInput.userHash);

        const proofBytes = (
          await snarkjs.groth16.exportSolidityCallData(proof, "")
        )
          .split(",[]", 1)
          .shift();

        const proofContract: GrothProof = JSON.parse(`[${proofBytes}]`);
        const [A, B, C] = proofContract;
        const contractProof: ERC20ZK.GrothProofStruct = { A, B, C };

        return {
          zkPermitPlonk,
          ERC20zk,
          owner,
          spender,
          otherAccount,
          circuitPlonk,
          circuitGroth16,
          permitInput,
          permitInnerSignal,
          poseidon,
          proof,
          publicSignals,
          proofBytes,
          contractProof,
        };
      }

      it("Should proof a permit input and verify it (Plonk)", async function () {
        const { zkPermitPlonk, permitInput } = await loadFixture(
          deployERC20ZKFixture
        );

        const { proof, publicSignals } = await snarkjs.plonk.fullProve(
          permitInput,
          permitWasmPlonk,
          permitZkeyPlonk
        );

        const proofBytes =
          (await snarkjs.plonk.exportSolidityCallData(proof, ""))
            .split(",", 1)
            .shift() ?? "";

        const res = await snarkjs.plonk.verify(plonkVkey, publicSignals, proof);

        expect(res).to.true;
        expect(
          await zkPermitPlonk.verifyProof(proofBytes, publicSignals as bigint[])
        ).to.true;
      });

      it("Should proof a permit input and verify it (Groth16)", async function () {
        const { ERC20zk, publicSignals, proof, proofBytes } = await loadFixture(
          ERC20ZKWithGrothProofFixture
        );

        const res = await snarkjs.groth16.verify(
          groth16Vkey,
          publicSignals,
          proof
        );

        expect(res).to.true;

        const proofContract: GrothProof = JSON.parse(`[${proofBytes}]`);
        // const proofContract: [
        //   [string, string],
        //   [[string, string], [string, string]],
        //   [string, string]
        // ] = [
        //   [proof.pi_a[0], proof.pi_a[1]],
        //   [
        //     [
        //       // Need to be in reverse order of the proof. Start with 1
        //       proof.pi_b[0][1],
        //       proof.pi_b[0][0],
        //     ],
        //     [
        //       // Need to be in reverse order of the proof. Start with first item in second array
        //       proof.pi_b[1][1],
        //       proof.pi_b[1][0],
        //     ],
        //   ],
        //   [proof.pi_c[0], proof.pi_c[1]],
        // ];

        expect(
          await ERC20zk.verifyProof(...proofContract, publicSignals as bigint[])
        ).to.true;
      });

      it("Should execute zkPermitGroth (Groth16)", async function () {
        const { owner, spender, ERC20zk, permitInput, contractProof } =
          await loadFixture(ERC20ZKWithGrothProofFixture);

        const permitZkStruct: ERC20ZK.PermitZKStruct = {
          owner: owner.address,
          spender: spender.address,
          value: permitInput.value,
          deadline: permitInput.deadline,
          compoundHash: permitInput.compoundHash,
        };

        await expect(ERC20zk.zkPermitGroth(contractProof, permitZkStruct))
          .to.emit(ERC20zk, "Approval")
          .withArgs(
            permitZkStruct.owner,
            permitZkStruct.spender,
            permitZkStruct.value
          );

        expect(await ERC20zk.zkNonce(permitZkStruct.owner)).to.eq(1);
        expect(
          await ERC20zk.allowance(permitZkStruct.owner, permitZkStruct.spender)
        ).to.eq(permitZkStruct.value);
      });

      it("Should revert using same permit twice (Groth16)", async function () {
        const { owner, spender, ERC20zk, permitInput, contractProof } =
          await loadFixture(ERC20ZKWithGrothProofFixture);

        const permitZkStruct: ERC20ZK.PermitZKStruct = {
          owner: owner.address,
          spender: spender.address,
          value: permitInput.value,
          deadline: permitInput.deadline,
          compoundHash: permitInput.compoundHash,
        };

        await ERC20zk.zkPermitGroth(contractProof, permitZkStruct);

        await expect(
          ERC20zk.zkPermitGroth(contractProof, permitZkStruct)
        ).to.be.revertedWith("Proof is invalid");
      });

      it("Should revert permit expired (Groth16)", async function () {
        const { owner, spender, ERC20zk, permitInput, contractProof } =
          await loadFixture(ERC20ZKWithGrothProofFixture);

        const permitZkStruct: ERC20ZK.PermitZKStruct = {
          owner: owner.address,
          spender: spender.address,
          value: permitInput.value,
          deadline: "1000",
          compoundHash: permitInput.compoundHash,
        };

        await expect(
          ERC20zk.zkPermitGroth(contractProof, permitZkStruct)
        ).to.be.revertedWith("Permit expired");
      });

      it("Should revert value changed (Groth16)", async function () {
        const { owner, spender, ERC20zk, permitInput, contractProof } =
          await loadFixture(ERC20ZKWithGrothProofFixture);

        const permitZkStruct: ERC20ZK.PermitZKStruct = {
          owner: owner.address,
          spender: spender.address,
          value: (parseInt(permitInput.value) + 999).toString(),
          deadline: permitInput.deadline,
          compoundHash: permitInput.compoundHash,
        };

        await expect(
          ERC20zk.zkPermitGroth(contractProof, permitZkStruct)
        ).to.be.revertedWith("Proof is invalid");
      });

      it("Should revert value too high (Groth16)", async function () {
        const { owner, spender, ERC20zk, permitInput, contractProof } =
          await loadFixture(ERC20ZKWithGrothProofFixture);

        const permitZkStruct: ERC20ZK.PermitZKStruct = {
          owner: owner.address,
          spender: spender.address,
          value: constants.MaxUint256,
          deadline: permitInput.deadline,
          compoundHash: permitInput.compoundHash,
        };

        await expect(
          ERC20zk.zkPermitGroth(contractProof, permitZkStruct)
        ).to.be.revertedWith("Value too high");
      });

      it("Should revert compound hash too high (Groth16)", async function () {
        const { owner, spender, ERC20zk, permitInput, contractProof } =
          await loadFixture(ERC20ZKWithGrothProofFixture);

        const permitZkStruct: ERC20ZK.PermitZKStruct = {
          owner: owner.address,
          spender: spender.address,
          value: permitInput.value,
          deadline: permitInput.deadline,
          compoundHash: constants.MaxUint256.toHexString(),
        };

        await expect(
          ERC20zk.zkPermitGroth(contractProof, permitZkStruct)
        ).to.be.revertedWith("CompoundHash too high");
      });

      it("Should revert deadline too high (Groth16)", async function () {
        const { owner, spender, ERC20zk, permitInput, contractProof } =
          await loadFixture(ERC20ZKWithGrothProofFixture);

        const permitZkStruct: ERC20ZK.PermitZKStruct = {
          owner: owner.address,
          spender: spender.address,
          value: permitInput.value,
          deadline: constants.MaxUint256,
          compoundHash: permitInput.compoundHash,
        };

        await expect(
          ERC20zk.zkPermitGroth(contractProof, permitZkStruct)
        ).to.be.revertedWith("Deadline too high");
      });
    });
  });
});
