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

    
    uint256 constant IC0x = 7255102727216011806421902342016542074769601656957948681820131134100785899665;
    uint256 constant IC0y = 7904728506152059647833804268425804342489626570162244043043769681230195786850;
    
    uint256 constant IC1x = 10589327766517980036125673934196390859922986455098078183433463980253026962314;
    uint256 constant IC1y = 778635978617002344882129396703358926350964232622813028890255578201540025326;
    
    uint256 constant IC2x = 2121470156290319952018545969207445933570358845230572829950283618515465703907;
    uint256 constant IC2y = 20916459708278839710382042330691567638712846215544839055164220305532871016136;
    
    uint256 constant IC3x = 5293716091092471427661016754917660544748103020684720795961475017092340553948;
    uint256 constant IC3y = 2169197650120724056712965262573086753027802838069763785511828289242216836568;
    
    uint256 constant IC4x = 9006773329537149719183287532572028592746041932738875344583464053727895262018;
    uint256 constant IC4y = 10225231549644564792440309141416935339553287480256896137098736617318529997427;
    
    uint256 constant IC5x = 2487440969642102495589731546032199439547580516420151833565628090565041343414;
    uint256 constant IC5y = 7608440703075904073407439102106886267117721229069919308683044485131125771463;
    
    uint256 constant IC6x = 8623094724928753405589115033947238437242034512542787972962396650064762998512;
    uint256 constant IC6y = 6671578633338503374721914242413688712433241760251116320948588870686479443136;
    
    uint256 constant IC7x = 4115382198676852480287255600937778093164285000708808034200625326567506699217;
    uint256 constant IC7y = 4981234094883411801582035512168268775136300288314772731956250211587521072238;
    
    uint256 constant IC8x = 13254037383575236424452068085904822034584398187897896586914083919827501588760;
    uint256 constant IC8y = 19674077118996816182635443103346941307661816167632301556693947048653110575785;
    
    uint256 constant IC9x = 10812314010174335834633740860438452712839364324237697670042851688225109289402;
    uint256 constant IC9y = 11452659270512728311389185269772279924066893366347063901785090228223649099305;
    
    uint256 constant IC10x = 1029087954807235890981203086856080043833611084983347212043418342487007914714;
    uint256 constant IC10y = 423319896054920571805173473423981731144678564032275061427706613040968859720;
    
    uint256 constant IC11x = 3162219716800777241431995369882692051829069439800278504344612676804401330741;
    uint256 constant IC11y = 14873237135231672126931853067760498631810560644220742931323898973428698402425;
    
    uint256 constant IC12x = 6102852738302155042402040665259941503127831509185996805254461461876370232145;
    uint256 constant IC12y = 7108593077981701560356880831986088226326155704637151518548947416764926810217;
    
    uint256 constant IC13x = 9121797586863686125631792637837598376827062341950304590639798328778373383484;
    uint256 constant IC13y = 19677519599925634554457904187441094650708343405676767001408774830123117160736;
    
    uint256 constant IC14x = 15210024199473803542910607527912012870909982483457368286022918979024272981142;
    uint256 constant IC14y = 16494380746865266349538808875231538151438887539805630648588031215025915842146;
    
    uint256 constant IC15x = 17761788751734531617012417553324356596417604241962114303385408203523994010524;
    uint256 constant IC15y = 5521372761796560816412170075630583791468908846615313346827304077576353468171;
    
    uint256 constant IC16x = 15430803818738425341609705543409859751330923752075536341404475895976107068569;
    uint256 constant IC16y = 18825102435439827269561587367145246287427876996491713881191013817791036081659;
    
    uint256 constant IC17x = 15995385284237710421959495222359927943111370870908841216451031433992846849379;
    uint256 constant IC17y = 21539254390402834375453719334830554905330721617843201205727281819023072847335;
    
    uint256 constant IC18x = 476789926743820456437838418245453438307680830663334268419860982089445340501;
    uint256 constant IC18y = 1646245887275234800784461097308746201724791048455402154381167896968359580907;
    
    uint256 constant IC19x = 11186581045219135704444553189973358823330086475303458433717361545959968648891;
    uint256 constant IC19y = 18571058801063988185016773922793767375680630850568855824342785170167079696099;
    
    uint256 constant IC20x = 6213463400704341845685934814329363886863958525577690513108463727387769376747;
    uint256 constant IC20y = 510388968222678046015850190740626806007406370682888819810357757302217002311;
    
    uint256 constant IC21x = 4014393541106751594637851343126869433158038200458934221366902263645170972130;
    uint256 constant IC21y = 13200208482684494541236380683352411755578445067255463682177870941987743678906;
    
    uint256 constant IC22x = 6037509135394030789444367075697159052794945555298833934798353598785268088924;
    uint256 constant IC22y = 4645380574994367741557708348003975020587820355823720215727132179589819046996;
    
    uint256 constant IC23x = 11543281781054987283190482993687138775118561637717150524166248624055044873290;
    uint256 constant IC23y = 1938734939860344967580313783434104690605613105807898057990214624063297972815;
    
    uint256 constant IC24x = 2322144625035538464864743533876343669847590013008598909186019836233530381728;
    uint256 constant IC24y = 15072619635338346849746452472044600530724216282447669620295816024620206740145;
    
    uint256 constant IC25x = 7692888526442745410748231812028947272090490114782910648355779567338914954980;
    uint256 constant IC25y = 13548543446117937776396932581903622238739668346932546064416200429642412939835;
    
    uint256 constant IC26x = 17118902918974640608801110296543131058314366718867227261497132428092151922534;
    uint256 constant IC26y = 10230473185631132447510393594988669434012428034872865035178719753947886846707;
    
    uint256 constant IC27x = 4029870194760900464059602256950907521216575888166462861952420401233678782957;
    uint256 constant IC27y = 10179886858726181041541736704604148004085104104461241294631077633152786681598;
    
    uint256 constant IC28x = 20365260380469652620572636374467255646719157552247345341150324140064236591129;
    uint256 constant IC28y = 18319357266365862342704460313605413003465611619918303956726461826638319759223;
    
    uint256 constant IC29x = 21281554477287124890081431620638704813801058221496399788688744893282029425647;
    uint256 constant IC29y = 18791446017100724001429497128265803685570453958002160605157521152911340194714;
    
    uint256 constant IC30x = 12915735935923838107893024989315280408182823016912295926734158954219870633857;
    uint256 constant IC30y = 5753289581014850597358333732361322144117886586887992524990322397018365321128;
    
    uint256 constant IC31x = 21348048720845986670413292305272213785608229324811294251297346026332425458073;
    uint256 constant IC31y = 120941999632276232182502986877486319933089022708569986398641896612099134932;
    
    uint256 constant IC32x = 20047302332509628542670066644708395623816457021931760881793834832869041114162;
    uint256 constant IC32y = 2061113104053720107493877419854518041151381917299151799497585380392464467791;
    
    uint256 constant IC33x = 17168569043453249556608781431634626664275221471235529151075308552286533862423;
    uint256 constant IC33y = 134552312031795560810763123663017666503940573977963607196670383462089328295;
    
    uint256 constant IC34x = 7059975956982746995186608313116521084710244007094165912793942789937529915275;
    uint256 constant IC34y = 18326509649292198451383331820207218536372787063442296599236016820708552788662;
    
    uint256 constant IC35x = 1841317367046460996167979970615670990778348194389625436896633338855936840900;
    uint256 constant IC35y = 18602882610317515709811396399500189061923307594540071721252486102176225494057;
    
    uint256 constant IC36x = 11828971719885197914430667741749025288567308423632572430461053989312308011969;
    uint256 constant IC36y = 15444300386548424094837362421374954668790215786092154982285786198532904712954;
    
    uint256 constant IC37x = 2881951640618719870769751241918328436626988892211189187428893487421598749590;
    uint256 constant IC37y = 17593457376699525855258161599626397326681781146282240153482028817739561993174;
    
    uint256 constant IC38x = 909510014812169059613898853334780480446598584062587139107930414243406263822;
    uint256 constant IC38y = 17624825804739129586578448394859353379335648182784561259775411297514473474941;
    
    uint256 constant IC39x = 12461144397647221867847092421419253128426977023784608000082394071894929866506;
    uint256 constant IC39y = 6080753746631396063717955287924666911511605820562793007469830857032528359984;
    
    uint256 constant IC40x = 16233019534445370589596295331783437412112368816025395114740046331140332680519;
    uint256 constant IC40y = 13321887327517734209717521010301970228567488702536246865266772250613102784440;
    
    uint256 constant IC41x = 13079428816066337152912484653722979091542549418744777190836244943307750588194;
    uint256 constant IC41y = 11245305256702803357647287430457997464794005727302660233734669055539278658184;
    
    uint256 constant IC42x = 10842384026127235720961505402055929044863734551970089312088362226929701144629;
    uint256 constant IC42y = 18040557828555789743102388525101398533199939958272174425870618234806712010881;
    
    uint256 constant IC43x = 18440727449912947075697979127905341311479413723425226651580908915944964118451;
    uint256 constant IC43y = 12169821298167333915714160074424262848627769155067115958294794891778843395147;
    
    uint256 constant IC44x = 21112143377224771564278152156605372901825383138147210129759771766370328392870;
    uint256 constant IC44y = 16094787597957536602027763645559647319117781544916928232920442248226774841493;
    
    uint256 constant IC45x = 16135490459357256816917917036435219523261223669351900399139972752480701181573;
    uint256 constant IC45y = 16949033931221787310835204314091655783722703080460588422955305868709960172659;
    
    uint256 constant IC46x = 16622115109453874470526666669299763102710773855417468518371424295121501216360;
    uint256 constant IC46y = 16275955392014019336431136797934432718388403341053118227745226999131963918233;
    
    uint256 constant IC47x = 21213377808235903801462374218030936594170938388509223293787298122700934461527;
    uint256 constant IC47y = 489870319586443488238480996654714298332278264193168892581042597759178223182;
    
    uint256 constant IC48x = 19486943157450141699483523470056706777357729721965078438328958627989382599429;
    uint256 constant IC48y = 21818511098761903933164651088752451188918589128325293041780962294535068870058;
    
    uint256 constant IC49x = 16155076353272152959824105926332994422830044158451722072453137722179137130954;
    uint256 constant IC49y = 19233228712129860386688864543953742878048824693672781268772413151677821657714;
    
    uint256 constant IC50x = 2671681982662305588507552664521668088486080849237513914252415708646277342756;
    uint256 constant IC50y = 12861315793595750802136415601137961449784602656887210477237254382498857039389;
    
    uint256 constant IC51x = 20507175211323259090042292527413522178440845604928670419892313465922178642238;
    uint256 constant IC51y = 536272167461138983324257213567400910242586043640001950596104231791877097373;
    
    uint256 constant IC52x = 19255333068365077699413198156262413874304663120786776253118965833947629778001;
    uint256 constant IC52y = 2225406340932717605639975558318350771164934430339091371926956525876174698169;
    
    uint256 constant IC53x = 10033475380987359122108305346808126910606501894625744450522998685686512294123;
    uint256 constant IC53y = 4627759479088567154034830792756662826824806273880941086957869215576180089306;
    
    uint256 constant IC54x = 6337841214826646950558999660419787119996588310261728286573608065163203386203;
    uint256 constant IC54y = 1648394225414936866640448787309359655615969979925286110569335902842355772362;
    
    uint256 constant IC55x = 15402658417944406382896446671959402864665014133536159643334639552085621435748;
    uint256 constant IC55y = 3652033011369516059015415141530230195550034398416564133712311622062751050603;
    
    uint256 constant IC56x = 20005519067467911940019961345043236850157000784206915648832215359983261320872;
    uint256 constant IC56y = 19716403448433543291727015721731426631303659977559360249459282850968863277067;
    
    uint256 constant IC57x = 3181879118696924651098182319467818387527712554246560338912466111179680084424;
    uint256 constant IC57y = 17611732829065769517703877155821114028295009005569513539826991131911615600827;
    
    uint256 constant IC58x = 4088763048626484651001898764136348366691903805841384245259217860771019944943;
    uint256 constant IC58y = 8489973129362189750496541004369816960429237059710232245569191167616527444268;
    
 
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
