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

    
    uint256 constant IC0x = 20642925960653893652383548613562491107811621797536604627338227817517084528439;
    uint256 constant IC0y = 864811453585363941255609222614884135249236514096852396977431424837148928856;
    
    uint256 constant IC1x = 3206297699968447951090516996763466108652777788735355446441691301900319507559;
    uint256 constant IC1y = 21576337880484702364577018752798798627923752000108839729476076257294843369259;
    
    uint256 constant IC2x = 4097354879141826861166415397843547064095480127894749476897356879261376531078;
    uint256 constant IC2y = 3599759483731252651293269618981829690425253665022601695765991429730091627718;
    
    uint256 constant IC3x = 5547160783910505563307298522756106301216003416134848640330978605535929025788;
    uint256 constant IC3y = 11103210927920924991784998003222395511006220713575868514319497835315003990764;
    
    uint256 constant IC4x = 11488873354811489344754774410495318434777994495092016410957759162948742533893;
    uint256 constant IC4y = 21727423981351880341418966913503814455704568508595303345356966462765942718973;
    
    uint256 constant IC5x = 2387306902264430199206747400868742651447089877066960784688786432493012144313;
    uint256 constant IC5y = 4910396497890299633077306328595930159233210196177080252672828361111560318970;
    
    uint256 constant IC6x = 21029925439251107788478079181274204797543110864557848876686052760446344332967;
    uint256 constant IC6y = 12090921828484308263327250525268799920735029952451805174768065818167018484264;
    
    uint256 constant IC7x = 12227366851899566299879609287125288049243524776388098476631776319015823261287;
    uint256 constant IC7y = 16205537619628258451367598849487330067444510889531867241140491065580104968751;
    
    uint256 constant IC8x = 9732853839620855317091962712300239767944323798038314687999180454940391292614;
    uint256 constant IC8y = 13948515150057116727064019944603352045445219532025315392023836675212120363947;
    
    uint256 constant IC9x = 8500544609622212965680431901210779821096742798797488428448495574184347385182;
    uint256 constant IC9y = 14296408347313577422224363291926898822627391577708212648679247809977149797776;
    
    uint256 constant IC10x = 12765503557453358243253172726820512406861530026915759492065660212109834792306;
    uint256 constant IC10y = 18163917318174217312535708286117940228036497340438821448472972741267923201214;
    
    uint256 constant IC11x = 17201273170554476281946431585183214214966402312432063374702798019257136278513;
    uint256 constant IC11y = 13144036048122018238402125676719037759712392317231823700329918541921484427;
    
    uint256 constant IC12x = 10870603229699642570490496113859447589841971562564721594702693338489543186862;
    uint256 constant IC12y = 1844293239505183199874010811625644493410164104801354062389552492878487220229;
    
    uint256 constant IC13x = 17699774835428401718738513769388934354922975454302593158318634418161170113025;
    uint256 constant IC13y = 17527363796856114513179643260926496286665473939806122281816824558107502155660;
    
    uint256 constant IC14x = 12368360128943849670812246502531947407672317191257554047874582599197407131900;
    uint256 constant IC14y = 6577869597007248429747634815589611712348943373117457321942674548158346647356;
    
    uint256 constant IC15x = 3039570921585869777366918133708989856116791140670944883840894905543993466288;
    uint256 constant IC15y = 3895163332349450775672137204044729482467927146578278198400535892632823701791;
    
    uint256 constant IC16x = 1162340998272884557567945911098045496427028100977922727965832991726890611206;
    uint256 constant IC16y = 5177933231540147338404488902087303283868786533572858488855522926505999823208;
    
    uint256 constant IC17x = 12751055585124963320286094636524996074413375430597380529807733120172009436353;
    uint256 constant IC17y = 8826165013576229306005278211235050049176529189207756602634574109362837182939;
    
    uint256 constant IC18x = 3713682115810954387392517571359427471082360365985962831338536858481506288854;
    uint256 constant IC18y = 7038924781645552660046578798571966986710474580383698078268136902332660031071;
    
    uint256 constant IC19x = 12416232386730247621011937062501399856454895893565123891259580740330200378213;
    uint256 constant IC19y = 15610487732106705130581634029743089064383917655287082052070985803152670333;
    
    uint256 constant IC20x = 664662962167460012935530443562002903309013092056063390125837361904143196460;
    uint256 constant IC20y = 13322844679893111827591516230246003531225010274261029689648153055171972085504;
    
    uint256 constant IC21x = 9976957361157709222445824747432194261184572804309081462831352326647778633798;
    uint256 constant IC21y = 15399038295382412506446576182657456406854725480084331082983465608530926648692;
    
    uint256 constant IC22x = 21635173371122411543878937409587473469067072302071208061157668369410308464277;
    uint256 constant IC22y = 2859213312308222914585282910884429590868492402527078488087249027655069092527;
    
    uint256 constant IC23x = 10593088646335424259797687542527168530725313011229133722734328005807195182055;
    uint256 constant IC23y = 18926710102567287485894997464716091425677776531970520633063261016991406400046;
    
    uint256 constant IC24x = 15965315586090949085672852133877947142435761394369707222043593926651239976748;
    uint256 constant IC24y = 15353956056912272076316577723177513034546024733876991292336574363774465561349;
    
    uint256 constant IC25x = 15185803479871156769459485063771411747058895361135430192880961266524319206561;
    uint256 constant IC25y = 3329598012628732007834804955057614909668498023015636423068000158193826681165;
    
    uint256 constant IC26x = 1527560641581397969068746708856871355984635468595515594685583020076628099869;
    uint256 constant IC26y = 4313233869848255551445986779468623869555999431079318776276994711168839288578;
    
    uint256 constant IC27x = 12948883705439460692395422882380241992778992478306119876969161739837450755756;
    uint256 constant IC27y = 14529778467389166982655999664262762456199433951226406495641350608145473649876;
    
    uint256 constant IC28x = 11427862830960032242232655918560324404860083179124237229556756640446008584341;
    uint256 constant IC28y = 10826675891451671220034349358084752478535423782062313236269079896100795429620;
    
    uint256 constant IC29x = 21227299113801666141481513954359098072064982200544553175792664730969269396769;
    uint256 constant IC29y = 18184250773051843989532022985499900374116612348018538763677210244358452879700;
    
    uint256 constant IC30x = 2447575845503219307631010074889087682928238130239294221933782081980159741305;
    uint256 constant IC30y = 16299543895904054122550379586881472792952059601217183863943870410089026199147;
    
    uint256 constant IC31x = 20201922870824522392680691336902849592387457480121955244832292432396066073356;
    uint256 constant IC31y = 18350182133244464998635475875665256055304166020538023037289326130360046772412;
    
    uint256 constant IC32x = 12885082548967300429280255262013061890867415444374656369535666080915366119266;
    uint256 constant IC32y = 21396253751313740369613861539652114615172230448861190196468213427693067772891;
    
    uint256 constant IC33x = 18102323157333803324233630970351632338710541207581405720807203987606274806752;
    uint256 constant IC33y = 11427386519284289858184519562195634449845165446176284512757976568559051900739;
    
    uint256 constant IC34x = 12251059616485588670964224732443798987091214597605404909397769917653084996874;
    uint256 constant IC34y = 9305282963290214604613219442594702036664088022093320903761265708069602547129;
    
    uint256 constant IC35x = 1466316083483890198556995399137086645457824366803728186933407506583773814217;
    uint256 constant IC35y = 20861648868770708456299190060373322008348631221237497003122760316704804580295;
    
    uint256 constant IC36x = 13465269649721566553481847601591037096539990189782406830324710319854351040925;
    uint256 constant IC36y = 8373198782960504848940049226683636352922626853977706715354206461121204057072;
    
    uint256 constant IC37x = 15410543548923211229605963370765837489822142654506053735632154348796284923618;
    uint256 constant IC37y = 12594009572095658832032080866350522265423006945689000190857740739531979405997;
    
    uint256 constant IC38x = 20301834776307152335717729782661181168656007363850222602091228743952700566771;
    uint256 constant IC38y = 16399295129705340585443088078931156706753117672926209587561852325072023145201;
    
    uint256 constant IC39x = 12200186099425077471774865669844059005276872079457650993754897071121094149708;
    uint256 constant IC39y = 21653745443995145405340495987827655754700840220236999674155515898915736865839;
    
    uint256 constant IC40x = 16590751545488265549640485747219464510188820429239121078369278520825540774251;
    uint256 constant IC40y = 16908385369123983709779151286050485673253568500242542559356255565012922115922;
    
    uint256 constant IC41x = 21015083877993044968933809619347403024179897658494539559429389371004270627999;
    uint256 constant IC41y = 9561446085566376860507450264293359041931838202258145462947165613899634860505;
    
    uint256 constant IC42x = 17861855475363411623619560893159309749441462937274815856783296117715165958145;
    uint256 constant IC42y = 3655409463469021069101760637211799328596199193433330184760825135228461656403;
    
    uint256 constant IC43x = 21426286122701839368051982772199474385092449420547154799221583643009195937361;
    uint256 constant IC43y = 16005604848271014064596536984408659733350925002183130688600475121089612908349;
    
    uint256 constant IC44x = 7601341934209504657693922098886005950062278021299130687076463295688527538518;
    uint256 constant IC44y = 16622232483320546690857617284580479797337414159998597339692472780686382948911;
    
    uint256 constant IC45x = 18994993404219583028885634183156529256641792806280223163751206338823359930506;
    uint256 constant IC45y = 8672524885703487026136169597322264715156346517421848632135410867471587464242;
    
    uint256 constant IC46x = 19090345314701386293122596205653910005870451590025132552866435470923365119155;
    uint256 constant IC46y = 19306759561535485288158936398183430460547388138277327984552423004040220188340;
    
    uint256 constant IC47x = 12809024594669941467436374216779013135029831207360525230470696239232140347680;
    uint256 constant IC47y = 10876981259562621017355228310616198984846454337437466380244593289127316670278;
    
    uint256 constant IC48x = 1904902620664788064892011869196980015353418048163326609382397052771474684420;
    uint256 constant IC48y = 10649361723070153259430216642796911239544203523756827683636914153245607225542;
    
    uint256 constant IC49x = 2646868660287170651099377529198853997071771812086599193815653502017585897039;
    uint256 constant IC49y = 1669158418917410790110716099641144571290477752324721190151646097717136594932;
    
    uint256 constant IC50x = 2980033859688006351951143173686683638601369168596032950387755132014976337253;
    uint256 constant IC50y = 5246275241761811888010334216591345186002927250741342826690386134958102731698;
    
    uint256 constant IC51x = 12540160092147256078356723805689486362534055067185585963334947037364957708189;
    uint256 constant IC51y = 6874149123212770701353521268630662803917359252424725249374793361031110767831;
    
    uint256 constant IC52x = 7560028559507561217866051140013198077386603787921543394846336500365758096339;
    uint256 constant IC52y = 14934498545241720414191678034235295880505300504185148610335214056733337065493;
    
 
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
