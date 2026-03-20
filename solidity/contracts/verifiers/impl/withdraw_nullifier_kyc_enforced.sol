// SPDX-License-Identifier: GPL-3.0
/*
    Copyright 2021 0KIMS association.

    This file is generated with [snarkJS](https://github.com/iden3/snarkjs).

    snarkJS is a free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    snarkJS is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with snarkJS. If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.7.0 <0.9.0;

contract Verifier_WithdrawNullifierKycEnforced {
    // Scalar field size
    uint256 constant r    = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax  = 20491192805390485299153009773594534940189261866228447918068658471970481763042;
    uint256 constant alphay  = 9383485363053290200918347156157836566562967994039712273449902621266178545958;
    uint256 constant betax1  = 4252822878758300859123897981450591353533073413197771768651442665752259397132;
    uint256 constant betax2  = 6375614351688725206403948262868962793625744043794305715222011528459656738731;
    uint256 constant betay1  = 21847035105528745403288232691147584728191162732299865338377159692350059136679;
    uint256 constant betay2  = 10505242626370262277552901082094356697409835680220590971873171140371331206856;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant deltax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant deltay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant deltay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;

    
    uint256 constant IC0x = 18810640774739932378833080382064904506834556335287077317171803084249991094040;
    uint256 constant IC0y = 9566557713043736588023006477593577430496802517444621138798303686362060756990;
    
    uint256 constant IC1x = 7654249461743992769833338237832598069748924783514417111475608292795311662792;
    uint256 constant IC1y = 6817779554600870395770270021440443207045040891783522712378914569707896917889;
    
    uint256 constant IC2x = 20090798274670679729973429868313066018150694930627100449514899662897006042531;
    uint256 constant IC2y = 1328108290165325208199882025684621437606505606748866655599972010393379966297;
    
    uint256 constant IC3x = 12456412544203206546798508537749419060852505158778761937789694987059838945077;
    uint256 constant IC3y = 17464152288823573673358037520535728864420306305752817311572254153657995984502;
    
    uint256 constant IC4x = 16404892014356327323296329128364980811057677836404275286870757441804388369397;
    uint256 constant IC4y = 9152153411628361212065749045803531513954136778767533719856454725568980261475;
    
    uint256 constant IC5x = 6896820232628001307527339272428466756198382749184900608922886496803713364398;
    uint256 constant IC5y = 7123901512991644493498025472086928332367685891044178783523683098075468033059;
    
    uint256 constant IC6x = 2822104704346238846215305242675974112195730655878777722534154297499566520424;
    uint256 constant IC6y = 13023378934647881808466439986013012476769030068546777444870576952216598607618;
    
    uint256 constant IC7x = 19986012937567136140516856654651028287036210671469474149751175307037324634089;
    uint256 constant IC7y = 15396274301708050781697717989744122320400443880125788933360616145678052545717;
    
    uint256 constant IC8x = 15832329708150786702883492242920269199920495626297818106794602471610448313037;
    uint256 constant IC8y = 11745245664939413602994411091974803761208012500494187328744979801140213929712;
    
    uint256 constant IC9x = 2323228432459226651581195483933048530910184559582865957924638382607692720716;
    uint256 constant IC9y = 8006736535434728680384778471438544692202888416970078789297530341869381109760;
    
    uint256 constant IC10x = 8933395073175171552892097101877415155080577881868604920951794885255375290063;
    uint256 constant IC10y = 21805293209465366687493281810404779076650942577094557773526319101884638473753;
    
    uint256 constant IC11x = 5866842689027276908164006080072553503214358672509556295474801355940868645781;
    uint256 constant IC11y = 19188006435988293489507575809262232313530592550090875286215759966618248327184;
    
    uint256 constant IC12x = 2433490184419545626340894869366948221043200322683100777504984959446952438195;
    uint256 constant IC12y = 20535235239584647240668652862708257070405308042110430376947607007234860430787;
    
    uint256 constant IC13x = 18465528845575432961884671648020841805094656823609847555265778860979837441572;
    uint256 constant IC13y = 17338100630192322743792774358763811953500292211194277067127795830002227491298;
    
    uint256 constant IC14x = 9242934273763543115982187514897301683404301027060738972556224225083919998661;
    uint256 constant IC14y = 8995063198634019536212081431735273453802117449292619937005192356744532514548;
    
    uint256 constant IC15x = 6908994098264694679126093431456897942177494419289668447388474517437762468067;
    uint256 constant IC15y = 8223724116835442085465943820571332445516150012787696543553947433042909324509;
    
    uint256 constant IC16x = 6085627674932978247116843786048720502683847013632517428819255449998556212469;
    uint256 constant IC16y = 738426628688316852006001669431077654069488478940935725955097972518178578980;
    
    uint256 constant IC17x = 9687656383092045116545511852987994244861067450516101471010884580602354145178;
    uint256 constant IC17y = 20308513661234222727204746159605554164986917811565970716742246714421242316931;
    
    uint256 constant IC18x = 5595758689870931380244091477921302400150062081302443325271582740852020645196;
    uint256 constant IC18y = 18284039299169065269424752828637897726133909397992281843773995195949423161422;
    
    uint256 constant IC19x = 4418864416689755019057482780808886194537737447731055918980599651015888366166;
    uint256 constant IC19y = 9877174096240277431726965424843692853938814873533121338311189682677397320279;
    
    uint256 constant IC20x = 10360204085084083643521055773530629195834820034853940793365951983114106486437;
    uint256 constant IC20y = 6867396794871835765967718386659406141389643268924547715959889410368589246136;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[20] calldata _pubSignals) public view returns (bool) {
        assembly {
            function checkField(v) {
                if iszero(lt(v, r)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }
            
            // G1 function to multiply a G1 value(x,y) to value in an address
            function g1_mulAccC(pR, x, y, s) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, x)
                mstore(add(mIn, 32), y)
                mstore(add(mIn, 64), s)

                success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }

                mstore(add(mIn, 64), mload(pR))
                mstore(add(mIn, 96), mload(add(pR, 32)))

                success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkPairing(pA, pB, pC, pubSignals, pMem) -> isOk {
                let _pPairing := add(pMem, pPairing)
                let _pVk := add(pMem, pVk)

                mstore(_pVk, IC0x)
                mstore(add(_pVk, 32), IC0y)

                // Compute the linear combination vk_x
                
                g1_mulAccC(_pVk, IC1x, IC1y, calldataload(add(pubSignals, 0)))
                
                g1_mulAccC(_pVk, IC2x, IC2y, calldataload(add(pubSignals, 32)))
                
                g1_mulAccC(_pVk, IC3x, IC3y, calldataload(add(pubSignals, 64)))
                
                g1_mulAccC(_pVk, IC4x, IC4y, calldataload(add(pubSignals, 96)))
                
                g1_mulAccC(_pVk, IC5x, IC5y, calldataload(add(pubSignals, 128)))
                
                g1_mulAccC(_pVk, IC6x, IC6y, calldataload(add(pubSignals, 160)))
                
                g1_mulAccC(_pVk, IC7x, IC7y, calldataload(add(pubSignals, 192)))
                
                g1_mulAccC(_pVk, IC8x, IC8y, calldataload(add(pubSignals, 224)))
                
                g1_mulAccC(_pVk, IC9x, IC9y, calldataload(add(pubSignals, 256)))
                
                g1_mulAccC(_pVk, IC10x, IC10y, calldataload(add(pubSignals, 288)))
                
                g1_mulAccC(_pVk, IC11x, IC11y, calldataload(add(pubSignals, 320)))
                
                g1_mulAccC(_pVk, IC12x, IC12y, calldataload(add(pubSignals, 352)))
                
                g1_mulAccC(_pVk, IC13x, IC13y, calldataload(add(pubSignals, 384)))
                
                g1_mulAccC(_pVk, IC14x, IC14y, calldataload(add(pubSignals, 416)))
                
                g1_mulAccC(_pVk, IC15x, IC15y, calldataload(add(pubSignals, 448)))
                
                g1_mulAccC(_pVk, IC16x, IC16y, calldataload(add(pubSignals, 480)))
                
                g1_mulAccC(_pVk, IC17x, IC17y, calldataload(add(pubSignals, 512)))
                
                g1_mulAccC(_pVk, IC18x, IC18y, calldataload(add(pubSignals, 544)))
                
                g1_mulAccC(_pVk, IC19x, IC19y, calldataload(add(pubSignals, 576)))
                
                g1_mulAccC(_pVk, IC20x, IC20y, calldataload(add(pubSignals, 608)))
                

                // -A
                mstore(_pPairing, calldataload(pA))
                mstore(add(_pPairing, 32), mod(sub(q, calldataload(add(pA, 32))), q))

                // B
                mstore(add(_pPairing, 64), calldataload(pB))
                mstore(add(_pPairing, 96), calldataload(add(pB, 32)))
                mstore(add(_pPairing, 128), calldataload(add(pB, 64)))
                mstore(add(_pPairing, 160), calldataload(add(pB, 96)))

                // alpha1
                mstore(add(_pPairing, 192), alphax)
                mstore(add(_pPairing, 224), alphay)

                // beta2
                mstore(add(_pPairing, 256), betax1)
                mstore(add(_pPairing, 288), betax2)
                mstore(add(_pPairing, 320), betay1)
                mstore(add(_pPairing, 352), betay2)

                // vk_x
                mstore(add(_pPairing, 384), mload(add(pMem, pVk)))
                mstore(add(_pPairing, 416), mload(add(pMem, add(pVk, 32))))


                // gamma2
                mstore(add(_pPairing, 448), gammax1)
                mstore(add(_pPairing, 480), gammax2)
                mstore(add(_pPairing, 512), gammay1)
                mstore(add(_pPairing, 544), gammay2)

                // C
                mstore(add(_pPairing, 576), calldataload(pC))
                mstore(add(_pPairing, 608), calldataload(add(pC, 32)))

                // delta2
                mstore(add(_pPairing, 640), deltax1)
                mstore(add(_pPairing, 672), deltax2)
                mstore(add(_pPairing, 704), deltay1)
                mstore(add(_pPairing, 736), deltay2)


                let success := staticcall(sub(gas(), 2000), 8, _pPairing, 768, _pPairing, 0x20)

                isOk := and(success, mload(_pPairing))
            }

            let pMem := mload(0x40)
            mstore(0x40, add(pMem, pLastMem))

            // Validate that all evaluations ∈ F
            
            checkField(calldataload(add(_pubSignals, 0)))
            
            checkField(calldataload(add(_pubSignals, 32)))
            
            checkField(calldataload(add(_pubSignals, 64)))
            
            checkField(calldataload(add(_pubSignals, 96)))
            
            checkField(calldataload(add(_pubSignals, 128)))
            
            checkField(calldataload(add(_pubSignals, 160)))
            
            checkField(calldataload(add(_pubSignals, 192)))
            
            checkField(calldataload(add(_pubSignals, 224)))
            
            checkField(calldataload(add(_pubSignals, 256)))
            
            checkField(calldataload(add(_pubSignals, 288)))
            
            checkField(calldataload(add(_pubSignals, 320)))
            
            checkField(calldataload(add(_pubSignals, 352)))
            
            checkField(calldataload(add(_pubSignals, 384)))
            
            checkField(calldataload(add(_pubSignals, 416)))
            
            checkField(calldataload(add(_pubSignals, 448)))
            
            checkField(calldataload(add(_pubSignals, 480)))
            
            checkField(calldataload(add(_pubSignals, 512)))
            
            checkField(calldataload(add(_pubSignals, 544)))
            
            checkField(calldataload(add(_pubSignals, 576)))
            
            checkField(calldataload(add(_pubSignals, 608)))
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
