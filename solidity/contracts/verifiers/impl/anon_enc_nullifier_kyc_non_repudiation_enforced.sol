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

    
    uint256 constant IC0x = 21263404391686452685047210544286304162949670044480389132658547116802153849206;
    uint256 constant IC0y = 6715898545454646022910635243410011953669170273843598060722897793457675733103;
    
    uint256 constant IC1x = 15553227336656179242047955775741943910811842346855067219387479042185796299759;
    uint256 constant IC1y = 3306380299886001104888221551311818473466487376048952579685932133930389760175;
    
    uint256 constant IC2x = 6399521538627601792068746726698683232622803224259184669577245829497201518339;
    uint256 constant IC2y = 12349529168241157724214382513886828559752049564880900733447414681552153866219;
    
    uint256 constant IC3x = 15278986940689104662926222436193592312762473090838563008234662655189649732365;
    uint256 constant IC3y = 7657178241304892995254337149240844060868822333038978279107668584313269365970;
    
    uint256 constant IC4x = 8554319543586316600618269957926650686847492388955738267858298130062306616421;
    uint256 constant IC4y = 9557845597648812772389857544089830028064973180540361778297886666607459721638;
    
    uint256 constant IC5x = 8132795775686904486816251061923846401006990516418208935914309487928673854587;
    uint256 constant IC5y = 3883073471771100195665529480049962336121244455499341483477008769805150232731;
    
    uint256 constant IC6x = 5279790637469670418356361522971919047833419738264750421522090593861740681952;
    uint256 constant IC6y = 17826523776444914173113359153553514496712876326139039683108610722089320627770;
    
    uint256 constant IC7x = 5279865274200740401463646972238400909744618794995713410616841763328793817741;
    uint256 constant IC7y = 20045958974038963878067443481600045041435846422320798509710964600468256068966;
    
    uint256 constant IC8x = 4567967022398975084035784200993904445435133948693647924216803339285916257045;
    uint256 constant IC8y = 19939051366747092132120835213517608044124721446759640132806723507651235199319;
    
    uint256 constant IC9x = 21314657463511545777424441615483360200231791000948526431360585438681751144151;
    uint256 constant IC9y = 1007014229093518271488246528679765284022124676436370955418489590315452878708;
    
    uint256 constant IC10x = 6308792656457761563496135154058016778687753972470866173453333183743224250763;
    uint256 constant IC10y = 3400084071651120411990690706406416293282971853993393493097834470370247385438;
    
    uint256 constant IC11x = 1000617969664195824319005613146002899210857759971956276311312254119351774892;
    uint256 constant IC11y = 8002889986294560136045572717334998151929124130407247622469033329340982409675;
    
    uint256 constant IC12x = 18626296394521320246863627750086969619416024940351341240426772988662536166916;
    uint256 constant IC12y = 15649182514908028034763926142498845343333020309866456139232847491137874543769;
    
    uint256 constant IC13x = 12168801813071019101696851964316994298831767031111023947664721553368304269493;
    uint256 constant IC13y = 8028430721423492709032252960505300669188425049244185304556881497366797577642;
    
    uint256 constant IC14x = 5692005096821935348638710326734977212339195721272844716401720295763084919987;
    uint256 constant IC14y = 5990424681219771753674479191910396978728604706344442381757612240905614742482;
    
    uint256 constant IC15x = 12121733990969710137712287590317105902349707856667250619074644051254764111143;
    uint256 constant IC15y = 11415581571809159405736983214790047303588637258185763661951063531210321393861;
    
    uint256 constant IC16x = 8692367832299874866079283856147105040815280950682073525843957283624165853750;
    uint256 constant IC16y = 18814094680839153220834330493429877640995314898023628636613045462895905554164;
    
    uint256 constant IC17x = 6378179364945251019114127528935258042261180669898283547503461513481976441595;
    uint256 constant IC17y = 20389449674994401072990265603023891490868084345041917937060265452967211750730;
    
    uint256 constant IC18x = 13930482783406923415999707742508267282238001044035610977445683809482228156485;
    uint256 constant IC18y = 9021593009708154594747344691024929346877465021062552774217255926970437864594;
    
    uint256 constant IC19x = 17079890501899757152642746141501458473571017631616649068012079625661602656536;
    uint256 constant IC19y = 3248526687608091394959076960787581166889591971197325839275372587748424452329;
    
    uint256 constant IC20x = 2780408301493617446825241600719156054643135332489775171645388460625730168178;
    uint256 constant IC20y = 4038700624995275507357566239062371383089528505977794185042459322055447938482;
    
    uint256 constant IC21x = 5183427392943003778947028467430950432838550198348076918706294112597956796146;
    uint256 constant IC21y = 20207265258059929288720072947363243833814286304393153728899358938658884599851;
    
    uint256 constant IC22x = 15019988559460617976119461062024169679385774998361686276887033258701681563454;
    uint256 constant IC22y = 678407437296468572941843136494616666843056610198213682149503667530050865691;
    
    uint256 constant IC23x = 6800517010200047326874411985638242607115796346421509619536049329699406076120;
    uint256 constant IC23y = 9263671577714917375386813371387980138937480875154319699590855201323333658163;
    
    uint256 constant IC24x = 562529808192911747020274085744871350344353475246883739294273786868004099743;
    uint256 constant IC24y = 17596025117868544677967891346417716243358785439855223969688561366341120469269;
    
    uint256 constant IC25x = 3603611645596572024463506975864026763968256612432658880124253129480675692315;
    uint256 constant IC25y = 10409526209483140242862706102578344259669006221001986763435261139694862679581;
    
    uint256 constant IC26x = 6041251684421790792737652066642348344308620747271770890876748831557802269505;
    uint256 constant IC26y = 17226305416316573291958971817457200041667481534181124821558845071416587367586;
    
    uint256 constant IC27x = 11641695142790529496607640495927649329035942578989797087912561068365659479815;
    uint256 constant IC27y = 20456363160139172887604456608945447218870198403750645371695121403596717634073;
    
    uint256 constant IC28x = 17224420515905236608977711679277556212363780793492879269333512193344194571092;
    uint256 constant IC28y = 12754718493975160105555268019165933028312617862240183237532311775242136707099;
    
    uint256 constant IC29x = 106671941977879313626213669452906406911215694138819673826216101134936332949;
    uint256 constant IC29y = 12515402013361112895611072823933842886795559772072964890667392708367146760065;
    
    uint256 constant IC30x = 21336658383630402503779548073224744487565321998209781201565586020857178781321;
    uint256 constant IC30y = 13445798795214061558249391637018194359226940688688187814401476426066656973761;
    
    uint256 constant IC31x = 13222812160998191280763210844232059321141737362497073659503615525894028962451;
    uint256 constant IC31y = 2713457770950243968886763944900757272308358903221166728930054120315449018953;
    
    uint256 constant IC32x = 21359919664574210571365293159139039627777175704446394477049204512384692571679;
    uint256 constant IC32y = 19182300192052116051878968086963975158472944585127779969988805519323537473973;
    
    uint256 constant IC33x = 531875239678152684193596312066958650298038188114082699796693379804678995664;
    uint256 constant IC33y = 17163417475378896245049264261203127333502077201111759135948484709247870671255;
    
    uint256 constant IC34x = 18675753643528726710503453612645111428697161166314755022961086451864387838424;
    uint256 constant IC34y = 14442448927282410840591839738649648817289945636313428489835290929987001687714;
    
    uint256 constant IC35x = 123383086900883015316779836667862457128181931992325340085566463045088141031;
    uint256 constant IC35y = 21639210548691540740053647281480257388838630182121428888470826815715955486324;
    
    uint256 constant IC36x = 19688390170510397739943249107831374646705470067988175204740654341834482746967;
    uint256 constant IC36y = 7756549142344473193676477408554269052942083176017509806592176726082007371798;
    
    uint256 constant IC37x = 16512993323254926572207667950142020622723647879743427955258926867617290128323;
    uint256 constant IC37y = 11031811175232000545608767605255021540514781966065229044318213218831772054418;
    
    uint256 constant IC38x = 8395829916480684763696813897242067515217025249350840137397175457301504404249;
    uint256 constant IC38y = 7912917567061833865687373459669663842439346001445088968881044372655880582869;
    
    uint256 constant IC39x = 17547344836873843773019471379408060662925828053524233983336449779926320936950;
    uint256 constant IC39y = 15458640239200738691666110777448626515523287092740818302340024414549937165258;
    
    uint256 constant IC40x = 21675818311828272159505203039566387668284591761261600621251741951832336304200;
    uint256 constant IC40y = 20269535661515115562117701452552843847705468364705870307659173315961238653278;
    
    uint256 constant IC41x = 904364192154412108475046073342558381215696538760487725009614432235317431383;
    uint256 constant IC41y = 5933663722127366204598107567069263075222434535110348104141853291754569035128;
    
    uint256 constant IC42x = 15428457737890852713662044600176140584968067296754065505079528508031401973754;
    uint256 constant IC42y = 14377028875139575872268459757497972575492356454068347053911207773691216895240;
    
    uint256 constant IC43x = 19210028841039502713165462746930549759650954731772821168325157663842056352918;
    uint256 constant IC43y = 14422768175699595343950829479921320329569359452169808850588086909228306616061;
    
    uint256 constant IC44x = 6266039694737389349205652374106626434072464397165923414659943972118821657183;
    uint256 constant IC44y = 16786575649509273639734247872558711360104184928983233215563292992213908360821;
    
    uint256 constant IC45x = 1583308065024498115841566966645640058926784528635160438021148388274167113916;
    uint256 constant IC45y = 10795873103957025549503784985095248520280038415252623782863662117740947769242;
    
    uint256 constant IC46x = 4052746579978448620104712584561922346334633152696964551310426508271030276496;
    uint256 constant IC46y = 148402343457893241130883640098159361631680453244101309280618083820849402786;
    
    uint256 constant IC47x = 5554681525460531793672247997196194123368641048491913267883181614006264644408;
    uint256 constant IC47y = 4514833707066879026634839652370852154062210965577133351273168957515162552552;
    
    uint256 constant IC48x = 6258861814663423915559088848902644026783428715720347117266586165414660029999;
    uint256 constant IC48y = 2640275495807055472210884251970980231150070928666524200296851421856943950866;
    
    uint256 constant IC49x = 13770881072792426796512273372762549650186641304058497344547083004176852507601;
    uint256 constant IC49y = 17688956969052975203423288121224815916540301851755623725668634637506456783828;
    
    uint256 constant IC50x = 18633143472179598332621527722090040409263397471499893284417240241156432249126;
    uint256 constant IC50y = 18280069070651761221970685963738481429431172815777337634559966145861593085890;
    
    uint256 constant IC51x = 21246902463369798769534092253690020996590904194904033594416699117987158864491;
    uint256 constant IC51y = 16368721579780754483634179797351108591692985232457164560403177154377889265964;
    
    uint256 constant IC52x = 8593638260069254173638407846410996905864506107385114849424221957286130637226;
    uint256 constant IC52y = 15435245038594107014431814221366172841756641897833257156057461933596439548289;
    
    uint256 constant IC53x = 17145639633626188910516167880940110425716002361234203965544500915067925768834;
    uint256 constant IC53y = 5216784080456343738090236596765958075805896178165215847541409531042724114018;
    
    uint256 constant IC54x = 10214828733434620605586789637396826942603414391527485768891992936091139376209;
    uint256 constant IC54y = 8210397311388264142455584883819844523857777557978716199317324202298584333462;
    
    uint256 constant IC55x = 65195722548792071014746452327586224941342746374524077084629692622274580579;
    uint256 constant IC55y = 19471409512446144105225431044166660466989021818774480691158472048132643063666;
    
    uint256 constant IC56x = 4124576387139837601216669036204689652644074062724396204447876145481290035730;
    uint256 constant IC56y = 20905093833078875683184141681933288686680855922202709361968550099887828375444;
    
    uint256 constant IC57x = 7873946102897797589159800145592114526591318658732798753710738786133611889037;
    uint256 constant IC57y = 19392047309214462336502663669880696677879299354862256139793395612708669872511;
    
    uint256 constant IC58x = 20094054028537404688730816106714181322534565800783226519471417769240507709852;
    uint256 constant IC58y = 15882788561434324900633935215729097035010800789468239972329956691815888779393;
    
 
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
