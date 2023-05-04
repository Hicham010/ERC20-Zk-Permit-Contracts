// import { initialize } from "zokrates-js";
// import { readFile } from "fs/promises";
// import fs from "fs";
// import { PermitZKArtifact } from "./zokrates/PermitZK/PermitZKArtifact.js";

// async function main() {
//   // await getPermitZKProof();
//   // await getZokratesArtifacts();
// }

// async function getPermitZKProof() {
//   console.log("test");
//   try {
//     const zokratesProvider = await initialize();
//     // const art = await getZokratesArtifacts();
//     const art = PermitZKArtifact;

//     const program = Uint8Array.from(Buffer.from(art.program, "hex"));
//     const input = [
//       "0",
//       "0",
//       "0",
//       "0",
//       "0",
//       "0",
//       "0",
//       "6398910001625085337503814164728823643603809257456974569680215566039089540271",
//       "5317387130258456662214331362918410991734007599705406860481038345552731150762",
//     ];

//     const output = zokratesProvider.computeWitness(program, input);

//     const provingKey = Uint8Array.from(Buffer.from(art.provingKey, "hex"));

//     const zokratesProof = zokratesProvider.generateProof(
//       program,
//       output.witness,
//       provingKey
//     );

//     console.log(`input: ${zokratesProof.inputs}`);
//     console.log(`proof: ${JSON.stringify(zokratesProof.proof)}`);

//     const isVerified = zokratesProvider.verify(
//       art.verificationKey,
//       zokratesProof
//     );
//     console.log(`The proof is verified: ${isVerified}`);
//     return zokratesProof;
//   } catch (err) {
//     console.error("Entered error: ", err);
//   }
// }

// async function getZokratesArtifacts() {
//   const source = (
//     await readFile("zokrates/PermitZK/PermitZK.zok")
//   ).toString();

//   const program = (
//     await readFile("zokrates/PermitZK/PermitZK")
//   ).toString("hex");

//   const verificationKey = JSON.parse(
//     (await readFile("zokrates/PermitZK/verification.key")).toString()
//   );

//   const provingKey = (
//     await readFile("zokrates/PermitZK/proving.key")
//   ).toString("hex");

//   // snarkjs artifacts
//   const zkey = (
//     await readFile("zokrates/PermitZK/PermitZK.zkey")
//   ).toString("hex");

//   const vkey = JSON.parse(
//     (
//       await readFile("zokrates/PermitZK/verification_key.json")
//     ).toString()
//   );
//   const artifacts = {
//     source,
//     program,
//     verificationKey,
//     provingKey,
//     snarkjs: {
//       zkey,
//       vkey,
//     },
//   };

//   fs.writeFileSync(
//     "./zokrates/PermitZK/PermitZKArtifact.json",
//     JSON.stringify(artifacts)
//   );

//   return {
//     artifacts: {
//       source,
//       program,
//       verificationKey,
//       provingKey,
//       snarkjs: {
//         zkey,
//         vkey,
//       },
//     },
//   };
// }

// main().catch((error) => {
//   console.error(error);
//   process.exitCode = 1;
// });
