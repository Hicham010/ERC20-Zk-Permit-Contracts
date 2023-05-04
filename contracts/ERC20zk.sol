// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Verifier as GrothVerifier} from "./PermitGroth16Verifier.sol";

// import "hardhat/console.sol";

contract ERC20ZK is ERC20, GrothVerifier {
    uint public constant MAX_FIELD_VALUE =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    string public constant version = "1";
    uint public constant nameHex = 0x5a4b2d436f696e; // "ZK-Coin"
    uint public constant versionHex = 0x31; //  "1"

    struct PermitZK {
        address owner;
        address spender;
        uint value;
        uint deadline;
        bytes32 compoundHash;
    }

    struct GrothProof {
        uint[2] A;
        uint[2][2] B;
        uint[2] C;
    }

    mapping(address => bytes32) public userHash;
    mapping(address => uint) public zkNonce;

    constructor() ERC20("ZK-Coin", "ZK") {
        _mint(msg.sender, 1_000_00 * 1e18);
    }

    function mint(address receiver, uint amount) external {
        _mint(receiver, amount * 1e18);
    }

    function setUserHash(bytes32 _userHash) external {
        require(MAX_FIELD_VALUE > uint(_userHash), "Userhash not allowed");

        userHash[msg.sender] = _userHash;
    }

    function zkPermitGroth(
        GrothProof memory proof,
        PermitZK memory permitZk
    ) external {
        uint[11] memory signalInputs = formaytSignalInputs(permitZk);

        bool isVerifierd = GrothVerifier.verifyProof(
            proof.A,
            proof.B,
            proof.C,
            signalInputs
        );

        require(isVerifierd, "Proof is invalid");

        _approve(permitZk.owner, permitZk.spender, permitZk.value);
    }

    function formaytSignalInputs(
        PermitZK memory permitZk
    ) internal returns (uint[11] memory) {
        uint[11] memory signalInputs;

        uint nameSignal = nameHex;
        uint versionSignal = versionHex;

        uint chainIdSignal = block.chainid;
        uint contractAddressSignal = uint(uint160(address(this)));

        signalInputs[0] = nameSignal;
        signalInputs[1] = versionSignal;
        signalInputs[2] = chainIdSignal;
        signalInputs[3] = contractAddressSignal;

        uint ownerAddressSignal = uint(uint160(permitZk.owner));
        uint spenderAddressSignal = uint(uint160(permitZk.spender));
        uint valueSignal = permitZk.value;
        uint deadlineSignal = permitZk.deadline;
        uint nonceSignal = zkNonce[permitZk.owner]++; //Increment nonce to prevent replay attack

        signalInputs[4] = ownerAddressSignal;
        signalInputs[5] = spenderAddressSignal;
        signalInputs[6] = valueSignal;
        signalInputs[7] = deadlineSignal;
        signalInputs[8] = nonceSignal;

        uint userHashSignal = abi.decode(
            abi.encode(userHash[permitZk.owner]),
            (uint)
        );
        uint compoundHashSignal = abi.decode(
            abi.encode(permitZk.compoundHash),
            (uint)
        );

        signalInputs[9] = userHashSignal;
        signalInputs[10] = compoundHashSignal;

        // console.log("nameSignal: ", signalInputs[0]);
        // console.log("chainIdSignal: ", signalInputs[1]);
        // console.log("versionSignal: ", signalInputs[2]);
        // console.log("contractAddressSignal: ", signalInputs[3]);
        // console.log("ownerAddressSignal: ", signalInputs[4]);
        // console.log("spenderAddressSignal: ", signalInputs[5]);
        // console.log("valueSignal: ", signalInputs[6]);
        // console.log("deadlineSignal: ", signalInputs[7]);
        // console.log("nonceSignal: ", signalInputs[8]);
        // console.log("userHashSignal: ", signalInputs[9]); /
        // console.log("compoundHashSignal: ", signalInputs[10]);

        return signalInputs;
    }
}
