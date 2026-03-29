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

    
    uint256 constant IC0x = 315768329875812746139117749366309276721793310637076597413700600615993293858;
    uint256 constant IC0y = 3702474555374294174947538531819172763708923073647681644212870446187870800275;
    
    uint256 constant IC1x = 17898087430143504672286803457249163695696818366107334779675717164081238601974;
    uint256 constant IC1y = 523792445304133737077251433340773263256633415144117797602369387558095038196;
    
    uint256 constant IC2x = 4204491922163954636586368738884566868042024041702611284440136465608672186564;
    uint256 constant IC2y = 8618431524823578907958887228165984195694371483816577473482680192395593467952;
    
    uint256 constant IC3x = 15349230279436971017884666967704168529370756695895672029791514795705142848703;
    uint256 constant IC3y = 14206583849128050823683960994499811276912630008486570352555436098901213552467;
    
    uint256 constant IC4x = 10512144889803843018023005377306987637637327979190976074364504439868909361634;
    uint256 constant IC4y = 3106806979222197302273280415510460866144694490796247132529302025552840778876;
    
    uint256 constant IC5x = 17416480176068843108286080645566210998603613726719613420391747882878370842237;
    uint256 constant IC5y = 14519453938969942576277270132246429374713969242996760264594553625466906853726;
    
    uint256 constant IC6x = 6114561473737546803197281264423364455820583494134869345314375115119862229976;
    uint256 constant IC6y = 16032898279198778034869468490681789737381870247046939860870846609413872134935;
    
    uint256 constant IC7x = 6082521059396587734635936023338212668020033916270527453226011093050357635931;
    uint256 constant IC7y = 4226022663719447697869883343184269312816890074473917284963954246261221589440;
    
    uint256 constant IC8x = 19884116782141930241198586082152513944362535496267006651462249137424746866311;
    uint256 constant IC8y = 15242825814397512589232050834818216611622977268604052150756611400986015420274;
    
    uint256 constant IC9x = 6127840612688817993942740563265818801926934911064564906061425309817227467029;
    uint256 constant IC9y = 3893869762877169783232277082837853691189546510517371113721555030965671126825;
    
    uint256 constant IC10x = 2148329340477127667547122885450543175008824563819518477570243143962384028005;
    uint256 constant IC10y = 2110026252852788325457995612639769862686064885524609457058066986186176470908;
    
    uint256 constant IC11x = 10755401975228891165249960082836445646935231568052414783679420118051975686914;
    uint256 constant IC11y = 11523590790238370455908714360090680723765808849922295674080073211376114769105;
    
    uint256 constant IC12x = 20637405614812517029419674061795707492283841272551929831795035022968932071859;
    uint256 constant IC12y = 19166770828259739344732487463253969383882993730091111172597038507479079252645;
    
    uint256 constant IC13x = 9377330398043230232862224239365376438795827933922468242847482960410007681963;
    uint256 constant IC13y = 6666371717455130078025609088717519946739156558690378911973519065044582224896;
    
    uint256 constant IC14x = 10179213393193700858209184555941773830359122790178339985784442673956102750130;
    uint256 constant IC14y = 1921007550746271404739257759345535205830120049192243026263360854098818034528;
    
    uint256 constant IC15x = 9395132579769092778550130842335078747447644352086975649239593738378511518131;
    uint256 constant IC15y = 18491484856302884801579418952369996443296907244969536377203163364541515895703;
    
    uint256 constant IC16x = 21128904583753416942670531903921750379618825575747646522847080680378224642852;
    uint256 constant IC16y = 3134262611995789887756843052968853647270593173533437434398890610452647807732;
    
    uint256 constant IC17x = 13727051881588997893312009878931619760389897515539706658417595684374818621203;
    uint256 constant IC17y = 8931504491014109605591223149002033362300603379507967468173330354002158190931;
    
    uint256 constant IC18x = 10202499625239557802940499501750178619132656373747729503514058421219460262446;
    uint256 constant IC18y = 11438924487259955939401674354496111013335654889942525270767293851124946302727;
    
    uint256 constant IC19x = 1206997474391953227051880996526929009189378510457723652904197125450648300704;
    uint256 constant IC19y = 11453001574282050106841205719305190841477680750946398947978321211209420694181;
    
    uint256 constant IC20x = 17044801550253608301553340684481984693006839712147250894899563279158290764292;
    uint256 constant IC20y = 6693594585575127115055341189378914038014187808945154054046946474556517530642;
    
    uint256 constant IC21x = 20464315768772283522693005992831051725117027686359674801766755773765701583228;
    uint256 constant IC21y = 13835862117197413744618022304383168286880524910070117727789548913114041278091;
    
    uint256 constant IC22x = 21572390317594974540230618278298317939955507190167236760899882829038353245037;
    uint256 constant IC22y = 16148519202019254234991327439272969042330005336948358196063591013230873784977;
    
    uint256 constant IC23x = 21850781280451821961734129896203378316380933932977959436001986234390039039698;
    uint256 constant IC23y = 15350990417072503955055072647570740201978603057692689504105540682160767753375;
    
    uint256 constant IC24x = 13637663655823508911452812738435336909219381756691282790499090993130689727219;
    uint256 constant IC24y = 14992640617081236151324186996391106714009220607567937514555032153533916907505;
    
    uint256 constant IC25x = 11760051406206093375883044844528391955562448930993127669872550842643735135404;
    uint256 constant IC25y = 2588406667717354757973682868521236566148126046203771129277496232031590789706;
    
    uint256 constant IC26x = 13205477762804493985607106742827504322814343946245701521451024462233801519457;
    uint256 constant IC26y = 9857260045310185854754505656324117025487336526109307722028857221480671172501;
    
    uint256 constant IC27x = 19619708921008512312182840532605720672009306596083379675501266831420597561462;
    uint256 constant IC27y = 299238559052419236460236172703138939375884895315671239485072151124442494191;
    
    uint256 constant IC28x = 13307798477724996695318696240024293004735011228496991778625007060482532779800;
    uint256 constant IC28y = 11335885206938109103933537049161876572045803613794809536503060032030145698357;
    
    uint256 constant IC29x = 15664357109496965290143822004912910379520238209690049906787660021014651621730;
    uint256 constant IC29y = 21186370496177798866061026004240628168336630009798485889641117896767789263330;
    
    uint256 constant IC30x = 7234493791619067175653627933677444669854073856688860362246906981503853228931;
    uint256 constant IC30y = 4859152065674539877303583885873706423149858319707841064694043079924637919068;
    
    uint256 constant IC31x = 14182978365231847188389106233860331496929810500563921118920210984558421836684;
    uint256 constant IC31y = 11143910024844092646731981126523228013559388313846841905437683744538651705779;
    
    uint256 constant IC32x = 19416842645868073960557559132491822860402688835615294178592235227526100665574;
    uint256 constant IC32y = 2484372720348916505101749910837599989774216411371613802011896514987673519517;
    
    uint256 constant IC33x = 1066068947099536413806360700881580996264250480833008518545362955347657885170;
    uint256 constant IC33y = 19930384220686030938515742937367251107116748569693078472136652432772018080533;
    
    uint256 constant IC34x = 4034569268886024669776630230809920131480742254084800417052028164386002976810;
    uint256 constant IC34y = 12135080576703864304681719040193560056525502767826517850953359231566459142453;
    
    uint256 constant IC35x = 14588379933842454076307076252772578672685404193644849970837418362231047713489;
    uint256 constant IC35y = 15423690638952228070871185324041175762254931589175217005295719355564543277823;
    
    uint256 constant IC36x = 17954573164435744936830706401299282520747656032065429226717742097306057366073;
    uint256 constant IC36y = 10461880044990827977303245923723428328359016183513445851203835812783678422984;
    
    uint256 constant IC37x = 15214612941201939783534459937829502895023704815929478158159985488144518491021;
    uint256 constant IC37y = 1587319957152224216265457807142331691865609504650997862479101952235181938443;
    
    uint256 constant IC38x = 17424506460534464632603753706877329837820479879636117267508668754699830579975;
    uint256 constant IC38y = 11250140967955270273217019386174660911148470617632875420447068576109969212699;
    
    uint256 constant IC39x = 20005625964930416809978775216232390353813501431480528966168648307821911779203;
    uint256 constant IC39y = 18958430962630649238724251827244801684290592282046870105918133200271878128300;
    
    uint256 constant IC40x = 7749890694368863323206539337892109918918650869412269577457646485681163347088;
    uint256 constant IC40y = 1837466069503877656241185022063519022749699087339097793397183863239869709820;
    
    uint256 constant IC41x = 6904404019331772493680241833846938785749977155056203042051793557345586265310;
    uint256 constant IC41y = 5341566134875537353015786508858615393633330472976230446759940385235893981519;
    
    uint256 constant IC42x = 908152716998219339016220697845976419222712791922440415559324036874282562396;
    uint256 constant IC42y = 18046299444583865169282782734608930120837602528525737470313611977757602320862;
    
    uint256 constant IC43x = 14042474320910730820104824027923028945920050657596966746673899704080650216313;
    uint256 constant IC43y = 17214335536671045128383565131153509069672164093823751923700395557137379510796;
    
    uint256 constant IC44x = 12534623869785005270535619384693834781226721965776440809428443729124375160001;
    uint256 constant IC44y = 20650645377045956196245706914585069225119180281967162586697111431011332322383;
    
    uint256 constant IC45x = 2300808563696070071803219846051044189185077493983938074777577653200725643500;
    uint256 constant IC45y = 12861808752277860336351317009075531106277276632492494982015785382655378957145;
    
    uint256 constant IC46x = 9790753700270450192905485373577519982676422110909598556348600975764716036592;
    uint256 constant IC46y = 14110174920746715317895504733906544368684537867140347280785392502238337466446;
    
    uint256 constant IC47x = 13311087765343057366666534095029694733975669393417725470291333725198428421788;
    uint256 constant IC47y = 9188046534324394880862133580529278404033358725217735537771980383115809647012;
    
    uint256 constant IC48x = 2961172774621055080574697397384898935979084779183003632576294682248129364614;
    uint256 constant IC48y = 3439217983878607016322025131109834280069495925240388471233603583870337665881;
    
    uint256 constant IC49x = 8755079532849203237404743566703472902281405982073180984494600143778671253388;
    uint256 constant IC49y = 13568302413660863607054406882255829210150471634817533721855630720799092266842;
    
    uint256 constant IC50x = 13077234879415104143327099042323206179885225576443150627911811443292582721744;
    uint256 constant IC50y = 1648203766321866070132627467244388150825511651826423979406801582926135357129;
    
 
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
