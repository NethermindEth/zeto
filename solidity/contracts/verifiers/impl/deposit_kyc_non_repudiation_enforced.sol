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

    
    uint256 constant IC0x = 18296952142532153462633874800121821039850921425459838271679152374017188056732;
    uint256 constant IC0y = 254578729704322733377063474597630301921329599763765008806317100776820020112;
    
    uint256 constant IC1x = 8467954261768250794001099035648459144005367226493597319810445266652867149672;
    uint256 constant IC1y = 726885319573648963484484075233427157256190687623184077828371223040102607481;
    
    uint256 constant IC2x = 8538184957339601761829725882734933688108264448323454911929015576902111532930;
    uint256 constant IC2y = 16306153825271845496159348552505330981406733331094581232145567101049995891008;
    
    uint256 constant IC3x = 14120393651278508183609415175146987595258553965033630515833077175400007482953;
    uint256 constant IC3y = 8978855421709595743427256340525514117198282799601205151381552005515238108133;
    
    uint256 constant IC4x = 8040505268019283679670264942552805922488140811708823606665634062859739814000;
    uint256 constant IC4y = 16151959078976648520518294573004663326246512808838250052365218689140207621712;
    
    uint256 constant IC5x = 14046433727064920751230329849280762885769969947212626247252849001403088980350;
    uint256 constant IC5y = 18948151955314975952118926250493301033483331286777940768190859909707076538519;
    
    uint256 constant IC6x = 12325173236810574191318481217058528401233129635820474354936751642841015625452;
    uint256 constant IC6y = 2481613567013500659439705883304604032488494207857194018832496688262124921354;
    
    uint256 constant IC7x = 13867464423195120057033055309775023527205917706999725412913201887508253944461;
    uint256 constant IC7y = 16966428810660298872267954191849567275684615570714523409972110277508192586262;
    
    uint256 constant IC8x = 2952590818108250053345213962918303507353065441917492444915771897897484193264;
    uint256 constant IC8y = 9669904012211841779528354877847856727768109769899098613162686725757957463512;
    
    uint256 constant IC9x = 15252281355713666398339778836760562098270797397463324374253890214316129550952;
    uint256 constant IC9y = 11946482687172887931603583673399478864759454218574179204896409736012898989372;
    
    uint256 constant IC10x = 8813688839770876841627424965801691002794668474729500831722520880398815100950;
    uint256 constant IC10y = 13139631645479786588731812740562542867331822953390112498245457834713325771200;
    
    uint256 constant IC11x = 10902451638651140258060484856992929384519467422419257837359267747814477856385;
    uint256 constant IC11y = 17268968015518519246575667575965395167258850204534272323745960328617056457587;
    
    uint256 constant IC12x = 19410267029747349063061742633330029132572348888397940835441116596636166882664;
    uint256 constant IC12y = 13267453979776635147711088146078562055081300204433715054300077483649325808354;
    
    uint256 constant IC13x = 10219911812296675492732520325249627595321057884695897647498823074565736871896;
    uint256 constant IC13y = 984595258323564051143768401536273478219698825462807420833489539779881500826;
    
    uint256 constant IC14x = 16985728181719147118099277234475915934581503735527386880061880861766647748807;
    uint256 constant IC14y = 16190041482385852504873491715323547556418051162245124651231936379106205838248;
    
    uint256 constant IC15x = 2600645749095552685010171234703022273544588653424192387701568900653634827927;
    uint256 constant IC15y = 17197242188888140462663292443065185434835623399184524122663982846372901357947;
    
    uint256 constant IC16x = 2080777076515400377695069496186353394942368134576265750892070505991749899535;
    uint256 constant IC16y = 9998219706059330829318045297080413063280460178647682507505083549363962974333;
    
    uint256 constant IC17x = 251439346779246223197785060164093987653203525562793579937421570480939239575;
    uint256 constant IC17y = 5291375358528636712745335325023944499135408595781317120271046118939874560167;
    
    uint256 constant IC18x = 4429882091294585210666872668190317591219732537318937000434001494474364355286;
    uint256 constant IC18y = 6085074001338778094890719269500337258034117448347672329299254582847429391895;
    
    uint256 constant IC19x = 16893594342097045220615877650694197972527363880733664662518633567722188108016;
    uint256 constant IC19y = 4285313319117220926481881210273975462617864769578612254602389379680467440820;
    
    uint256 constant IC20x = 10337760235163017445126848652006318820844588903685700442578843711512428401110;
    uint256 constant IC20y = 18650258392517983166956261015492501049040556444865524143470970375697283098351;
    
    uint256 constant IC21x = 7445544623236543757210360642074017656169978340338937422647264286927059286429;
    uint256 constant IC21y = 6327247174266317759611423952523862766042859388941875070043840694823325495031;
    
    uint256 constant IC22x = 21225326367566248307559823752365724149760644974952017777449532398335328821420;
    uint256 constant IC22y = 17298639929497508812236251812682178741809798894019898578554872377223818781762;
    
    uint256 constant IC23x = 20066655322431612545760251478937125222364477226236755921915959187733706602828;
    uint256 constant IC23y = 1066889475937488682411899091896259259658868051991443263290828373690537836642;
    
    uint256 constant IC24x = 18072367997272341973599123596538313075156300714179540976711238902487007613035;
    uint256 constant IC24y = 17972363946424647657825113664465201196532044947854897917590327286879372651737;
    
    uint256 constant IC25x = 12661255009589404377437488255023389802026656900644634276947304207755860994776;
    uint256 constant IC25y = 13058155334029897408278473440932817175228959193757683091217814848010036178946;
    
    uint256 constant IC26x = 13975516150657302224927833615534625556259433868622643527931752405096321146613;
    uint256 constant IC26y = 9399917326851315979905613374567222279391474705892292825526496689650683847971;
    
    uint256 constant IC27x = 8834307962247269063977282427813238098169036526130215581715313650770864171698;
    uint256 constant IC27y = 19680714222939196661323709059816294689343672230246898039188803589126601781389;
    
    uint256 constant IC28x = 1062123228962417575120273922105268399941000430123852171952868572900572206018;
    uint256 constant IC28y = 14684424245888155306284641529770562911661401970909262273706686485309075921609;
    
    uint256 constant IC29x = 4672336270065213680837153082184562693870327975363382992810299721506347159542;
    uint256 constant IC29y = 16921945967375993932406592024705789301299594632282277708641174175915201909460;
    
    uint256 constant IC30x = 1055594069309379961848556147640760864667554239580205957453526573927278662913;
    uint256 constant IC30y = 15177284924529664049124739544636801081129149895480046431768246550087302240518;
    
    uint256 constant IC31x = 14066939810929338421423417137722867296436451744531646412389137668326467181926;
    uint256 constant IC31y = 20893260302092901056207272706702362784715216947766102002676645326745113014225;
    
    uint256 constant IC32x = 10101279227779506599686125238658684061276912122854888983806237058265974744529;
    uint256 constant IC32y = 8479335501510257821976899329090418159623933047875619988603773502866809450362;
    
    uint256 constant IC33x = 10644442085695521034374578227198691572239876967227725077047502337307749953042;
    uint256 constant IC33y = 4531660432243068552004033523549402368787413403261676458907840026167826956151;
    
    uint256 constant IC34x = 10219536582083474267581509127440262440722321065521429078347322931787469709316;
    uint256 constant IC34y = 21792543560394206159450514685590114980185341939290170919305033324666041989744;
    
    uint256 constant IC35x = 13739701614136694829381857239097650430482538190234478991859481138434022987381;
    uint256 constant IC35y = 33112641771352551692577648989162760268681648418111490649212991761408146083;
    
    uint256 constant IC36x = 4082994579056658787567658683221469066586065956202121545840638288102145664127;
    uint256 constant IC36y = 18675897260266821341865975359042145395119642622623726802472891317026159887740;
    
    uint256 constant IC37x = 4037437089454900325445130043584665152362729802485377694774917118293350686919;
    uint256 constant IC37y = 11951852736459153781663599355648826191232469656487680980068172670332850064680;
    
    uint256 constant IC38x = 8595050669544068309560147240164400895558749981512632702202127505129176455338;
    uint256 constant IC38y = 2477117030822286653196844791710313198034808812097686908941655394990738348079;
    
    uint256 constant IC39x = 5240343804626036068547502318247479983066891842010571385940523044577023257894;
    uint256 constant IC39y = 20386099032416051194190739341882693925986712683481651774653503502064004884438;
    
    uint256 constant IC40x = 15075731780017996987478256177661677152146826687156140474150354418308379522023;
    uint256 constant IC40y = 12829680966122420601923382281577768143267435307632452037188425615511164755217;
    
    uint256 constant IC41x = 16073728201148192709160209074354596839730402944900082759992927373565882615108;
    uint256 constant IC41y = 8109336663012123171010703638258723138811150942938181287303635575691001154477;
    
    uint256 constant IC42x = 3101889125554948919914042689123646377193259964146644158474288913733265534365;
    uint256 constant IC42y = 2105504272964227572432307059180096516065662881009472644318873259644477131516;
    
    uint256 constant IC43x = 3901288849640442318261970118235243068891457005254501348686148797891057577596;
    uint256 constant IC43y = 18089147700948488362533912807495780017033468470908431909659484548237616210677;
    
    uint256 constant IC44x = 15596899984449872795101094576618893290892987760833810544904379071404486116689;
    uint256 constant IC44y = 18055676449690144017127610626404012635795695530587998324855858036212732121511;
    
    uint256 constant IC45x = 3291819577637479012072002764437516472001661725272164856508902467050645539708;
    uint256 constant IC45y = 3488632927954197429333369548502353590938253598057645736601999964224337724356;
    
    uint256 constant IC46x = 20243571321991995345701043241737043169818142909290979657179077663561264385449;
    uint256 constant IC46y = 19989305975643765590078468436174467152615466652223670974459806288329643392019;
    
    uint256 constant IC47x = 16888060626330994892761888969954610366614000323880525933352149986843824112609;
    uint256 constant IC47y = 10572987406598766066295350781502769168473886679840613126221354041327448304662;
    
    uint256 constant IC48x = 11852341214668346253704475423060234863273090039468525954065524099259629253013;
    uint256 constant IC48y = 17875046674765103746566642132932656257177199112708385358863369334961441305215;
    
    uint256 constant IC49x = 21502620470854177916760747998700170830002833816039223956708685594119422112354;
    uint256 constant IC49y = 16689693006678550896959931086268441595327424100678252464274302133538027787430;
    
    uint256 constant IC50x = 4472437761610531437384665159743624936890262971120250441637110927623532373097;
    uint256 constant IC50y = 8402613508777119404872642305066399997049174920129212884320491444195493759291;
    
    uint256 constant IC51x = 9246635575362279085764831668216825655782628697285163275060565869621491138161;
    uint256 constant IC51y = 5975670475569047677302314533381007685784073725090787016560023154898071052949;
    
    uint256 constant IC52x = 10612778740178723809605022137851691142040277166041540976382394280365097943129;
    uint256 constant IC52y = 15594813136463766143767419023589769425808879205201648943380817700014619334928;
    
 
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
