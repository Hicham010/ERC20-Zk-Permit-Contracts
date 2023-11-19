// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Verifier as GrothVerifier} from "./PermitGroth16Verifier.sol";

contract ERC20ZK is ERC20, GrothVerifier {
    uint256 public constant MAX_FIELD_VALUE =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    uint256 public constant nameHex = uint56(bytes7("ZK-Coin"));
    uint256 public constant versionHex = uint8(bytes1("1"));

    struct PermitZK {
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        bytes32 compoundHash;
    }

    struct GrothProof {
        uint256[2] A;
        uint256[2][2] B;
        uint256[2] C;
    }

    mapping(address => bytes32) public userHash;
    mapping(address => uint256) public zkNonce;

    constructor() ERC20("ZK-Coin", "ZK") {
        _mint(msg.sender, 1e6 * 1e18);
    }

    function mint(address receiver, uint256 amount) external {
        _mint(receiver, amount * 1e18);
    }

    function setUserHash(bytes32 _userHash) external {
        require(MAX_FIELD_VALUE > uint256(_userHash), "Userhash not allowed");

        userHash[msg.sender] = _userHash;
    }

    function zkPermitGroth(
        GrothProof memory proof,
        PermitZK memory permitZk
    ) external {
        require(MAX_FIELD_VALUE > permitZk.value, "Value too high");
        require(MAX_FIELD_VALUE > permitZk.deadline, "Deadline too high");
        require(
            MAX_FIELD_VALUE > uint256(permitZk.compoundHash),
            "CompoundHash too high"
        );

        require(block.timestamp < permitZk.deadline, "Permit expired");

        uint256[11] memory signalInputs = formatSignalInputs(permitZk);

        bool isVerifierd = GrothVerifier.verifyProof(
            proof.A,
            proof.B,
            proof.C,
            signalInputs
        );

        require(isVerifierd, "Proof is invalid");

        _approve(permitZk.owner, permitZk.spender, permitZk.value);
    }

    function formatSignalInputs(
        PermitZK memory permitZk
    ) internal returns (uint256[11] memory signalInputs) {
        signalInputs[0] = nameHex;
        signalInputs[1] = versionHex;
        signalInputs[2] = block.chainid;
        signalInputs[3] = uint256(uint160(address(this)));

        signalInputs[4] = uint256(uint160(permitZk.owner));
        signalInputs[5] = uint256(uint160(permitZk.spender));
        signalInputs[6] = permitZk.value;
        signalInputs[7] = permitZk.deadline;
        signalInputs[8] = zkNonce[permitZk.owner]++; //Increment nonce to prevent replay attack

        signalInputs[9] = uint256(userHash[permitZk.owner]);
        signalInputs[10] = uint256(permitZk.compoundHash);
    }
}
