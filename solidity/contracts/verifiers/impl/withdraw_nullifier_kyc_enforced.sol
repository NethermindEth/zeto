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

    
    uint256 constant IC0x = 8031595523312774434646274307988004694866098098778304616552089882123819432316;
    uint256 constant IC0y = 9342541504757238021036176277034884404797226399954585906538991415675223861797;
    
    uint256 constant IC1x = 14419043076107983987414039785930036546468491843644940471719184801440283870900;
    uint256 constant IC1y = 6215511353802437538208221162037052172152158067715200866047360707674624666084;
    
    uint256 constant IC2x = 11824541340637545184811051032868787920359465217566405797173095689478587255759;
    uint256 constant IC2y = 4092068544566654541132256718960397879587609938937705050692654651994045995215;
    
    uint256 constant IC3x = 5041327037969611068571168448993184450468879898541668323320817836835979542711;
    uint256 constant IC3y = 13149715594302011887492770853453615727913782101364402095140723238640188136917;
    
    uint256 constant IC4x = 21439300805200506620531501990860799113158944956705690750034270488560865216605;
    uint256 constant IC4y = 2625125713073818519816562013231138384682655905863936947146796200501359301990;
    
    uint256 constant IC5x = 11700902112267872857834881930595253747450089921189448637818759284693459915668;
    uint256 constant IC5y = 7961049354025712119990198049946490533080256996779858187191827803301817123602;
    
    uint256 constant IC6x = 17096283971554849922114002964999425215769147820448158142559590970140636906274;
    uint256 constant IC6y = 16127060952095327326426957749724245828028823413353405648346753495371491588036;
    
    uint256 constant IC7x = 14334519714921066149096192787567033204133425789047643636030860487994926486822;
    uint256 constant IC7y = 3928260135159403554465173030707632677605879390894825918873309919423174967775;
    
    uint256 constant IC8x = 7617084075033759635194221033350455065199358525861327284355705629952392117502;
    uint256 constant IC8y = 8466910954180306653853268620332429053378883510038358250621135924154522485337;
    
    uint256 constant IC9x = 10220190628508104068652829969468206209974662945487358745621461696717921576556;
    uint256 constant IC9y = 1772166149898439193133310251903814140289517075663057822475247057238896402496;
    
    uint256 constant IC10x = 20637836392483022356477979208697326751825717557095066906022673939321558260478;
    uint256 constant IC10y = 15085651541249793074575213251166965919878125112321519500758273043449407547514;
    
    uint256 constant IC11x = 6653410914300307010580068022640338291339823676460367478704290961637675827873;
    uint256 constant IC11y = 4239419048033395055570325525583449904521568817273288645119707946572098075295;
    
    uint256 constant IC12x = 10642506980226529121376025490147211449482946402231946725746619733026424669877;
    uint256 constant IC12y = 17504654945341408464133164618380651990124324454483351889646973172992426044156;
    
    uint256 constant IC13x = 4459052987287731427234063408252128262688319626752484085568560759420747956804;
    uint256 constant IC13y = 846250340402247003910554630538552707653188430616657582669172075698822928472;
    
    uint256 constant IC14x = 581573158828769046691917499786623001135497053345775681486704225043393699379;
    uint256 constant IC14y = 7980893617688630281608658947401103026491288397516810694886463035455449325868;
    
    uint256 constant IC15x = 18124016465993265105900337536701595942644900023393731768324962584087667600378;
    uint256 constant IC15y = 13427758123446480428241694005860800565342657904918908085926203086941164820702;
    
    uint256 constant IC16x = 20865327457691596692116824521109329989794238935036304392690864207521876161786;
    uint256 constant IC16y = 6966118799010688782186078463689885361739357922543832344812955888551241357895;
    
    uint256 constant IC17x = 20380786190468007749250502889599127936619722723558136325814170441541149623239;
    uint256 constant IC17y = 18842872272192132223245965210290698350829276947535799112980767298299679534687;
    
    uint256 constant IC18x = 9312365202328467656673964344673438748808249795397696444722481570260661574909;
    uint256 constant IC18y = 7119088897873106542600945898796623534204071272879962966496557692297672986982;
    
    uint256 constant IC19x = 19091405866027768164206848188836022702551107809062189692168322024634102542804;
    uint256 constant IC19y = 4218672207869941776220512222704220171376567537272135569477667221571812354375;
    
    uint256 constant IC20x = 13392301149141919718255693551573768136810485620382836751730272482381739480459;
    uint256 constant IC20y = 18574277098235238583216361603526166129628184951157813979597230364147641181977;
    
    uint256 constant IC21x = 19035932810075052812019145210813798017729178954394723916255690530836104070729;
    uint256 constant IC21y = 778648493459879229513532537451319757983980679249437445112547637512353771097;
    
    uint256 constant IC22x = 21660532554782279472903747300636036448113697415577235254315502533381951569402;
    uint256 constant IC22y = 10079779774220021483723489579933939945585367889370228142506799277122840310399;
    
    uint256 constant IC23x = 6712277948844036967959037095976764471686153153015792289924440177872976139215;
    uint256 constant IC23y = 16655492003789474193352381793426190805617153920921029331257553732987522780824;
    
    uint256 constant IC24x = 2432796851787129418102972389427810351411082335951971171897199196215890388682;
    uint256 constant IC24y = 1749496292402405874560007679967145109602484959111586154976041942768860088188;
    
    uint256 constant IC25x = 13045267395190325578615125085105509264700801367259754031766026231624972513574;
    uint256 constant IC25y = 10171323507148611776674303590016647132414144362289876714275309067378761307850;
    
    uint256 constant IC26x = 1743350841439900515603696407707085768488401587888188340718055884801566995153;
    uint256 constant IC26y = 5792428831349428681299795390519252227909120476786153773357175581660453223504;
    
    uint256 constant IC27x = 20657993179352345664371043093360908701764279294800417373699079481317090335305;
    uint256 constant IC27y = 10867211693437029453846252371594773516495964229696089641180035133400969102933;
    
    uint256 constant IC28x = 19906195983165963807574220790953914208236450920580830113314271594772014181707;
    uint256 constant IC28y = 2949505746846096651780145561467153238191187103436639416151225333074235615630;
    
    uint256 constant IC29x = 8753648942457664388314284477857114684345711340616183424838967670797398461207;
    uint256 constant IC29y = 14226644728042511322309763317730799932357029139048119673694987527949994079881;
    
    uint256 constant IC30x = 12302066836203688934412617197045525143587194427230796228702875325203427101934;
    uint256 constant IC30y = 17761085580421349131924060916285466919890357080087916620157798033029767691334;
    
    uint256 constant IC31x = 21133432655798543673671283738839416578326371693701131187793919949924186893913;
    uint256 constant IC31y = 14744716188573813586111440725055652942323500282149355980657220226606952551557;
    
    uint256 constant IC32x = 1762567385647939486138180461700356750778444052213999670128847417363382769123;
    uint256 constant IC32y = 20093280597993704798046441586756196005390227363478120811099594370700353878903;
    
    uint256 constant IC33x = 12595375983666247859067866538085723909442416046709179413829359847007458420328;
    uint256 constant IC33y = 13054155499878659733569929513643660123159187440407799417017466166555410942373;
    
    uint256 constant IC34x = 3611966243235789308691161913551073407537219828901036342145343740537912168985;
    uint256 constant IC34y = 21007748674580772117626073272302398342794786733500816451819093566747498212794;
    
    uint256 constant IC35x = 14155961406589495634465473720448093420467361741679353554661398254932885051605;
    uint256 constant IC35y = 14144761592990800027010183445853365873568255528649929218143380451336212667515;
    
    uint256 constant IC36x = 11523827453080589155149240001817115654457965280859843006100314405531071217828;
    uint256 constant IC36y = 13171766302875102124097085882645849127011733245203775376153681549921887067441;
    
    uint256 constant IC37x = 16555163072979040235346591239305861586872926131604279680004280592858931387363;
    uint256 constant IC37y = 10193345296471812716998064552692363738516930133015963200167436034262522645765;
    
    uint256 constant IC38x = 1701678312074464799703766577756621016668176547441431353618621155621360658598;
    uint256 constant IC38y = 15709815122202534653182516391862644316179903266988253308968382500362816569836;
    
    uint256 constant IC39x = 13125254878699170098773156838628574219755728435161722989864868483604198190541;
    uint256 constant IC39y = 18850701121080065803270763969494224324709006278681133607360512481805586449038;
    
    uint256 constant IC40x = 7071221522368555406328565236352127852824919985864555403936251690068765065522;
    uint256 constant IC40y = 20453132640983524508670908261045588605833218281458821642633542395844347631795;
    
    uint256 constant IC41x = 12268969458968022967855631847799453870741296431476827570537394408380107273872;
    uint256 constant IC41y = 12310462680319549407328720168620388379619199211156158598806304846820766903438;
    
    uint256 constant IC42x = 8181214281441840891768155382744797471127929282068958680707593270147843590731;
    uint256 constant IC42y = 14612701245212876363359671980422649721794341352797652332329317192889649197507;
    
    uint256 constant IC43x = 6810511030444715250822577522361774755192624076565695552247744570435653639688;
    uint256 constant IC43y = 958017361879777660953932511522170253347448992024860488061212696829019582315;
    
    uint256 constant IC44x = 5130865999033048405728424817248089339389076388108011877005091517114981196535;
    uint256 constant IC44y = 10679271580509576090657111104631585827303352770207095967459782488631260678636;
    
    uint256 constant IC45x = 16744828830150276234180332929333163479565867079409704343508444053363614418208;
    uint256 constant IC45y = 11201844692955149881477575234293176812999102569670844470357505975952980319655;
    
    uint256 constant IC46x = 11751889686951138153616258176876757903332705382069015048608562420779402789741;
    uint256 constant IC46y = 18130120511901313383617282893704429863943080003517984532257705414418649244646;
    
    uint256 constant IC47x = 2196592466054584958735329805019554008440361153568988704851202939309865966583;
    uint256 constant IC47y = 21678567295855640448693763974650621796722628995383302897906421999854589111211;
    
    uint256 constant IC48x = 18837984258364058909538068750366242721818464148482816762099242239901806452726;
    uint256 constant IC48y = 11609462049318552450347563013181633144697949217289429223231484033891847037056;
    
    uint256 constant IC49x = 3488440502820794979593980665859437322806101332732528903745399770645458097664;
    uint256 constant IC49y = 15522684540541477131039792960157908010441637744574920536769717199833425555611;
    
    uint256 constant IC50x = 14279101090539935417414394827915805577088381993489676431927997955110441627369;
    uint256 constant IC50y = 20757372113645320406397382470496681584810227482917416787274097968435181751935;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[50] calldata _pubSignals) public view returns (bool) {
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
                
                g1_mulAccC(_pVk, IC21x, IC21y, calldataload(add(pubSignals, 640)))
                
                g1_mulAccC(_pVk, IC22x, IC22y, calldataload(add(pubSignals, 672)))
                
                g1_mulAccC(_pVk, IC23x, IC23y, calldataload(add(pubSignals, 704)))
                
                g1_mulAccC(_pVk, IC24x, IC24y, calldataload(add(pubSignals, 736)))
                
                g1_mulAccC(_pVk, IC25x, IC25y, calldataload(add(pubSignals, 768)))
                
                g1_mulAccC(_pVk, IC26x, IC26y, calldataload(add(pubSignals, 800)))
                
                g1_mulAccC(_pVk, IC27x, IC27y, calldataload(add(pubSignals, 832)))
                
                g1_mulAccC(_pVk, IC28x, IC28y, calldataload(add(pubSignals, 864)))
                
                g1_mulAccC(_pVk, IC29x, IC29y, calldataload(add(pubSignals, 896)))
                
                g1_mulAccC(_pVk, IC30x, IC30y, calldataload(add(pubSignals, 928)))
                
                g1_mulAccC(_pVk, IC31x, IC31y, calldataload(add(pubSignals, 960)))
                
                g1_mulAccC(_pVk, IC32x, IC32y, calldataload(add(pubSignals, 992)))
                
                g1_mulAccC(_pVk, IC33x, IC33y, calldataload(add(pubSignals, 1024)))
                
                g1_mulAccC(_pVk, IC34x, IC34y, calldataload(add(pubSignals, 1056)))
                
                g1_mulAccC(_pVk, IC35x, IC35y, calldataload(add(pubSignals, 1088)))
                
                g1_mulAccC(_pVk, IC36x, IC36y, calldataload(add(pubSignals, 1120)))
                
                g1_mulAccC(_pVk, IC37x, IC37y, calldataload(add(pubSignals, 1152)))
                
                g1_mulAccC(_pVk, IC38x, IC38y, calldataload(add(pubSignals, 1184)))
                
                g1_mulAccC(_pVk, IC39x, IC39y, calldataload(add(pubSignals, 1216)))
                
                g1_mulAccC(_pVk, IC40x, IC40y, calldataload(add(pubSignals, 1248)))
                
                g1_mulAccC(_pVk, IC41x, IC41y, calldataload(add(pubSignals, 1280)))
                
                g1_mulAccC(_pVk, IC42x, IC42y, calldataload(add(pubSignals, 1312)))
                
                g1_mulAccC(_pVk, IC43x, IC43y, calldataload(add(pubSignals, 1344)))
                
                g1_mulAccC(_pVk, IC44x, IC44y, calldataload(add(pubSignals, 1376)))
                
                g1_mulAccC(_pVk, IC45x, IC45y, calldataload(add(pubSignals, 1408)))
                
                g1_mulAccC(_pVk, IC46x, IC46y, calldataload(add(pubSignals, 1440)))
                
                g1_mulAccC(_pVk, IC47x, IC47y, calldataload(add(pubSignals, 1472)))
                
                g1_mulAccC(_pVk, IC48x, IC48y, calldataload(add(pubSignals, 1504)))
                
                g1_mulAccC(_pVk, IC49x, IC49y, calldataload(add(pubSignals, 1536)))
                
                g1_mulAccC(_pVk, IC50x, IC50y, calldataload(add(pubSignals, 1568)))
                

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
            
            checkField(calldataload(add(_pubSignals, 640)))
            
            checkField(calldataload(add(_pubSignals, 672)))
            
            checkField(calldataload(add(_pubSignals, 704)))
            
            checkField(calldataload(add(_pubSignals, 736)))
            
            checkField(calldataload(add(_pubSignals, 768)))
            
            checkField(calldataload(add(_pubSignals, 800)))
            
            checkField(calldataload(add(_pubSignals, 832)))
            
            checkField(calldataload(add(_pubSignals, 864)))
            
            checkField(calldataload(add(_pubSignals, 896)))
            
            checkField(calldataload(add(_pubSignals, 928)))
            
            checkField(calldataload(add(_pubSignals, 960)))
            
            checkField(calldataload(add(_pubSignals, 992)))
            
            checkField(calldataload(add(_pubSignals, 1024)))
            
            checkField(calldataload(add(_pubSignals, 1056)))
            
            checkField(calldataload(add(_pubSignals, 1088)))
            
            checkField(calldataload(add(_pubSignals, 1120)))
            
            checkField(calldataload(add(_pubSignals, 1152)))
            
            checkField(calldataload(add(_pubSignals, 1184)))
            
            checkField(calldataload(add(_pubSignals, 1216)))
            
            checkField(calldataload(add(_pubSignals, 1248)))
            
            checkField(calldataload(add(_pubSignals, 1280)))
            
            checkField(calldataload(add(_pubSignals, 1312)))
            
            checkField(calldataload(add(_pubSignals, 1344)))
            
            checkField(calldataload(add(_pubSignals, 1376)))
            
            checkField(calldataload(add(_pubSignals, 1408)))
            
            checkField(calldataload(add(_pubSignals, 1440)))
            
            checkField(calldataload(add(_pubSignals, 1472)))
            
            checkField(calldataload(add(_pubSignals, 1504)))
            
            checkField(calldataload(add(_pubSignals, 1536)))
            
            checkField(calldataload(add(_pubSignals, 1568)))
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
