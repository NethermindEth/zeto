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

contract Verifier_DepositKycNonRepudiationEnforced {
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

    
    uint256 constant IC0x = 11020782072846676332854630382173374188549037755356523067184831661917937756240;
    uint256 constant IC0y = 3160865225500985599780703329033623194488581455287032803220673149096711794636;
    
    uint256 constant IC1x = 16945697449508993612110655975512084815570706863085516405507974295390199061863;
    uint256 constant IC1y = 3168447593699331044371429912948744519855082207246472898504768151202041889499;
    
    uint256 constant IC2x = 357713788667019572950441854388004123548520250924324437363458880613854103049;
    uint256 constant IC2y = 9428983632189239262305999541034734208006529444783958864818045457310003429963;
    
    uint256 constant IC3x = 13806546309468778618854321522620842701208724483992178784048693190158844596317;
    uint256 constant IC3y = 10249753732193881160196453273163682343141127007000616856604701566756885037613;
    
    uint256 constant IC4x = 8810764525294899866684334619989760043627297681757085000824758976263964992077;
    uint256 constant IC4y = 1555065485364127344848112177956137559429791822690229563551095194199521723463;
    
    uint256 constant IC5x = 14819245299860075321750335584374528581114529452125815349915673064560415726804;
    uint256 constant IC5y = 9877138543483024124694995337300272331653583314254631941717808921555571423121;
    
    uint256 constant IC6x = 13678413649306765478862288267367883688636222133449073899836400576821489680423;
    uint256 constant IC6y = 1966368438468894663521033783064223123203258761307050462820321372054828935561;
    
    uint256 constant IC7x = 12785957746475762225799576663905287956060492002943192318293047736177109079804;
    uint256 constant IC7y = 8559159177948048860834757872867184135793687518255431809737804693317621583581;
    
    uint256 constant IC8x = 16677942263756911030169704762044321547703033504676519428968903353323336970270;
    uint256 constant IC8y = 17246756809537393979189596664606258997843748137820357508370229339054597187419;
    
    uint256 constant IC9x = 18436676902013552458980497221261217095474189798875686906861222367578420252236;
    uint256 constant IC9y = 7409220513446599942261103245171106324300709454949364854833751795396750061648;
    
    uint256 constant IC10x = 12410624313046713529885397553763288897557083622274689562164885180034351710562;
    uint256 constant IC10y = 8851642125399300696501255966074691783959088946821120110404118464324033083721;
    
    uint256 constant IC11x = 6584347914545049192769815162721646276246068448586181050524652312623036226336;
    uint256 constant IC11y = 21069368245003119117998953549235232987559012934496293815334899836833364159387;
    
    uint256 constant IC12x = 12368360128943849670812246502531947407672317191257554047874582599197407131900;
    uint256 constant IC12y = 6577869597007248429747634815589611712348943373117457321942674548158346647356;
    
    uint256 constant IC13x = 9800821955918509642748191937079300175898903791798257686329281414851782112365;
    uint256 constant IC13y = 17525151722648220058642109666072111088794043460097715844747307379833722776782;
    
    uint256 constant IC14x = 8866688776411694014000972870568690698647339951656599397216319297203335523362;
    uint256 constant IC14y = 15605356520597109170640569147072107279980717303856042094155201399240104961535;
    
    uint256 constant IC15x = 12751055585124963320286094636524996074413375430597380529807733120172009436353;
    uint256 constant IC15y = 8826165013576229306005278211235050049176529189207756602634574109362837182939;
    
    uint256 constant IC16x = 16034627788829367575394832971492711514503324347941143904472437205763297490391;
    uint256 constant IC16y = 2425265378342917567036242170567923166785397456305232301803050103441733289738;
    
    uint256 constant IC17x = 1623497996833928926462932399628899561509427102509919239814432023995816184811;
    uint256 constant IC17y = 13882750355509525707296551054411154575169536868968753965691658971309334050001;
    
    uint256 constant IC18x = 664662962167460012935530443562002903309013092056063390125837361904143196460;
    uint256 constant IC18y = 13322844679893111827591516230246003531225010274261029689648153055171972085504;
    
    uint256 constant IC19x = 16415789791964328429562794103775260284269968675362516522264401939574134316786;
    uint256 constant IC19y = 8294639730764640189144266514127863812640426007785775875275764478073547280987;
    
    uint256 constant IC20x = 1618395649752979480070430144556674894419012561185924241914876044766378468652;
    uint256 constant IC20y = 6606469307571374786730421511434350818576674059924903686986435566985119506396;
    
    uint256 constant IC21x = 10593088646335424259797687542527168530725313011229133722734328005807195182055;
    uint256 constant IC21y = 18926710102567287485894997464716091425677776531970520633063261016991406400046;
    
    uint256 constant IC22x = 15416897733634400728341244680490275809514296882207183394654375144103638091579;
    uint256 constant IC22y = 5121135062985515092091379196794708270562712624616842239195813954495744700704;
    
    uint256 constant IC23x = 11208897506197975467812407198291097665426496419846615736151820392181224477535;
    uint256 constant IC23y = 17755162876415685017853105488558317034053293712074781791830586909415816192656;
    
    uint256 constant IC24x = 6578200946506842855620435132403092832792655965326681098859294803329832961242;
    uint256 constant IC24y = 15495280116880454140390094657874407146086373851913152469733664878878310780445;
    
    uint256 constant IC25x = 771039522077459729405685264938522770184946401874959383571562007766469230405;
    uint256 constant IC25y = 19531785004666295039893496951454714567782090603361760898210833125044339536626;
    
    uint256 constant IC26x = 1633972438191633246049501281654396525731963180135997049592136281245874335811;
    uint256 constant IC26y = 5037944532975153369420892235386521900580443373785126387727505928451498049731;
    
    uint256 constant IC27x = 2679876256255020739256508203816521092022275780170960532410837683423180815794;
    uint256 constant IC27y = 4378619444914419318195260841694110154116820033024687118581968430099470906133;
    
    uint256 constant IC28x = 2447575845503219307631010074889087682928238130239294221933782081980159741305;
    uint256 constant IC28y = 16299543895904054122550379586881472792952059601217183863943870410089026199147;
    
    uint256 constant IC29x = 10744378865668042745528361259827531720685161309618030520358866742598316341785;
    uint256 constant IC29y = 9080466370047214530403141147301578237030678629492684370393588414300774765775;
    
    uint256 constant IC30x = 11277752260215168238116432362763645984217799788979645904157346979584564406633;
    uint256 constant IC30y = 9219781704642698309890952730612658365956971538626526676994821505473313106178;
    
    uint256 constant IC31x = 18102323157333803324233630970351632338710541207581405720807203987606274806752;
    uint256 constant IC31y = 11427386519284289858184519562195634449845165446176284512757976568559051900739;
    
    uint256 constant IC32x = 21768961159849544511396324502982118542196902626329074713173574803171368786079;
    uint256 constant IC32y = 16124877843185542752014037854063123043244247821369624696132474373551017557926;
    
    uint256 constant IC33x = 11333584649726059698606678026624044556265968958296743272779393500743549975292;
    uint256 constant IC33y = 17835831071505433303986155177455997492209767510373928990041558438957647020064;
    
    uint256 constant IC34x = 13465269649721566553481847601591037096539990189782406830324710319854351040925;
    uint256 constant IC34y = 8373198782960504848940049226683636352922626853977706715354206461121204057072;
    
    uint256 constant IC35x = 14263077416346289332595134243415695175290817916024186848888227329938039199966;
    uint256 constant IC35y = 21632203704091659060939267372076986389318702533126979247883146915807850116062;
    
    uint256 constant IC36x = 15412103556102386847115130861594982529066957923927328374829537939024077584001;
    uint256 constant IC36y = 18397536123114795624538561697068581867513291354915854061765428633834157031520;
    
    uint256 constant IC37x = 12200186099425077471774865669844059005276872079457650993754897071121094149708;
    uint256 constant IC37y = 21653745443995145405340495987827655754700840220236999674155515898915736865839;
    
    uint256 constant IC38x = 475384049526944718131386765840048879234285089353485350229612264193010787028;
    uint256 constant IC38y = 11517751243707136686633058811928341887915811432478912814757857241593538475111;
    
    uint256 constant IC39x = 7416450106054817580648570219133109974771447115881890845326061621599601057827;
    uint256 constant IC39y = 4027167906809793455013270182402051782580652673714636165113109324192844673240;
    
    uint256 constant IC40x = 20366339817828135598001111542611817505016377901468137639494314940788854527414;
    uint256 constant IC40y = 6829471663733341615783977315187457022995582674603139512514311233263902977662;
    
    uint256 constant IC41x = 10176686654106078186114301449275091129617158191214968182455898603751810923769;
    uint256 constant IC41y = 2772257525951948950073783129898800833707362144395807546209919099607238225538;
    
    uint256 constant IC42x = 17653475592296306548001220074971476288112632532068504194984032026541314388771;
    uint256 constant IC42y = 14909491212851278011622160289118230250325425815654300406179880421138818421727;
    
    uint256 constant IC43x = 19655124040548265204401723957822659199009195166881891607762486828533035228403;
    uint256 constant IC43y = 19527972643538949143247163884839223113463824393485850222242363192423569585529;
    
    uint256 constant IC44x = 1192342530079112196075123362117615845946556292822083358622296910365415604244;
    uint256 constant IC44y = 5317812933731270950032948589508900120777881244468040214557664767356873818959;
    
    uint256 constant IC45x = 15334146041399808721772789432832558967524336222197822783047161398172556869888;
    uint256 constant IC45y = 2782261369053615535553068305899609391821330215593628864709072959413179302219;
    
    uint256 constant IC46x = 2609992995375305952077689863568745634885723016676903348034565375328721674623;
    uint256 constant IC46y = 14776823622735931126163115471955221007307677205645117702574055226165253657269;
    
    uint256 constant IC47x = 1133729410830369223411543100989581697746931042440699477821607864697561049337;
    uint256 constant IC47y = 2867691949969595669803444113599461271807501904646261909696633854761106584142;
    
    uint256 constant IC48x = 11592986787093014559365978682733314370741664470864173843879852522662363190799;
    uint256 constant IC48y = 8070437158503078923855499694430054452458372453092390380702934813693299890029;
    
    uint256 constant IC49x = 18448047974029810128830858718731527771531863439965075218502453526889676825699;
    uint256 constant IC49y = 1051807283062151869903420751434878267428698597904208788099612202997021956200;
    
    uint256 constant IC50x = 7036884559736299893338949545883538564266169665050835668671198598643335794150;
    uint256 constant IC50y = 12793201801199459944656415348438083620482223372599109794219399505749449519994;
    
    uint256 constant IC51x = 12022529615755084702041282622460310511756732651802606244867116004884870960284;
    uint256 constant IC51y = 18870409423466339897137637417744560865800540875958947347880314886587028625644;
    
    uint256 constant IC52x = 2433956574462909968685332116766030248974500002426393696512130479837935401652;
    uint256 constant IC52y = 4020221246673351401930280449534802218203679223137701030270695506108860748853;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[52] calldata _pubSignals) public view returns (bool) {
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
                
                g1_mulAccC(_pVk, IC52x, IC52y, calldataload(add(pubSignals, 1632)))
                

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
            
            checkField(calldataload(add(_pubSignals, 1632)))
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
