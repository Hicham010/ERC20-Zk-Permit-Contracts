pragma circom 2.1.3;

include "../node_modules/circomlib/circuits/poseidon.circom";

template ZkPermit() {
  signal input name;
  signal input version;
  signal input chainId;
  signal input contractAddress;

  signal input password;
  signal input salt;
  signal input ownerAddress;
  
  signal input spenderAddress;
  signal input value;
  signal input deadline;
  signal input nonce;

  signal input userHash;
  signal input compoundHash;

  // log("Verifying proof...");

  signal domainPosHash <== Poseidon(4)([name, version, chainId, contractAddress]);
  signal userPosHash <== Poseidon(3)([password, salt, ownerAddress]);
  signal transferRequestPosHash <== Poseidon(4)([spenderAddress, value, deadline, nonce]);

  signal compoundPosHash <== Poseidon(3)([domainPosHash, userPosHash, transferRequestPosHash]);

  userPosHash === userHash;
  compoundPosHash === compoundHash;
}

component main { public 
                    [
                      name,
                      version,
                      chainId,
                      contractAddress,
                      ownerAddress,
                      spenderAddress,
                      value,
                      deadline,
                      nonce,
                      userHash,
                      compoundHash
                    ]
                } = ZkPermit();