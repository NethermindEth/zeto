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

    
    uint256 constant IC0x = 15014164560111675329781543403572232459153345914794133493492913478456902858055;
    uint256 constant IC0y = 16743978849835579967045689959089090581857052723461663296195432122128519522406;
    
    uint256 constant IC1x = 20575384950289596728507866575055038905464801556347479270338499169056495568505;
    uint256 constant IC1y = 10972285846175739537317264947557767383395796512512224211465022972479305568019;
    
    uint256 constant IC2x = 8164485574981408767029999569180759738043450961024437185875549685198597208956;
    uint256 constant IC2y = 16385434522398219100190073544721022759057273901269101575092435375818727098270;
    
    uint256 constant IC3x = 17892743846370399498075442090757896672814359293462055117822436909372249433877;
    uint256 constant IC3y = 14235878484958745096093546848136354585298181813011247781814826482894657850135;
    
    uint256 constant IC4x = 4033000892870860032084528482320733730903514426383224920677784766869934616652;
    uint256 constant IC4y = 14327160595723705335601320464461680253222641908983914654077070713740126501136;
    
    uint256 constant IC5x = 8857664405242462869164379303273158594053358568559374776258912683935396594832;
    uint256 constant IC5y = 5361353038105282348470709504055257593788855959786096209460340601327660085402;
    
    uint256 constant IC6x = 5764603894408509865718877221398539706370018016482560617386741705728577139529;
    uint256 constant IC6y = 7074668823170613355141651797214798124215088080026502295989542119653299734820;
    
    uint256 constant IC7x = 10488625362908655992866633160945835566766204249154429137223414274830041581337;
    uint256 constant IC7y = 1786912292936452728718211941328687486920731321297691047601484709222723195173;
    
    uint256 constant IC8x = 16990056500772156995427335924912895147281988001948310307748111384373235983408;
    uint256 constant IC8y = 3931857624492558179556203722168378676560773181451909866375810553914604716165;
    
    uint256 constant IC9x = 14807385266314601653139411037493080978625042821255550409619428446930039175214;
    uint256 constant IC9y = 10248265840567121747762391472673707712188292747823069046133590189036275727535;
    
    uint256 constant IC10x = 2128416993159628785862437522473120942478495772194089197312309681981959218827;
    uint256 constant IC10y = 10786841584495061295157471172396712117622253649427504829718911948226534418386;
    
    uint256 constant IC11x = 7618319042960158955885644430797987273128419458317784263413782570168158563744;
    uint256 constant IC11y = 10362878388213159499177860231863629356651035707448658256107879419933159171973;
    
    uint256 constant IC12x = 10362465471161516020565806642599554086651979928088561582399111144417255791057;
    uint256 constant IC12y = 18794670633691767286663381674278260641257519579534982881840749627747541231063;
    
    uint256 constant IC13x = 14909418905736578642627295386091216945839762246197948952184587852836140008153;
    uint256 constant IC13y = 14121609016809419017990066094034392499264215155018150829261255791372607256636;
    
    uint256 constant IC14x = 3688390964725345327702775041851754198923726953948780700743212683107650348009;
    uint256 constant IC14y = 18332169682620676150712805492795471719438434196201517915614789180933917923196;
    
    uint256 constant IC15x = 16850494615425715972330898133830552702363174734634631173734644843903699585699;
    uint256 constant IC15y = 12506629067313597261247660245059564549992710725287858548656835626665477312192;
    
    uint256 constant IC16x = 12323508133159411212169374225942806256410123062392723989440271884318267413457;
    uint256 constant IC16y = 18777778506119454673802172322398535454185307343159690330930344460780271856727;
    
    uint256 constant IC17x = 20416883592043593052251093760089003387983581511870727310892825932742374699358;
    uint256 constant IC17y = 13521984718560776403711562517537116312658606982486194284242777648673622478340;
    
    uint256 constant IC18x = 4032798442798275357788717177017668877994670759506162549522328813412363145392;
    uint256 constant IC18y = 9906318458976456283713454307397469270558982744860022463669985120283138571901;
    
    uint256 constant IC19x = 9603177688447142905832170448927466405829514427740346198306507376287012835990;
    uint256 constant IC19y = 20604576664099126354353766473858947156406530084415508834346784154240233774094;
    
    uint256 constant IC20x = 14975988890652758774792625848896670802271038291959196433743368132041038478622;
    uint256 constant IC20y = 12276901720053829904697667877378608691176997915635621379027453224802287266743;
    
    uint256 constant IC21x = 3123674109275061094287616827056515995042023818316931906818518094593705793776;
    uint256 constant IC21y = 17881580423466604879229511068284630692447263525343391976706556387054720766187;
    
    uint256 constant IC22x = 30055435226287495905170717424982827518573298378852377810425991502498479877;
    uint256 constant IC22y = 7475585120426922488476496452708151849602852940484662961949958924034759261705;
    
    uint256 constant IC23x = 3056308688519958499829797350868728285719521421992658104746433605844602836548;
    uint256 constant IC23y = 994756415959374212041546285199763227245426986268669861179305204491755296815;
    
    uint256 constant IC24x = 20257933298954237220233143394424476069099516237848130818863603357134236147459;
    uint256 constant IC24y = 21805823281259880818980402840317457846556431553732625362606551530761988023369;
    
    uint256 constant IC25x = 14351629374267559694343883457672512606927943149573305068621009105665482273790;
    uint256 constant IC25y = 13526050342436994114912633133858830873145893854666931599549406322122361314572;
    
    uint256 constant IC26x = 10423451397457390769576998821162650908393299793906800389230200749968587958593;
    uint256 constant IC26y = 9720405946101926165854578755606707339867016465693050065745944358447720152962;
    
    uint256 constant IC27x = 18932210790513961842298843234227776051220970384665080907967761277338482213840;
    uint256 constant IC27y = 13703253739263538405504142495693983574451159316932046551775008655006773482104;
    
    uint256 constant IC28x = 15423440173766319472629485393290095961875174009652575163068975719574578716930;
    uint256 constant IC28y = 13923372667857334966466722274939629526993983740020824317821625648049393173342;
    
    uint256 constant IC29x = 20312446079750612949752250318296905161003163696354688423029360978373770229069;
    uint256 constant IC29y = 4160583327812317950317602706508964166664347442443015467413983412305153703134;
    
    uint256 constant IC30x = 5209593734316136177895529829013915909111338909398615315958936895674244452483;
    uint256 constant IC30y = 12429894998446479711194155659236218072641408273367547365891295002283954930844;
    
    uint256 constant IC31x = 13441707513404911106165780475140568871808457539291713186916592605275245561014;
    uint256 constant IC31y = 6209485204103983346456956323450735205606669392482484055010202231871761071292;
    
    uint256 constant IC32x = 10323290840897298380404983491542237248237166602694027533607350877833116109017;
    uint256 constant IC32y = 19542571690310768845686573012126130596673056507176330925908263080250435891505;
    
    uint256 constant IC33x = 17990383834971043955606723656936680151163820307565599752855845696729176584814;
    uint256 constant IC33y = 21246752262838474821564389101810121093131696323739433672386174393072077893179;
    
    uint256 constant IC34x = 4479136781735504692507085831155420942553116238050231226194235587980820148903;
    uint256 constant IC34y = 12785494018101565469272184872575318493590097181434580163001802611178236218211;
    
    uint256 constant IC35x = 21656443713271980193339791929677435446219922764065495360274621816807367191930;
    uint256 constant IC35y = 13696274754582754422116086429863814016708914109764585237213850828451796431738;
    
    uint256 constant IC36x = 9205918300491733196878733171453099771975031792190822120397854372234588421898;
    uint256 constant IC36y = 8466378586624568493408160098508400627658701303108278937566514687593829613545;
    
    uint256 constant IC37x = 19852830304102325683430491152258705794817575938761163967506818588468426424355;
    uint256 constant IC37y = 5777839904282308815539805355941129872802663914982956512782189188890226787497;
    
    uint256 constant IC38x = 7259858149414088063657509621906856021642168105576376823094834399985206327005;
    uint256 constant IC38y = 3349554442545253905086475185680341509946770409064326119415094618273790910874;
    
    uint256 constant IC39x = 19807903950062181398310680001583396391993846530030805618264722853502100461154;
    uint256 constant IC39y = 19721414787878605780419791716803707162278458028462960449209454139975982603489;
    
    uint256 constant IC40x = 10908566869209771257367472624505245419102027809635771180133291277609472965113;
    uint256 constant IC40y = 1594475911082586326867710703628950157160782035389725944676877055001033331718;
    
    uint256 constant IC41x = 14067298543105489445612930822850335839422996985680090212950244848479695588632;
    uint256 constant IC41y = 18382100635660588839051741584026474648535766322252718260339175402009360682834;
    
    uint256 constant IC42x = 17306693244576429036484567883418607571467644137834713922735216270613891421630;
    uint256 constant IC42y = 20894280134947277199042988408894162479831481143424189516741904605643199058015;
    
    uint256 constant IC43x = 6436802883797492497452686715344466213943664568304256087042399225666050484006;
    uint256 constant IC43y = 1253280077449520605234765284243262109603099626406856820743042790861767055286;
    
    uint256 constant IC44x = 14804477684916913293401104012117937054555518726131860663388785126620230731731;
    uint256 constant IC44y = 4308433519936854630529449967925517933787102336324795234036756953373935002338;
    
    uint256 constant IC45x = 21695192412299792608469828500352290434974874667004422553768421505516175194610;
    uint256 constant IC45y = 13559937943834135269976451865839069610536229005195509240867652423306635077051;
    
    uint256 constant IC46x = 17581012645868848353767419093344709705986775080492908932802763875538244165016;
    uint256 constant IC46y = 8791231688480651351296903877507146990828188531849738800435751199693270034591;
    
    uint256 constant IC47x = 21642067537333941807503275090130691143843545621684423280110760514022331167805;
    uint256 constant IC47y = 2684360497581756281937748421461312010805306456141303766230142082168011974571;
    
    uint256 constant IC48x = 21045889410910150984291598317088984402690706380898795676059821878210727746888;
    uint256 constant IC48y = 8538313403530769161019448110711136394991109319292929519268937036775659637255;
    
    uint256 constant IC49x = 12044512033438013614809239940128326659055398190809831247658078859927932631810;
    uint256 constant IC49y = 9973051196931955133445458205466113191678937334524343655243121730669065305820;
    
    uint256 constant IC50x = 4285617172387508386261334381198044583367559312817812483328820801316412605168;
    uint256 constant IC50y = 4108228524252402703729432400997050094192570112231027895959610936849226712170;
    
    uint256 constant IC51x = 21511777228842214653495021633926888608833089682046272598314946217392644457052;
    uint256 constant IC51y = 13901483643721891929146429974356220762826349332175803125922272978695591482527;
    
    uint256 constant IC52x = 16458931300156513686473270162592987684916758832281044395255946144561858293144;
    uint256 constant IC52y = 14067194212580082860449932019559594283646530716767566761184188510469009362321;
    
    uint256 constant IC53x = 21562630316647013645756311595382373963553667548928780377562315115552071292629;
    uint256 constant IC53y = 7818273183716298545610657407697772298663029283281658416555316543294889745887;
    
    uint256 constant IC54x = 7656898544080502241266117954069737731574230187305621734359836375511955307975;
    uint256 constant IC54y = 11054138151406194123885292953986154088055406003745347267967793744202420671804;
    
    uint256 constant IC55x = 16349954338705408107902991117506487350170251081337446900275670745247300699448;
    uint256 constant IC55y = 2563049096122705782005638542907970516640690565514830304151798986855917513508;
    
    uint256 constant IC56x = 7022594126469850101035099780420289705422346937548963717300530552614015425403;
    uint256 constant IC56y = 26532996913488651544919685922745765737376213425419722982078925865416386447;
    
    uint256 constant IC57x = 9496366419600705998717019796582274748056693471709675858892659063062270537144;
    uint256 constant IC57y = 17603201522715904529469046057230705539747153069959636936989561065511498071909;
    
    uint256 constant IC58x = 8887911360286610063391220652682301888057589962863015642123161181850511083922;
    uint256 constant IC58y = 3640907767433112156857226715303753493991449551578019386461963144608111627447;
    
 
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
