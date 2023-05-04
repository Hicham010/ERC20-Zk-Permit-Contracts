// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x162fcfcf2412db817e550e0779198ae383721ad30c498e88bb9152f6859ce25d), uint256(0x013eaae0de3af176dd2f058788e74dbadb427c22cf6101dabdfecc8022539c39));
        vk.beta = Pairing.G2Point([uint256(0x0e1c98a99345ec7670aea919fed69a88e71ce6a2c6fa80eddd8ae99768797943), uint256(0x1dd8b53666941b05aab7f99b3da0c54c04420555b7f91b7b34f501fd37963b09)], [uint256(0x2b809c34bf6eec0e82d2200af5c624b4056d1a7df5d8439a3e1c82403a9ca56e), uint256(0x09a1b30ff6781dd274801e23001fa63645b31bcb0b00b61152b60f49ed5228e7)]);
        vk.gamma = Pairing.G2Point([uint256(0x15cddcaaf739f32bba73da4a1020083b8516109055444624a82393d27820bcdd), uint256(0x2d48b32fa8aaad27ff9b414b79917f407693c531fe76635ccdcf296949573c19)], [uint256(0x1ab166453984c5a132c142be30e7e3aa9d2bc116e0b6116f484935e7436b1ca7), uint256(0x14115fc0dc912786ceb57879fb2fc18661861d670dd2d6b01d321f9aa480a9d4)]);
        vk.delta = Pairing.G2Point([uint256(0x23beb9d3dd287b0f975c8db46c182211607d8cdcda1a37d40e419092cd671d2e), uint256(0x157b79d5aa15bd94ccc599f538cf3d4745b029682973f8bc80be493f6bf55d3d)], [uint256(0x0d12469d43f02a30a583742b41012da31b07c577d3500000ec5de1eed14cf3e4), uint256(0x1da1a9c721b4ea5e48333fea3d3f61b485a7078332e2306d55ac942b80297a1d)]);
        vk.gamma_abc = new Pairing.G1Point[](8);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x02944fef90828e9db76ccfbaa6d3fe995871742afe38e1e7dc7be01d040df7ce), uint256(0x1bc2718e4f4393c97a1218a35f9444114b949ac4927942df2fc1a3f5527b512b));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x04c870989f1701b735ba98e38bf0d4cce1935abdeaf6db6d1eabd1e27eb5809e), uint256(0x2c7945e360d65d68e8a1aa8b63be91bba39bb362a9bb83897d67ad1bb819a1d3));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x19939b9baaaad7041ee95e03465f099d5ccc7435d9de3bc0c07d2b2654d50aaf), uint256(0x1f4eb3ca835a1d929c8bcaf2cbca8e170c40c14aceda19b7c1d6daa3c87f7cfd));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x0a8863b3c204feb00e651be07cd6a1c95000c569320961cbcbb073a948f5736b), uint256(0x255f7279229768a82469ba9eca6b82e15e1f3178312246130a8cf201a3405215));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x0a23dd02cbe39fc06b306aea2e373e5bd761fa50ddbc76e15354096c06f768c1), uint256(0x0012616a241dd762b4d5ea43411d667232682d028893fd479f243e6e058f3302));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x1af2e34527a8aa6957dc6793795557e25f81416175c30d3ec2e16ff0f258f20e), uint256(0x2e31acd6f2993e9fcdea2c21551a7e60aa21aeac130da861be57676ea87368e2));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x25c1e5e2a9f802049ddd6bf4f5d99afebeb3e22c015e0688823d8fb52d12ca01), uint256(0x19207117e3b6f0be856a4846fa78c94bf59878bc65969544920edfa6983755e5));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x141d9378d67511e0e3c2e7a276dcef75cebda52935b290c0071a7c527375ea12), uint256(0x05cd94a1032852d5ecd7e145e129110fd7788bcf006c35fa43e9c600d431617a));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[7] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](7);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
