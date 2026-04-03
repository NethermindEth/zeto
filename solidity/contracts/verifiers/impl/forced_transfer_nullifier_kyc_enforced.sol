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

    
    uint256 constant IC0x = 7662703036356789051895848482375398578741451034531046187352504129435848365530;
    uint256 constant IC0y = 11441862892929340844032925403846879883851966940041751977462397544637512505669;
    
    uint256 constant IC1x = 4418930065096286366326408174389676120104952696084996187702433711229222362406;
    uint256 constant IC1y = 7837103860724291697476768442626615205536601704698084850158756809864473274686;
    
    uint256 constant IC2x = 14566504866256948118928807076702478520193037146915741904011905055039872752500;
    uint256 constant IC2y = 13213682847349585844752877475133456277121700237163114347587007671354792646731;
    
    uint256 constant IC3x = 9385284192198244992188158335276020232591684521773642303721283616469794149348;
    uint256 constant IC3y = 21033090346075268312168391036040722238943742573183458311291468241270575283530;
    
    uint256 constant IC4x = 17014464181795486337316740110512401847079194549508723679036678785451166407149;
    uint256 constant IC4y = 13362357870179640974491821802136768468193468518908807178415155846004781218690;
    
    uint256 constant IC5x = 19088049541637763064200422309007794747404995898127625122539544691937086468975;
    uint256 constant IC5y = 10927679815344447894388809464754504361710979865883195501495052072462894746956;
    
    uint256 constant IC6x = 19229636638228008180347497288229219656496812578386146232852961853119134932190;
    uint256 constant IC6y = 5983785972603629088003228609611779743455785380808808621780521724275427183328;
    
    uint256 constant IC7x = 20068258276075268919663084671697810665930172499235908222772416395707545315289;
    uint256 constant IC7y = 5912504703975394157467566605325638276832865249044956781422071873300911259260;
    
    uint256 constant IC8x = 15335419922131625965347272037786573008462578299225825023567843463547643564248;
    uint256 constant IC8y = 12896093825860890297015121912648005382802617638447077470448633015211079150721;
    
    uint256 constant IC9x = 21120103762798800807137600490502402039194529127743823206546240731694919672133;
    uint256 constant IC9y = 1503894121541656672768364556557240268638483167550565259301192616445514703551;
    
    uint256 constant IC10x = 10595305130139436532868136812966599054140689353576447717267129564881042749818;
    uint256 constant IC10y = 15409063217041301772546309375178721992621308361088382282246722655316526197820;
    
    uint256 constant IC11x = 14844867787312271487268172682520566890842647973931366156114308726864875524534;
    uint256 constant IC11y = 1585390320378145404059696283791270385078920476736769810649346238613465584649;
    
    uint256 constant IC12x = 21267406091038843801034291405164336673038969615921584325004803117265488795941;
    uint256 constant IC12y = 16369833456635666212343449446984291482603244170781042476221822483103825171443;
    
    uint256 constant IC13x = 6881514011408254048000695620864170952332085792187980580464349724889294394480;
    uint256 constant IC13y = 6308577548471192695670582659914082836225482279661202691365646463680215153842;
    
    uint256 constant IC14x = 9242960502920121489750524042330122595878172420555128241221318659182999454424;
    uint256 constant IC14y = 14636953083375290711122362933442132033386242536275328130691486592084014807876;
    
    uint256 constant IC15x = 14737591610092466511520463220777999615181291173662027516988200729571041277780;
    uint256 constant IC15y = 9934970748507278345641283375835599072641322896945956004290456633853212678113;
    
    uint256 constant IC16x = 18350911082040667578575031049925473527145395744617366973729536977570625841590;
    uint256 constant IC16y = 14597561032893840071403850237721800312977934755755950845006652939815603414137;
    
    uint256 constant IC17x = 9339563558165831816446894957782539347741580838022030300659044436153353451064;
    uint256 constant IC17y = 4896083489779244315951136168006952430668938809689200720478879183081940065025;
    
    uint256 constant IC18x = 9178366051229546540507574573674119271680321674075972233828238251925611148589;
    uint256 constant IC18y = 6642026264330113335843843597550099782272700469345932291927222608558139598779;
    
    uint256 constant IC19x = 17988022463656396461188360690754220111855545227238802118437887306550157984717;
    uint256 constant IC19y = 14102242035539600776912329173024697242453444790870518544967925514532346179233;
    
    uint256 constant IC20x = 12759119604513588550253398442031873359482442503385705015009489987093071578309;
    uint256 constant IC20y = 309266755689943879923206310933584939657729580626983072383507375605365323233;
    
    uint256 constant IC21x = 16304127227454730228117332349367220688634516436283317490123050731582766541904;
    uint256 constant IC21y = 5976439298835580148361818587408539565920312342210340804456025220997799366569;
    
    uint256 constant IC22x = 21604110371502413556343863325378116900572858525044915146102100569510243787106;
    uint256 constant IC22y = 5296649101791664576670830094800879867134761263124483728262834412254132955950;
    
    uint256 constant IC23x = 8342139063355097657546537078285573002515538301883748628997829030168317146208;
    uint256 constant IC23y = 13979883928428288173586229124442345861842701767656575884483150391449622862443;
    
    uint256 constant IC24x = 21706228432949722923751752885616322587391061597181622228716011340184758042331;
    uint256 constant IC24y = 8858204934533892013660047442400793184161047907083296420137734507452738896442;
    
    uint256 constant IC25x = 14934103357639093986245098280268427899139562523463395300346788082522825577964;
    uint256 constant IC25y = 1352981463410646412833093628936371328714124840524039773188316698720314325299;
    
    uint256 constant IC26x = 1393943658414225200043959739318302361537308855438156771207385911718253056473;
    uint256 constant IC26y = 17734308524072972830880686093464474473635026838605244172881964141112191014906;
    
    uint256 constant IC27x = 2659114942717824432322686216867616673742289863762007701051728525131478526689;
    uint256 constant IC27y = 11082395092504577673260541821864039233385854539433585897683265428548041867201;
    
    uint256 constant IC28x = 526952527418309259487147269303429146446298952204875721435906937844558635767;
    uint256 constant IC28y = 13458335984207495578511029256100594547129315278341363791150459088498674674231;
    
    uint256 constant IC29x = 569759943764189546257170958548046495960348896542259849072841434927622267549;
    uint256 constant IC29y = 8127210524807043661862072706983424517249207613880933281572695449440351346229;
    
    uint256 constant IC30x = 19117337053485866458577038004241683870096402430048472151413005661314315156204;
    uint256 constant IC30y = 7303559500595360214808305895844176671755616463602179058690911384659154697551;
    
    uint256 constant IC31x = 5515603342978669632017116422823100230927470610451009892684370313003543023018;
    uint256 constant IC31y = 17979319513141342993667204470726560117689631400052695779155445052762064221593;
    
    uint256 constant IC32x = 9966663398178728294373484070209949049307562553746220129170729344818660793205;
    uint256 constant IC32y = 5897327100008714485624352708834218688689418172538907896724340529748614834655;
    
    uint256 constant IC33x = 8610171820786774648551297638920412681039249586205175555161143127130082042823;
    uint256 constant IC33y = 17913052462473074734845927983671969138401539113407337314357877927499421153616;
    
    uint256 constant IC34x = 11542587467526204311383351436489958377319153321935156122756074921700019782991;
    uint256 constant IC34y = 13876357129399781142629121863427694654643388179088282003960091307324903529242;
    
    uint256 constant IC35x = 17795654693778698261266921196931755314318955725107513277647910349649320015864;
    uint256 constant IC35y = 12435903301044251947891549900193076945336909107832965920094667618366019301605;
    
    uint256 constant IC36x = 13140392383982445550643339785023052383527871205268830972142907326362384980762;
    uint256 constant IC36y = 18201469193187022953411627682149261308399386781304684837675395722683933113725;
    
    uint256 constant IC37x = 21398233236436453298507469603460351494592905136734413311403256397137293593583;
    uint256 constant IC37y = 8970944944024649634961615665107630685426340808642238824927577724714077221173;
    
    uint256 constant IC38x = 6761981665465070330112040665929185646005030136696229958218738657267804914223;
    uint256 constant IC38y = 3491973341324412478231309405880320422151289473529666662776848982952248227229;
    
    uint256 constant IC39x = 4297807788419604983445323741716115959629875200217855098134307993048287547915;
    uint256 constant IC39y = 20630944734394206426118231619012935658313746246913257180507504407747702653530;
    
    uint256 constant IC40x = 8352528684153505769246892101336295933445487362831932725778355486232878553452;
    uint256 constant IC40y = 11782392094000171134275275732549147346712577999704589693652751559315286842;
    
    uint256 constant IC41x = 11393894466939734027412169914511691736521086265856564803471461090001399856103;
    uint256 constant IC41y = 7370408108160762993895785847208560349932408228315943213791342825858293921327;
    
    uint256 constant IC42x = 9275379930299438357482696730411664837906892899670011394973691087857505548930;
    uint256 constant IC42y = 15649521345068303713776266316304932791666517836847962031643832213649448240582;
    
    uint256 constant IC43x = 6775865143210216654588408545197780596771056290146449539505244570637229624076;
    uint256 constant IC43y = 10845022839838956758979099606733060938461896066982312727870069182588871491196;
    
    uint256 constant IC44x = 8822405566900733997478601006914159972065570255857564812909561610788880266234;
    uint256 constant IC44y = 5649739097369178785806806510446698569399164830513640228513299298968340850583;
    
    uint256 constant IC45x = 11092939748484721408876025531331776502926510607971863502703834212298680139553;
    uint256 constant IC45y = 11249486918603075789598806671344661287167249342332097159617895655501951333563;
    
    uint256 constant IC46x = 3722355530334956571256549790486671321945666194005109239883797545751477336254;
    uint256 constant IC46y = 7110618449778640751513709642412036911693319220679244056804084276898011048801;
    
    uint256 constant IC47x = 15215469980802387880060442169544068393359552755088522089006162825708310250582;
    uint256 constant IC47y = 8478179101401776625731766723394824020768567862694816332265594466729509173049;
    
    uint256 constant IC48x = 10672751820083463079907311668000751095695761498586825948865751215771189796521;
    uint256 constant IC48y = 175807928619499987433335499763482419557893972854829130316440916210571764413;
    
    uint256 constant IC49x = 21174503465871297506316225336753786000751750652917858771742784510116091755260;
    uint256 constant IC49y = 8644325467382057555534543461288648715088074185644709670905014162175154003791;
    
    uint256 constant IC50x = 18048942896328473294741480098456664198443447946288618843153059635792053207270;
    uint256 constant IC50y = 3109999811114718038126351233844301189814184398989930434921438855609925053556;
    
    uint256 constant IC51x = 20479598079656157165740550879662697564367918856759167766218585558150861718055;
    uint256 constant IC51y = 3573692737303495776650039096680639551461267834253325116617806908867654413929;
    
    uint256 constant IC52x = 1478691773678592312322883801903425971051915306728397454095018343727366646766;
    uint256 constant IC52y = 21140355746386372026799612443118231354450868271757577683589940100470991116450;
    
    uint256 constant IC53x = 16280120620267955252584678624886954154984874684651463691507417282159600516480;
    uint256 constant IC53y = 2205216374377537569820740153235286545860167696546666160531378984232705008158;
    
    uint256 constant IC54x = 5787568212827987249387716396315027175578787111933106357174736668126817638191;
    uint256 constant IC54y = 3318503666146149496493413731916129644760300502357646851478561910827895548984;
    
    uint256 constant IC55x = 21332923347717206523585693066178527402578438511913237156797380567705351184256;
    uint256 constant IC55y = 3690483768796792298402500748613075568335488172029235697780602118480650524727;
    
    uint256 constant IC56x = 11125346372288240219840444833018828866196932367848523564917194086858672511265;
    uint256 constant IC56y = 3159589611275961926189880830922529584194798415287793797787676540014909369002;
    
 
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
