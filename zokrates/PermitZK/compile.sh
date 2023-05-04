#!/bin/bash

zokrates compile -i ./PermitZK.zok -o PermitZK --r1cs PermitZK.r1cs --verbose
zokrates setup -i PermitZK -b ark -s g16

npx snarkjs groth16 setup PermitZK.r1cs ../../powersOfTau28_hez_final_18.ptau PermitZK.zkey
npx snarkjs zkey export verificationkey PermitZK.zkey verification_key.json

zokrates export-verifier -o PermitZkVerifier.sol

