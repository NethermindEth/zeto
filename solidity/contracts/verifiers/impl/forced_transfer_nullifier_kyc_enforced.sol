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

contract Verifier_ForcedTransferNullifierKycEnforced {
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

    
    uint256 constant IC0x = 3366540367951405744657796644181637805985102867349391969792156316998609920715;
    uint256 constant IC0y = 18855859118699951517096543347679723108224185086664181809332124041348153911221;
    
    uint256 constant IC1x = 12326231257914339581382600132865331069613866078904491263480826157746515639314;
    uint256 constant IC1y = 17349730541580288054574410060153159418993989666047465873698539191784320946782;
    
    uint256 constant IC2x = 21091469265497475439362286713547545042857721754953019009724573881392163829651;
    uint256 constant IC2y = 1585922718049073221690448328551528892892033181655413550860224751525625117952;
    
    uint256 constant IC3x = 12764310230542258418230858118108447745181846132146610575130094841996385242546;
    uint256 constant IC3y = 8548131552135388711498873111147025269505129773519282355521074201039080049302;
    
    uint256 constant IC4x = 4930983562920285646606289110283820568569126559858060797149905951860347617813;
    uint256 constant IC4y = 20235375604272186204738049460001600404124824406457280315943996587884603206059;
    
    uint256 constant IC5x = 5563656897014588011490092990127628583597829998497934773978897114656876715518;
    uint256 constant IC5y = 7150095381268537849660846100966672858195487728888327898622781889042473270149;
    
    uint256 constant IC6x = 6351203278488187883896404218144717198921747629730323685085756223030539709229;
    uint256 constant IC6y = 3667759065921982533131716880303130643469735041651713057808383330357591973635;
    
    uint256 constant IC7x = 21739288494845077092801524641878867488428333382419392864042008341981819466026;
    uint256 constant IC7y = 9119382149322784622853074814866854158820663476181243827013782918751836639109;
    
    uint256 constant IC8x = 10493056317747000175818294559018255134822922680903571659908884499391948858019;
    uint256 constant IC8y = 16254906234586454019708508329329522511034412699168021925598371023872512720721;
    
    uint256 constant IC9x = 11051830130002828980474057483650099547362864498047766287455845057102933561052;
    uint256 constant IC9y = 845490642322050729779576204705717803306624246998645781431394020558017672091;
    
    uint256 constant IC10x = 10575915608547561339414567156170636072175364710670048540561249982849902637495;
    uint256 constant IC10y = 5870263316293581497151967864735648116961150027350179489159328551979433586542;
    
    uint256 constant IC11x = 18503298274952528096463860395844907986172052594952281103470767629602586989356;
    uint256 constant IC11y = 9344204437998414150929484094433578982256232394540619093737709168608604639701;
    
    uint256 constant IC12x = 20234968197763681358400121437438311168091537793534978383446186939384591878228;
    uint256 constant IC12y = 2502148449035939226544905736955411575620575990365892123391771431440906684688;
    
    uint256 constant IC13x = 12573174736094110535603025413935605263930222518556855652851188763097375097495;
    uint256 constant IC13y = 19556248502072050290813816683625083456931161997463563174123197087029555718117;
    
    uint256 constant IC14x = 4906066950238918421705236731355345621882692386419741769173666721998663011258;
    uint256 constant IC14y = 17912795257356733869264446916829462684024860998879024863013899618971630651850;
    
    uint256 constant IC15x = 19394227121755519742052982877244718028678816288088862151949447400177017352024;
    uint256 constant IC15y = 6425725587901718091963685985381801558319161496241318127115158674763793718070;
    
    uint256 constant IC16x = 4127183334478482951323786301762162639743351897747042131319296909097647500947;
    uint256 constant IC16y = 11474249033918324944353861751937019301384246225535027216714770756648927439915;
    
    uint256 constant IC17x = 10086716751110058840801000085024311051206596987346143858811274986950103272494;
    uint256 constant IC17y = 1942345077198777017065877526711786235511889325636677603162906421882835157829;
    
    uint256 constant IC18x = 21159080316877774580920567318039014375596187853718783578632081912301050904501;
    uint256 constant IC18y = 14863637751767239076422854363424741653355419366008504393773768940223145526215;
    
    uint256 constant IC19x = 21512990997587937809296262660050980922720592336826862700071847425570573628870;
    uint256 constant IC19y = 10991730722656456631787215664302767764125554788352088835886930462335980615497;
    
    uint256 constant IC20x = 11748238337778481901041006894226206815587361091321233543689334159959018339975;
    uint256 constant IC20y = 21638305217311352552411411284629289145700859734890363291703538110466820628155;
    
    uint256 constant IC21x = 13108104296565501705802990039244318046714363823724559611400909192153920734580;
    uint256 constant IC21y = 13900722913334258008499567736377735976574420395126672993530137705309507930261;
    
    uint256 constant IC22x = 16498874243663729874507858728374012462590758574519216871965939907984995386189;
    uint256 constant IC22y = 10219054326897004172712146576423584597861388889883983346909270751449692088227;
    
    uint256 constant IC23x = 10840540974376341010553568414698346556155701915810873619033716103913396676672;
    uint256 constant IC23y = 13982311661448977913782065290879576216641353143139149550827953466881757839699;
    
    uint256 constant IC24x = 1216719134664425751120038858707953509714423363770387727178510273737242461187;
    uint256 constant IC24y = 12492491643255054595576779113963281379849086098714956797864107989506906513304;
    
    uint256 constant IC25x = 15611245751204702488779347196210771012394412367282558635206229126611039644058;
    uint256 constant IC25y = 3835878547592565613604494037652571876545408954807547297468850002152348412800;
    
    uint256 constant IC26x = 679765826838991890529837179163964197351858969265748216148754835426815227235;
    uint256 constant IC26y = 11328338435543531777367165883957636296204587881126058113395310670670513166803;
    
    uint256 constant IC27x = 15717194842142053574861685705595731115892526678621460148145631428606401707148;
    uint256 constant IC27y = 4427533945763300324820220089218981998588883452423093723089413109901589114988;
    
    uint256 constant IC28x = 6920158233170829152955334296764720217164729542763864324211462539584649520440;
    uint256 constant IC28y = 20789585454993617466872245540552083985428680553249036768752358495767399582503;
    
    uint256 constant IC29x = 1652942002967108642709861076109877433956332424193813001293436857717329033456;
    uint256 constant IC29y = 8492943866403161645284362870481779491742408134393668123408609725862981152925;
    
    uint256 constant IC30x = 6425627601670454658937894055230651128431351757676884245050680352026041811223;
    uint256 constant IC30y = 8525468118624887510303475627407313758680671801091143245830893726448953945772;
    
    uint256 constant IC31x = 17483205948686091672037116552428770813776219202237899427778367576476583902997;
    uint256 constant IC31y = 5059922112834976232004619542667458096887104505767456229592966517903301341136;
    
    uint256 constant IC32x = 15302666412310137676669001224566208926115525344789668649771343185004177899187;
    uint256 constant IC32y = 547666935398919009141691372436991160810977838433889258804367380479895428902;
    
    uint256 constant IC33x = 12207605200508218798169364983210173624517081707650380428188561831560517296853;
    uint256 constant IC33y = 10209241852028451183210305623056380377347668873008458179019698204052429172735;
    
    uint256 constant IC34x = 19183640846858891184900019447002943866217150079092282867338890447375717606441;
    uint256 constant IC34y = 6939908673993957590603400649688990281867587661898116184807719277703828321638;
    
    uint256 constant IC35x = 16482484325814725020754757082784677093940529785205768813913217737094992901460;
    uint256 constant IC35y = 4009265100686928488893215244917608680672623626964736399605281973465328443788;
    
    uint256 constant IC36x = 9280842314351017563918599998006975627778107174936520543855834068739259306672;
    uint256 constant IC36y = 7432631035577163974055199699080818002306928550185885312763001446831694803199;
    
    uint256 constant IC37x = 6094362699451776337299291803475129078347435504288204045132731813805877006704;
    uint256 constant IC37y = 7172540880299013382868216350734075507233883636227516424514631705777368186738;
    
    uint256 constant IC38x = 1134048418123458763161952005884936627447032839382768975498840566333930358963;
    uint256 constant IC38y = 19180050832769231246572039231541546334859376578599057221745686192952303830276;
    
    uint256 constant IC39x = 3538682344802696573557920359245605752890619309623756687389827951039004136711;
    uint256 constant IC39y = 18494265243096427638405951398117810266745985752085534652436835934398259309657;
    
    uint256 constant IC40x = 7769245654420713808473960580944906705055896459687016857217990079549846584645;
    uint256 constant IC40y = 19711699108247525768125900488622956978607547000121450915170715257525439096533;
    
    uint256 constant IC41x = 14038331145637539543503431752257484981727713298393073343516398890877209033351;
    uint256 constant IC41y = 16360698586484608118839084520374703159192347597436912306908441148505886978472;
    
    uint256 constant IC42x = 14098730473684345930454010226684926804492761104043880186507575437240420682168;
    uint256 constant IC42y = 12133781226553259352919646734576954690801815870254433630266043395419933754071;
    
    uint256 constant IC43x = 13333297551324591377686684336328009285674677851512451889679447818339119130118;
    uint256 constant IC43y = 20570938237811143936845095787498622717303944674664874116017747510311938249022;
    
    uint256 constant IC44x = 5872572348462062355650953430151566364308243004802690114618587932724074446886;
    uint256 constant IC44y = 2987299436372167328962813218766597454917902615001323089812027176086529075358;
    
    uint256 constant IC45x = 3534959572424535115452311265762344449259488358965183058898781885974076825064;
    uint256 constant IC45y = 21390082025388562917421749266079827249009311063318660616255199131252914146840;
    
    uint256 constant IC46x = 20379489600470361981090613203642637222521406846400173390802964280571193077527;
    uint256 constant IC46y = 7367937598345407966495301809494798694040943436180810642408434282327079782557;
    
    uint256 constant IC47x = 12994558245100958563548696784704250021187519796606944155010698995470165042475;
    uint256 constant IC47y = 6862658552724360205415668695178529306954944262253825151291814088571683633500;
    
    uint256 constant IC48x = 3875674766114983803363200426580297682208677032705159105246297768582921876234;
    uint256 constant IC48y = 19370116800968850556248883467270322292943112074849336302173495922628198218604;
    
    uint256 constant IC49x = 1384624301144525076524649325751214766343630158329039413135718600478477069717;
    uint256 constant IC49y = 4343228826156536353307015974289869279895644160657605475867771681165488203445;
    
    uint256 constant IC50x = 2477491752676848706855138062554496763411303216254553553409979380927169281841;
    uint256 constant IC50y = 14376556413714672818448714810283349440732032135577840927898887002819879820716;
    
    uint256 constant IC51x = 14744464392949331844227225677110547008197793537131054238812404855721076151661;
    uint256 constant IC51y = 2086513824073078243127159244886703793349954439699469389972200270502400821000;
    
    uint256 constant IC52x = 14540654392745945883729490065717981461989305071476524082987264538447612829728;
    uint256 constant IC52y = 11358912749320074713710697170450909963372558386091211020792178025027976330101;
    
    uint256 constant IC53x = 11179699866850731324428872942623854945755693637777279696004916275632173061748;
    uint256 constant IC53y = 13751790650030315675657869633984297293158099213664780127750744654651705467000;
    
    uint256 constant IC54x = 11885859772586541942753755061772525600265362467137123195367813001844244887931;
    uint256 constant IC54y = 20681388260765541010997314232391853080378356784226526288619882620720487192380;
    
    uint256 constant IC55x = 5981532928167731588593354916858232346337385453998720021365570913859116122126;
    uint256 constant IC55y = 20012340129006562815931106773540535496443546277166077367523086248617320903525;
    
    uint256 constant IC56x = 2931919146999484746934859458274490164521812062060877197234830424168009051134;
    uint256 constant IC56y = 15570545698806146844403591242909965839144873138447802679553064236248557181166;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[56] calldata _pubSignals) public view returns (bool) {
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
                
                g1_mulAccC(_pVk, IC53x, IC53y, calldataload(add(pubSignals, 1664)))
                
                g1_mulAccC(_pVk, IC54x, IC54y, calldataload(add(pubSignals, 1696)))
                
                g1_mulAccC(_pVk, IC55x, IC55y, calldataload(add(pubSignals, 1728)))
                
                g1_mulAccC(_pVk, IC56x, IC56y, calldataload(add(pubSignals, 1760)))
                

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
            
            checkField(calldataload(add(_pubSignals, 1664)))
            
            checkField(calldataload(add(_pubSignals, 1696)))
            
            checkField(calldataload(add(_pubSignals, 1728)))
            
            checkField(calldataload(add(_pubSignals, 1760)))
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
