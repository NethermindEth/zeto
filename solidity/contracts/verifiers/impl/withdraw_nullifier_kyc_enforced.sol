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

    
    uint256 constant IC0x = 20533604517479841815324374075535911472492918585760527462671466173427154538227;
    uint256 constant IC0y = 6670263208233899913959741806055837478996925967408674437361548678970716600647;
    
    uint256 constant IC1x = 15085476072413486237890818080570759539076588834284333263714262621688950357758;
    uint256 constant IC1y = 5695581322339540923909887475334004295470932115763309478236946573363244075736;
    
    uint256 constant IC2x = 10872347024628865650480521395448059794014986664767385788560751986174780842285;
    uint256 constant IC2y = 3257844397309138481488494391400653094334525139943946433226988739412440699138;
    
    uint256 constant IC3x = 12346318881074947991496743062066962957923604886815377446345269253684473935447;
    uint256 constant IC3y = 8205171045932621251163569915197933237851348159522056689432155041654524436004;
    
    uint256 constant IC4x = 5159990414608453585056941699828033537778999930338610526826232025388448331844;
    uint256 constant IC4y = 6663927016864702670627513430211310254178584403870634065985018467549797898144;
    
    uint256 constant IC5x = 14995473079350596649175658783165567723136785321161421477717458425724901832899;
    uint256 constant IC5y = 14404685064772515122793789265158429650908291021274148970556587751944971619403;
    
    uint256 constant IC6x = 20155316249666570835033011519331938806504177828770886044461253875706372134020;
    uint256 constant IC6y = 10571596786064431279323937550890703622515798420932674448006432793453754825739;
    
    uint256 constant IC7x = 16153192034220170795695951446193658445020969429231248647565186542952515538064;
    uint256 constant IC7y = 5575987731020811263278622400028231238418156093084709362536697955753894936625;
    
    uint256 constant IC8x = 13850762108463240640628185044754291447506305980646270789949429214871920009192;
    uint256 constant IC8y = 3958472861698154518542813246247956319126771295493126911798300030871918558758;
    
    uint256 constant IC9x = 16091074941087445149057387421686728260844522629493311399181273474620607437944;
    uint256 constant IC9y = 1676963103826446736723210884605081990317202318397420987749259097481758557251;
    
    uint256 constant IC10x = 901803504447055580493358358184779048504829024684589398002572399949138379033;
    uint256 constant IC10y = 20802539166565966938708033151511415689121492005692170855550972905770526412990;
    
    uint256 constant IC11x = 2337780239765786206975335108355250876951133404359682268866166351091394841215;
    uint256 constant IC11y = 17538372565220875497163050556530675870506742488750421762432185413298637930390;
    
    uint256 constant IC12x = 21239469804039709517170379521117326667207717518338701935917087770062989179467;
    uint256 constant IC12y = 5290415401887128856135339259942191964923523619934155417299943470434676887099;
    
    uint256 constant IC13x = 13997879064328385717080590276481436319034182220228974516527062248734514423640;
    uint256 constant IC13y = 10224242709013881573963856660945828580942320327975078518715734048894748942994;
    
    uint256 constant IC14x = 19039926738385171527011793537477888668139937749631917587031892692392898433183;
    uint256 constant IC14y = 6709234159956458308515104931875082235190760319650569238633859453978268945272;
    
    uint256 constant IC15x = 9973867337756727403550070893169332019564146938994380848063099977358325538948;
    uint256 constant IC15y = 14479945255672314452878900448240418851997245337926866086576735207258447707872;
    
    uint256 constant IC16x = 10408436554967518205980326944675368062613642141208116482980627644764648271707;
    uint256 constant IC16y = 6358746816463986963363011625380972789534881571649836632366644126849963239885;
    
    uint256 constant IC17x = 17880541436446567629035831798187840767783817601444084604537458933176843269549;
    uint256 constant IC17y = 11255687146163590122588026217319040360123929536107261861808625207375292659474;
    
    uint256 constant IC18x = 14794887630183373904494928906985149554797233413545092837399683651304644805873;
    uint256 constant IC18y = 15249114440414912593662658116720047053958181561773604848837339798841199225562;
    
    uint256 constant IC19x = 6585919575878019953552253145691823886956653396290642696035828463457230112291;
    uint256 constant IC19y = 20542586021519434732638678134172772226460825158807882946333562828426645639913;
    
    uint256 constant IC20x = 18122371052072925185705709738246530580449090900649148071078220845551268759921;
    uint256 constant IC20y = 239463249606087034567442565274175632017314919881524372301393586501566944433;
    
    uint256 constant IC21x = 21854373366754272058881398868423244249037582393427936942569086678581759258973;
    uint256 constant IC21y = 20886446580136949107595736184232278410604094757790925165028743565656984811144;
    
    uint256 constant IC22x = 1317011397349206432742675757469756966466717684303217357283228556651391703793;
    uint256 constant IC22y = 11877899949073243640066519163622545225938124254070984761787864037247934686570;
    
    uint256 constant IC23x = 5489028138089433241101375478519255314152778521474948154608525486020631082724;
    uint256 constant IC23y = 7269281120524096280742295825551808669777723262167142423185479541895385677323;
    
    uint256 constant IC24x = 6362709015679833305144369073759580798797030265960130930286659170575405089654;
    uint256 constant IC24y = 683125896170993470357200132811558031081063685688874751677149141887738230570;
    
    uint256 constant IC25x = 14637818502391638765757514824377589665806143651592271558716912290980223785821;
    uint256 constant IC25y = 9994845678912133130808659699425467642123833265303811934305324467625530887628;
    
    uint256 constant IC26x = 3894363938688383098578278638408265648379097031227289609050528092112322506478;
    uint256 constant IC26y = 11540117226809635550195003238224425189179796618485375002209420671011020582829;
    
    uint256 constant IC27x = 19448469200237249012511574497197366553578416860181578251894821301004949830954;
    uint256 constant IC27y = 7331663134479312094914883067807296058777163846295862859813695849177613250793;
    
    uint256 constant IC28x = 12761035483888580399234277106266268978580506487555242107251243510391268550221;
    uint256 constant IC28y = 12855418770955534134497638237221190231257703240386195610817795069973559059565;
    
    uint256 constant IC29x = 11035268352956995571794810872795129969771465050122473755194922801440056080139;
    uint256 constant IC29y = 17895885658609514078437036292218064940310584511787400839221584378242427479774;
    
    uint256 constant IC30x = 9922537287288244116736342526788289647217526276047527965329729965620042596891;
    uint256 constant IC30y = 9268610565355615241640601098126261973611390532305503110805786604071894787660;
    
    uint256 constant IC31x = 20561625470843356859413323479570806924271118748896695593828035473283655653413;
    uint256 constant IC31y = 11690282170605998343590351030529497414807853634826936479028619744756905541652;
    
    uint256 constant IC32x = 17065781792322851319138566476330400925427013635042099006973580701699500518742;
    uint256 constant IC32y = 6802574883284849875431942601429966698842695649953150848374491493008374070982;
    
    uint256 constant IC33x = 10341251879963476602758800139257242418062204706807760243620971194695994032001;
    uint256 constant IC33y = 21037158666010914965524209706921306712685663964328398955158364811844195059650;
    
    uint256 constant IC34x = 16898616488800318859544463447739793312048120432573028424054558149414517529083;
    uint256 constant IC34y = 16285409578391264655969183702691998393375015763475767209011936068879859430435;
    
    uint256 constant IC35x = 18251928075931478805961288513674419838542944941441333992423367432223480581736;
    uint256 constant IC35y = 746618281861081447815180903606482483042686416985263327692736765354210154303;
    
    uint256 constant IC36x = 9675350588974347832848230101269335681890682575081269510437669727964386246073;
    uint256 constant IC36y = 12136427083181699559800296329122652990504693598455103568399394561712381827384;
    
    uint256 constant IC37x = 11534056116886471801570015061464837221560738023960682602213454497639559889633;
    uint256 constant IC37y = 19640215977703676259350555005293153749453087397040230362525541330140946767576;
    
    uint256 constant IC38x = 10464721417464523402962277503191849274571234866549334484880061544422309515129;
    uint256 constant IC38y = 21392946256871866383329489628146412714738038684352853812108455633284869118039;
    
    uint256 constant IC39x = 16402146061986047256447543091260100286020245990610191139204066696779761993245;
    uint256 constant IC39y = 1284232440263337575638753486901156466458380948758762303913350476417115985901;
    
    uint256 constant IC40x = 20068075904428791545202183805391598514749355601764724820909218360475555688126;
    uint256 constant IC40y = 15372840419896039385899727181793595272131635481278871975505854561872198763432;
    
    uint256 constant IC41x = 16021498753159429894116094287416896742628555498850756347165622048000212167768;
    uint256 constant IC41y = 12776227237342652783450121960827923378133046570477159164966997143417816643810;
    
    uint256 constant IC42x = 1595497788453832172509402801580005767756672390632163779247439645205586182918;
    uint256 constant IC42y = 1967447958340177699728208434367666902273319254661903828335269217906361890194;
    
    uint256 constant IC43x = 20496695765394489710022445286983393156189683637119945459161489891335985987785;
    uint256 constant IC43y = 14928275002516874978141122258793321863882996811861195736355541756608734342573;
    
    uint256 constant IC44x = 7723281019076507359471092332905467206503532801111400396085103576982253621766;
    uint256 constant IC44y = 13077577494458785651261132485400795762252434927709641710826780521048042636379;
    
    uint256 constant IC45x = 9182663586539431875655566696603192812265033043308483538189843737932952772716;
    uint256 constant IC45y = 19032103548566268072824864742328144224461449108782790145609296423739906795248;
    
    uint256 constant IC46x = 6281889626804576810465078246280921359514951755479704566753425118618682718544;
    uint256 constant IC46y = 10460929423919813570728443199515430981012742446348082202574340194025318628352;
    
    uint256 constant IC47x = 21315670463803414403261656949319962709075890444072705647094683999110132434656;
    uint256 constant IC47y = 21567086990017219992448646987480601228462627773958695005854149368553438361092;
    
    uint256 constant IC48x = 13494455996853777133808707568237387643110618552407225073656017867773513976755;
    uint256 constant IC48y = 19196380290298179975212864737236915149291484619045148485831773653756455398495;
    
    uint256 constant IC49x = 3985996720914402073576020433502808501030145027352144669526186088139910498603;
    uint256 constant IC49y = 14850640273160092417153652341643940325482127697451851287630008890640869454225;
    
    uint256 constant IC50x = 20293039784953730950231177586914036955791522144864405120414714450687037638317;
    uint256 constant IC50y = 9765701354944622155164400404518342508806171104443027144705850671026741853896;
    
    uint256 constant IC51x = 21511648554984372594066431889709474256395614704553381301778756381833416792517;
    uint256 constant IC51y = 13941161593193274118187737951109636041112072834870572068341849333721701334668;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[51] calldata _pubSignals) public view returns (bool) {
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
                
                g1_mulAccC(_pVk, IC51x, IC51y, calldataload(add(pubSignals, 1600)))
                

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
            
            checkField(calldataload(add(_pubSignals, 1600)))
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
