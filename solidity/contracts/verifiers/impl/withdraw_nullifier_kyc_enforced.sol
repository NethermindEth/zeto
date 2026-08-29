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

    
    uint256 constant IC0x = 2751805287642208176553841631917063040569387693253609910108095452300326274306;
    uint256 constant IC0y = 16047768980584963157613205864138307613063732978654027944626098501099799507117;
    
    uint256 constant IC1x = 10068238256224022381808725187177925734094224913047993128038806915255932319535;
    uint256 constant IC1y = 19440410744401648072565892010005128847212613104122080787829299135627367376124;
    
    uint256 constant IC2x = 11583252107513871746739016741979238089137873482072294041970847132505397897606;
    uint256 constant IC2y = 19840510381454708042219115754952156078822710157384412326395754078475147473225;
    
    uint256 constant IC3x = 18474307626933212389203784411805786445037273326363094551002001752022818136135;
    uint256 constant IC3y = 8756283306192050997634263925417093450736186657075229792795809504598404130459;
    
    uint256 constant IC4x = 12346318881074947991496743062066962957923604886815377446345269253684473935447;
    uint256 constant IC4y = 8205171045932621251163569915197933237851348159522056689432155041654524436004;
    
    uint256 constant IC5x = 5159990414608453585056941699828033537778999930338610526826232025388448331844;
    uint256 constant IC5y = 6663927016864702670627513430211310254178584403870634065985018467549797898144;
    
    uint256 constant IC6x = 477513096101512035364899322733556242453045794729209445065553943694851997730;
    uint256 constant IC6y = 1640682689540079133190846188964949600288432444902781696532759219607803837181;
    
    uint256 constant IC7x = 20155316249666570835033011519331938806504177828770886044461253875706372134020;
    uint256 constant IC7y = 10571596786064431279323937550890703622515798420932674448006432793453754825739;
    
    uint256 constant IC8x = 16153192034220170795695951446193658445020969429231248647565186542952515538064;
    uint256 constant IC8y = 5575987731020811263278622400028231238418156093084709362536697955753894936625;
    
    uint256 constant IC9x = 18876028820470758610666888909768876070570758683287952988332544148190346253517;
    uint256 constant IC9y = 12084439619800082659590799820753130035256099319201613843027169893524313523087;
    
    uint256 constant IC10x = 16091074941087445149057387421686728260844522629493311399181273474620607437944;
    uint256 constant IC10y = 1676963103826446736723210884605081990317202318397420987749259097481758557251;
    
    uint256 constant IC11x = 901803504447055580493358358184779048504829024684589398002572399949138379033;
    uint256 constant IC11y = 20802539166565966938708033151511415689121492005692170855550972905770526412990;
    
    uint256 constant IC12x = 20206483482978735154831409436385000314440152352384271413786062584972698565554;
    uint256 constant IC12y = 15215944476352780631874024546022902429509439887444175225724652780936122872394;
    
    uint256 constant IC13x = 21239469804039709517170379521117326667207717518338701935917087770062989179467;
    uint256 constant IC13y = 5290415401887128856135339259942191964923523619934155417299943470434676887099;
    
    uint256 constant IC14x = 13997879064328385717080590276481436319034182220228974516527062248734514423640;
    uint256 constant IC14y = 10224242709013881573963856660945828580942320327975078518715734048894748942994;
    
    uint256 constant IC15x = 9701283507889741054831576363409567184056602942725453191935484618791120085082;
    uint256 constant IC15y = 10162132193114664212747855612795696540847450958803722186413706304427494943111;
    
    uint256 constant IC16x = 9973867337756727403550070893169332019564146938994380848063099977358325538948;
    uint256 constant IC16y = 14479945255672314452878900448240418851997245337926866086576735207258447707872;
    
    uint256 constant IC17x = 9251317400541915242989462816332108249204465940340887115390089898722456383231;
    uint256 constant IC17y = 5220014558996416079854648872910348369478373119572312718475890847905069599453;
    
    uint256 constant IC18x = 21191074449765203625101836409998876647520767018025217995456035784373105871452;
    uint256 constant IC18y = 4724595618395160754410773693139445725126986194546173961209345141397358082249;
    
    uint256 constant IC19x = 18525935948589518127874421531884306866928097249226835680090427393003203064744;
    uint256 constant IC19y = 2796223025527211168312638043521076327884605893650970694256150460557210518844;
    
    uint256 constant IC20x = 6585919575878019953552253145691823886956653396290642696035828463457230112291;
    uint256 constant IC20y = 20542586021519434732638678134172772226460825158807882946333562828426645639913;
    
    uint256 constant IC21x = 18122371052072925185705709738246530580449090900649148071078220845551268759921;
    uint256 constant IC21y = 239463249606087034567442565274175632017314919881524372301393586501566944433;
    
    uint256 constant IC22x = 16069456601513726965641415377841250340719791463167200417545819183528753677850;
    uint256 constant IC22y = 222524911979221183064824112342058139930370644351830827521474227943362228648;
    
    uint256 constant IC23x = 1317011397349206432742675757469756966466717684303217357283228556651391703793;
    uint256 constant IC23y = 11877899949073243640066519163622545225938124254070984761787864037247934686570;
    
    uint256 constant IC24x = 5489028138089433241101375478519255314152778521474948154608525486020631082724;
    uint256 constant IC24y = 7269281120524096280742295825551808669777723262167142423185479541895385677323;
    
    uint256 constant IC25x = 15552780945122379607150880806909997946380437129057827924854132265375507593931;
    uint256 constant IC25y = 19132545740781567531714413858129608898208667504050533404930811288690627490145;
    
    uint256 constant IC26x = 14637818502391638765757514824377589665806143651592271558716912290980223785821;
    uint256 constant IC26y = 9994845678912133130808659699425467642123833265303811934305324467625530887628;
    
    uint256 constant IC27x = 3894363938688383098578278638408265648379097031227289609050528092112322506478;
    uint256 constant IC27y = 11540117226809635550195003238224425189179796618485375002209420671011020582829;
    
    uint256 constant IC28x = 11982113086129846738786211322963605160007974567248996840189555680471922757861;
    uint256 constant IC28y = 13473254815140499901083874753282184297557067562724610158290285666181203860151;
    
    uint256 constant IC29x = 12761035483888580399234277106266268978580506487555242107251243510391268550221;
    uint256 constant IC29y = 12855418770955534134497638237221190231257703240386195610817795069973559059565;
    
    uint256 constant IC30x = 11035268352956995571794810872795129969771465050122473755194922801440056080139;
    uint256 constant IC30y = 17895885658609514078437036292218064940310584511787400839221584378242427479774;
    
    uint256 constant IC31x = 11901162625117906524796942188400399841200287622909150683011389206804832999547;
    uint256 constant IC31y = 15857995115683681874595853154305089734346077089636047449093447236801184002699;
    
    uint256 constant IC32x = 20561625470843356859413323479570806924271118748896695593828035473283655653413;
    uint256 constant IC32y = 11690282170605998343590351030529497414807853634826936479028619744756905541652;
    
    uint256 constant IC33x = 8451319572743286276406254232964094172016564517793704431931209719570033062357;
    uint256 constant IC33y = 20470845357635942896715082306158791842621121828903507486805922067968902565095;
    
    uint256 constant IC34x = 6500892595700924033313680903016840303831217391997544847411549213589671387654;
    uint256 constant IC34y = 2672071796329389186532500768657288625417753835397002178431937295045386456232;
    
    uint256 constant IC35x = 12793447114837884327549341102082006496142465350853169568107788278170232920508;
    uint256 constant IC35y = 10462030209775271234285942368792369878630833561717467009815790274350527345179;
    
    uint256 constant IC36x = 4236073190936486969881634575164979509625490420276503448179527103612088993827;
    uint256 constant IC36y = 11437954430382860337535171145665148186267175797268667734516724262254463963076;
    
    uint256 constant IC37x = 14394492970896372734896050337860539535054543293293585604750827019638089237361;
    uint256 constant IC37y = 13767343505522273770280550419504005675299198955550657847188888448652490097548;
    
    uint256 constant IC38x = 10918951858082762869397623687968288020318936252746588159118534128623997579181;
    uint256 constant IC38y = 9419268653579480529399204415228066827739299179496008270083507823338949593068;
    
    uint256 constant IC39x = 5148868797915869645210567441485946281196142387475994854884533869725825024145;
    uint256 constant IC39y = 10344267292728810961770936027101278710336407754226512223209205045935176781476;
    
    uint256 constant IC40x = 19610807315080318688431253491329396760023340646672583589886718755952544201494;
    uint256 constant IC40y = 3702708182481384121150757456543447949309258214365149487209540716986143748431;
    
    uint256 constant IC41x = 11611021620797757594560408083661868987692576931892681869037638274725244707579;
    uint256 constant IC41y = 14772847596829530543319457667931033202715407419024934926198420841370817711457;
    
    uint256 constant IC42x = 12921757522172937132278734901814575408376349967981960046172574270561281318466;
    uint256 constant IC42y = 7457529963884251124863554313921023275706854847275846852992907091933361095312;
    
    uint256 constant IC43x = 15034561107775934952656056377957047610955671399390901546340603633381441812196;
    uint256 constant IC43y = 18816613271865118523334299691535456839662366975167528147642243192601536373292;
    
    uint256 constant IC44x = 6269331023311042639228579265755892808582398847826342784486718591539422689873;
    uint256 constant IC44y = 356233639425891333265455764581711141954446007909020956189900501936377239679;
    
    uint256 constant IC45x = 2515881463711714222134649644320782375228535853501239910915416151851180646491;
    uint256 constant IC45y = 9177838808151968732634084015509374552844908715772694366169889252603175280253;
    
    uint256 constant IC46x = 10777342550281542601606973281847899399062869309776276520762467973905277446329;
    uint256 constant IC46y = 10646521965138926817727986311343801718462311755548848989776666988953654652315;
    
    uint256 constant IC47x = 14962833145241005068752812471062284893502579889378766129712267176556411303568;
    uint256 constant IC47y = 16788579716987865389841503656796007279579791470469593559405380669775688938965;
    
    uint256 constant IC48x = 19146703333500387150618901558694774334590995967853193843676509325905257453317;
    uint256 constant IC48y = 7222675565513924969578823557320284577779937568824426700869483119172943241166;
    
    uint256 constant IC49x = 7992486437399344413321780363535615450281892000786070633936758847654007751326;
    uint256 constant IC49y = 9600398219048797653431719843921816707272805391390000788030514841033439139179;
    
    uint256 constant IC50x = 17258612595293148083079706178795192531028825887089216584806184727400440644373;
    uint256 constant IC50y = 1228297181509830257502810836957252167942734067730966277671067548129491894052;
    
    uint256 constant IC51x = 20761865864201401321570869424583811222414591838431910890643310341372505078121;
    uint256 constant IC51y = 16310959823808074847172050235213492588862650011611841287870091836790972705032;
    
 
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
