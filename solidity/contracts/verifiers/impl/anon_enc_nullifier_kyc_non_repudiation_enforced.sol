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

contract Verifier_AnonEncNullifierKycNonRepudiationEnforced {
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

    
    uint256 constant IC0x = 18457128877623345141461891410177837217367757273540721754099487466478922746660;
    uint256 constant IC0y = 10527912119825000840518533389149127757895035841780493123861944861444911874355;
    
    uint256 constant IC1x = 4473062312739300965526549389921628971892747350976119910295390515120296517626;
    uint256 constant IC1y = 2416849567433750847745488098727650310015521796364089126451783391006610065918;
    
    uint256 constant IC2x = 8122115199755934653836433870254606940757883723697086588212179656841777515366;
    uint256 constant IC2y = 18288010429900330390385229179182728387634601941858449632626000238239950122295;
    
    uint256 constant IC3x = 16704196085601648105921484456619780474170887772941121402836257287391846324807;
    uint256 constant IC3y = 15061527868202540931009992108140219804568479246364676228815955850796128557796;
    
    uint256 constant IC4x = 12042715530392042689984533752481511956655895849499925743307171546704628623403;
    uint256 constant IC4y = 2150386966930043569969687270197813208841326775350568595166516924524618686682;
    
    uint256 constant IC5x = 6901573853503052139813221615106100167771121315434943520273122401074308228018;
    uint256 constant IC5y = 508836781556053700358968432780807015122911388802292622041188102632881056718;
    
    uint256 constant IC6x = 18630086453973867832080956859198440750665349602446617401715865464789545137222;
    uint256 constant IC6y = 4341831433098844067362955414430099157983863865390497009405766975818208329077;
    
    uint256 constant IC7x = 5782799232246231654829691122726548607660140545944290047645074423517142723245;
    uint256 constant IC7y = 12266246254194918871827334292918971932118438330429222006804772896606859119153;
    
    uint256 constant IC8x = 17173339261168771276055415422369214778927365062108859971841178193008787353340;
    uint256 constant IC8y = 16936490200446900567351213491354608380548703715694519596079338346919757906937;
    
    uint256 constant IC9x = 19429323427790805317929584119058479795760328431571394287150860538747679553540;
    uint256 constant IC9y = 19361456249035336472339263640909197721253488074593893820411436089518667047861;
    
    uint256 constant IC10x = 16492086893087316686508368148717917152041390798371335537245402726318530147802;
    uint256 constant IC10y = 2832479499244699636966417300730155200145643395846641309963108098233065043557;
    
    uint256 constant IC11x = 16041307680197448440613604751534633999964329502771285287850854627114179363471;
    uint256 constant IC11y = 16337159798249785700019126141784166369483765446716989133287275495893332819506;
    
    uint256 constant IC12x = 1574700190609098108594525850984489019121292980877385376925971766292375716384;
    uint256 constant IC12y = 2178884588922075114240957104839339723563107063284232631329773952374867204492;
    
    uint256 constant IC13x = 7618319042960158955885644430797987273128419458317784263413782570168158563744;
    uint256 constant IC13y = 10362878388213159499177860231863629356651035707448658256107879419933159171973;
    
    uint256 constant IC14x = 4052593774975902824006275680701966335217355043428276733147878991216908989109;
    uint256 constant IC14y = 1606824893174478899112647980619019171737513857357578322656834944506259913652;
    
    uint256 constant IC15x = 2468067565745623664970488836969487127630179781247762924227261983527662805553;
    uint256 constant IC15y = 16152710362899963710482960675592054309832670492910492204309113990910302865566;
    
    uint256 constant IC16x = 3688390964725345327702775041851754198923726953948780700743212683107650348009;
    uint256 constant IC16y = 18332169682620676150712805492795471719438434196201517915614789180933917923196;
    
    uint256 constant IC17x = 14843068292231701781862427983781635052827637816601450375752616951101842008230;
    uint256 constant IC17y = 7206371949477031381157585639598372614970132937685933487912758111989414061042;
    
    uint256 constant IC18x = 18085056501727356807601113511934718069474753328655210935119801022793239444094;
    uint256 constant IC18y = 11420521912660738480171681112290024775719122685109137225583188435832107422720;
    
    uint256 constant IC19x = 20416883592043593052251093760089003387983581511870727310892825932742374699358;
    uint256 constant IC19y = 13521984718560776403711562517537116312658606982486194284242777648673622478340;
    
    uint256 constant IC20x = 13180204059846819885521483672212516371111911095612450180109516065777721568256;
    uint256 constant IC20y = 10306580189967371722559707209788937978485297378622545660576800806641914909841;
    
    uint256 constant IC21x = 4647611562290556387814296507083238651734587220676507655275160068267239623633;
    uint256 constant IC21y = 9810048250962432676022434700293560080183625292784576827853891163235301591674;
    
    uint256 constant IC22x = 14975988890652758774792625848896670802271038291959196433743368132041038478622;
    uint256 constant IC22y = 12276901720053829904697667877378608691176997915635621379027453224802287266743;
    
    uint256 constant IC23x = 14309333657683101742514232181104850346551156939933253183428205916207660715398;
    uint256 constant IC23y = 19349722722735293180270547051743951235096849701764610178630275222493560331045;
    
    uint256 constant IC24x = 17293076926184146145824848624885438935304701293131062657802893512424713264322;
    uint256 constant IC24y = 19699304864236181677930318799688990358286873045491909104274132956536244018605;
    
    uint256 constant IC25x = 15540062926805137054984798731826142469792368880922402249942565938088428370374;
    uint256 constant IC25y = 5237861925558725026698615757213145823996240024953394378608698314431692727501;
    
    uint256 constant IC26x = 10171327023550915421860353407709806712749223969877821191644918324380248122883;
    uint256 constant IC26y = 6380992311768925715508744455093702065165274706455257741565888796164098908658;
    
    uint256 constant IC27x = 3056642349059372456006965621434833816599428029307514484113414445469490332753;
    uint256 constant IC27y = 18320749248266114461730748568210384629766196411076834365083081594901736792283;
    
    uint256 constant IC28x = 2985424574869179985881133361516173816261582394707226692432419394784285352296;
    uint256 constant IC28y = 10440443235642914807740693647110026787240290680418806990573291301466547116561;
    
    uint256 constant IC29x = 18932210790513961842298843234227776051220970384665080907967761277338482213840;
    uint256 constant IC29y = 13703253739263538405504142495693983574451159316932046551775008655006773482104;
    
    uint256 constant IC30x = 15893938138012778488717251095917253669853917205930960610363070612387339908633;
    uint256 constant IC30y = 13821174683472025408515465597187769468196093006321993396446251092071366533370;
    
    uint256 constant IC31x = 4052041354669302414428860535190170670119723320570913110293750209131524514104;
    uint256 constant IC31y = 13185635249228206403310076203085487559555821975864137127454546695366372315031;
    
    uint256 constant IC32x = 5209593734316136177895529829013915909111338909398615315958936895674244452483;
    uint256 constant IC32y = 12429894998446479711194155659236218072641408273367547365891295002283954930844;
    
    uint256 constant IC33x = 3270762279102763918744800446254561912187475140798737524399326890782668179397;
    uint256 constant IC33y = 6989904955068175472785084043648745119729556779080201052449730253574210076230;
    
    uint256 constant IC34x = 3359985258910148330742939787482560562061869814794932225898461082508841365293;
    uint256 constant IC34y = 17190636927679329082178919339986588784493090869496536566380272281378050509482;
    
    uint256 constant IC35x = 17990383834971043955606723656936680151163820307565599752855845696729176584814;
    uint256 constant IC35y = 21246752262838474821564389101810121093131696323739433672386174393072077893179;
    
    uint256 constant IC36x = 10536304239726159717794866121255602061018575953313155230622818936372431305774;
    uint256 constant IC36y = 6894064837638443498318427647895209035279685122830275561053895725736934964009;
    
    uint256 constant IC37x = 11541197826199019150709880213790101252672790686343355393504583689432138564206;
    uint256 constant IC37y = 20338200064716688758187057745677520016233586500962239061238937101034249950859;
    
    uint256 constant IC38x = 9205918300491733196878733171453099771975031792190822120397854372234588421898;
    uint256 constant IC38y = 8466378586624568493408160098508400627658701303108278937566514687593829613545;
    
    uint256 constant IC39x = 4289589324804922837012708179775291971143919857045520705527881155037898680069;
    uint256 constant IC39y = 18093504465183301105866055700326515103001915869678370482882029731272378016969;
    
    uint256 constant IC40x = 18580161107414188784172428935513750622405190556892701910428917577069637443285;
    uint256 constant IC40y = 3103767106739567269794631047327949820242947679018320762269479407195262489443;
    
    uint256 constant IC41x = 4810559828290616575487313738593760155205539370557847444854963460182541223876;
    uint256 constant IC41y = 5760368414074087696665166337306722344576945943087619169464118306094629915799;
    
    uint256 constant IC42x = 14927391583742297776617237549381333363230284583792608476261828828037347471495;
    uint256 constant IC42y = 13984444423279327509878512679900132350599028255270686112391060492933672607951;
    
    uint256 constant IC43x = 15516346959126783942076942807508597168230361047215142509545589072838016779883;
    uint256 constant IC43y = 10133032812673585650890921145859833777290112013912063602379908365769129394352;
    
    uint256 constant IC44x = 5738140553876007537841900312250460743225329916520377512614935139942567682805;
    uint256 constant IC44y = 20063393987450880955195569121301145105689624928408569356493832392495003810197;
    
    uint256 constant IC45x = 19157744173190553309829846979099657693469316666272310096113986475848825431243;
    uint256 constant IC45y = 8207459269820711479140226038124717526562456013526760466842629268289010410031;
    
    uint256 constant IC46x = 20245986168752374975883176312774175552383644771177799194212145123435579097062;
    uint256 constant IC46y = 5660263106179660123513798977989524612234875357615688056984682851237652442573;
    
    uint256 constant IC47x = 14855681762954306029951232570443970073046109874585799748860034316090487738766;
    uint256 constant IC47y = 8448937324322662760724682125199920823176192793880228604863478499202199258295;
    
    uint256 constant IC48x = 16232339365284604024855513971552442276731778080772837651576158808276421845666;
    uint256 constant IC48y = 17198023390288706524579933579973424071087569862808390942132651775653854883506;
    
    uint256 constant IC49x = 4023464649057417224846764513225921332965941462808735901433046416944746010170;
    uint256 constant IC49y = 1411178223296439064378876876512515217075958943355211636326998770237175869351;
    
    uint256 constant IC50x = 7382665134432276805414642130312492989110470755000870700793547143851041719050;
    uint256 constant IC50y = 11229277127663377901105058987341095917978082839677968088453864808431246627557;
    
    uint256 constant IC51x = 16904418286660175690512049828316505280936923255748736787261305585428072311423;
    uint256 constant IC51y = 20647223372447410012913240997973577591279512771091161021433312027439254474293;
    
    uint256 constant IC52x = 3284328208396483803547501114585526644999059317369623228104448729380164772815;
    uint256 constant IC52y = 21182435351633127642675123964432288444361774786974815099706542769823328422975;
    
    uint256 constant IC53x = 16407008696647794452057105520049531687167514841206900597142468341420847075670;
    uint256 constant IC53y = 4767921736829156897490813195175361373521244512680612000262659835662171733300;
    
    uint256 constant IC54x = 13099302470060535256457211487930550365361852818804547158785092369433215526410;
    uint256 constant IC54y = 19450868461829760998424914250280765018672087086747643667912986641158067447721;
    
    uint256 constant IC55x = 4504376703921871766635613905133069486534967041613272578527786601501381327869;
    uint256 constant IC55y = 4208975013697549882807212844846734632212528107927441047404992311851725926989;
    
    uint256 constant IC56x = 10673813451825646861038816003092857367006043623467482967512583729658335497142;
    uint256 constant IC56y = 13384630776075403526967037820093448869644323596348777231250136478137149635527;
    
    uint256 constant IC57x = 11213377807069537924591283972356668814380828834839339595356891562498645558286;
    uint256 constant IC57y = 6812117598799254954753193324739474772066604837743029772537507441903347112749;
    
    uint256 constant IC58x = 9557478402332034756059512214015032019434818427323898187133913254984565766091;
    uint256 constant IC58y = 1402960805031588616448234438422173520379068174626663942731634656595754781784;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[58] calldata _pubSignals) public view returns (bool) {
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
                
                g1_mulAccC(_pVk, IC57x, IC57y, calldataload(add(pubSignals, 1792)))
                
                g1_mulAccC(_pVk, IC58x, IC58y, calldataload(add(pubSignals, 1824)))
                

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
            
            checkField(calldataload(add(_pubSignals, 1792)))
            
            checkField(calldataload(add(_pubSignals, 1824)))
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
