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

    
    uint256 constant IC0x = 16923240697462243130520616846652846781583207375717165252145074524162066719814;
    uint256 constant IC0y = 8203447333022407163543634887404975780052168848035393978943665610637547388595;
    
    uint256 constant IC1x = 12661649045518417846209474829514240550445224404476788735368718751097886487651;
    uint256 constant IC1y = 21184736979873185990143918452111049939218035114931803105567511762809145992460;
    
    uint256 constant IC2x = 5343179950411351614834491241830006655978529757408188334878322735144698768724;
    uint256 constant IC2y = 17021018382946661884326228525443686230508081243555448774746796519273652446480;
    
    uint256 constant IC3x = 14104832253126082223109242559136163878678521510359726798932715328448359416462;
    uint256 constant IC3y = 17658532276416361567934187906258257604303099298761452894398256994867374674713;
    
    uint256 constant IC4x = 17853304045654237490031481961965928597593000674735618771164763655748379646433;
    uint256 constant IC4y = 922512303187144565599041689522002680193423532028692588021001621131370043410;
    
    uint256 constant IC5x = 19796591191615469620739953863941998894454366617897695411029316227201794427584;
    uint256 constant IC5y = 7015600237678010074459547838138176300695490814707823732145621277988352084211;
    
    uint256 constant IC6x = 6874075928279627673296422309818853876950337409606240406108561598736155161774;
    uint256 constant IC6y = 18247455666973610724445372365089587676703940082531490238812221043738137224946;
    
    uint256 constant IC7x = 8578435268798631693241164623358363082676443818831549762523238618573384532062;
    uint256 constant IC7y = 15567975347939117318517035254018179909553332214287358298036500121527824476630;
    
    uint256 constant IC8x = 15258136574474244288853362121470822733905857641476229145028723187427348129729;
    uint256 constant IC8y = 15291473749428210996312274188973617200043840547910290755627739270950363989339;
    
    uint256 constant IC9x = 2815358369230087407956565266317930358316937672152138960149415257606325305080;
    uint256 constant IC9y = 14737368905308366330499509218275304294127174348552951712215801644683149353699;
    
    uint256 constant IC10x = 16375299913949597689135817007319851395552434759750651830407233936363632969169;
    uint256 constant IC10y = 19302197455113624762975833118342817105737851766594521373920528985417991455914;
    
    uint256 constant IC11x = 4917827849637454273377429764153238520649377334370215273984320459596719398729;
    uint256 constant IC11y = 6536580117270679260092381918690496396014849275877241153912906320489026750860;
    
    uint256 constant IC12x = 4516062648477829885573569037171650305000200833747952510158202797917346043592;
    uint256 constant IC12y = 10549752353333041312225362942531598512673289713662328128474638284360379129460;
    
    uint256 constant IC13x = 16206632586173558549104275079527982352193684121558360825290413366394355368951;
    uint256 constant IC13y = 11494851693780849759078617561417154770621683203817302245112081657815919882625;
    
    uint256 constant IC14x = 11494537797371204955953896441257224721545261196263031813266909513435665805662;
    uint256 constant IC14y = 21484519233759708001559605017394800449077345710556636401445346236347737665764;
    
    uint256 constant IC15x = 8143037812918765445678327863059482898618229447426850259598703637867920339204;
    uint256 constant IC15y = 21326855404564209980400866715714302555292295578898339820889120547335860508529;
    
    uint256 constant IC16x = 13859168284680484190699782240675844286221388034312773869249275401661420131297;
    uint256 constant IC16y = 14514826459937067546474335130621485785708812241707182333682831421988704541042;
    
    uint256 constant IC17x = 12144768410792980112660756836033819773061063684877845752627117741975843128159;
    uint256 constant IC17y = 5719368915361836076419425432528266222237764040588047953859695992851630221295;
    
    uint256 constant IC18x = 10024031127248606222752216400379705149197455230013591713620663020473103228010;
    uint256 constant IC18y = 10834093570899668118366837933319615891100775743706209804567285006293783458301;
    
    uint256 constant IC19x = 5433005283890383251661146980571182520884833703958533933258423721995493540411;
    uint256 constant IC19y = 20530328388677116534108827214646200192727864238958650057488055043652777825835;
    
    uint256 constant IC20x = 1631920737359478615817221791315988879805443419472452782659862441603690065485;
    uint256 constant IC20y = 8687256080539854120748607159915198823226137595233817641436879371173953696671;
    
    uint256 constant IC21x = 12354005290139141053450040794595246516630351268720304214925176981300777913345;
    uint256 constant IC21y = 21661865275710335567727904946444951078087641502407680831824928826747987560371;
    
    uint256 constant IC22x = 11670472458146225271618624844936539049227773322727006349035160728433495858989;
    uint256 constant IC22y = 21518319850451169808677075844795713149912478831247127242453877429992239184804;
    
    uint256 constant IC23x = 21239119551687493831963291621884568049550540787531419553345901581925458466827;
    uint256 constant IC23y = 21231054598907496683744574037661891291796336344340443663657155486216430461707;
    
    uint256 constant IC24x = 14626007384322396126061956320049385429288687670637866027214619545612789136949;
    uint256 constant IC24y = 17778262785638908454175731688605137049203148510077482367931883688167032378356;
    
    uint256 constant IC25x = 20375777566673313333627854745202598200712727076033954892313373280822184571936;
    uint256 constant IC25y = 5242892809569559064522987052155544356204382393992349088581797238918990008763;
    
    uint256 constant IC26x = 3863677994988804915454061422824240029223032412811317626260906908208550098048;
    uint256 constant IC26y = 1047689049364808103082646089900397381884513171729963245635583600587693939624;
    
    uint256 constant IC27x = 372254940650716582985690581685092052150395790782625543046713640723986542020;
    uint256 constant IC27y = 17858095020742448712580954516650689604489593476921220312675593172159228823747;
    
    uint256 constant IC28x = 9550333133814806549197497506382624149308052909736352108885572135283614071921;
    uint256 constant IC28y = 3051956490727744147497769388383645319295443656437466920554912002449004709820;
    
    uint256 constant IC29x = 8804212804302992519682033945455204539170319282041491204560871221910360387153;
    uint256 constant IC29y = 15635391911184010180766654271266392379815604016441115434940520253827125703962;
    
    uint256 constant IC30x = 12962590372172443756454223903483156458293780398968601822289180202923523104883;
    uint256 constant IC30y = 8068446888392764532985423534319074416268840160937371751174103398627942150350;
    
    uint256 constant IC31x = 15293600034356076431446092980077103560435756957964791451270737760849654287902;
    uint256 constant IC31y = 21810396186028261909122458745581700907646550287151311581342931860719953660982;
    
    uint256 constant IC32x = 16760295543969897387869026063266627279418718795604811122782733087338781701756;
    uint256 constant IC32y = 19360520075981730847908508550164563378104937953576013785957225303594018107996;
    
    uint256 constant IC33x = 8825128053519112831543372345937032746717646084130169726470664623312946414737;
    uint256 constant IC33y = 21685827551674784126179778308399741068356682414887501920878709736109229809455;
    
    uint256 constant IC34x = 1086584663359421005005108541687726003497109670093669836593624899592557993989;
    uint256 constant IC34y = 5780168212522507048244124750856170250146409092397028462157988810625485519112;
    
    uint256 constant IC35x = 16884460013581263324530001184661199273559312684386966135091492676234740932643;
    uint256 constant IC35y = 3178885432478671218064816730964932595116872378299878183090531947262933562828;
    
    uint256 constant IC36x = 21453604374239682447921279699029608778021066552434565537046485191039082536815;
    uint256 constant IC36y = 8682428480529675332096919333070948587311551269362068002118103617282125526753;
    
    uint256 constant IC37x = 3033541401337734294828804640066162713602276869694077547542808834945641591024;
    uint256 constant IC37y = 4275747342944237981434350027211033649302960748030600761298845220833986659366;
    
    uint256 constant IC38x = 12349834885412051111568521387352783485289718079028566267846479834612540197374;
    uint256 constant IC38y = 12590680537145568044776604560747204586527030313141313498842179009761289155436;
    
    uint256 constant IC39x = 18799330330916013486976093238698073793083565216315082972676000669515164034424;
    uint256 constant IC39y = 8110044273670741107969815985964914225039895980519281435509349053757608970171;
    
    uint256 constant IC40x = 1994527595756032742809457539987222451333483969636336205273419008564940355951;
    uint256 constant IC40y = 19652285995646029979109092720116713016178213622622951001808903834202901187215;
    
    uint256 constant IC41x = 11277446909706015616858559351558372858859010002746634445095850009524588126344;
    uint256 constant IC41y = 6998376127601174954763687538555737403907368313999858264195607906130363627948;
    
    uint256 constant IC42x = 6604599259909517824525979871001648807397103870523035992673557430956259107153;
    uint256 constant IC42y = 9999283379940263176651794026154026172826654752046244600463056692073657637295;
    
    uint256 constant IC43x = 5558098382853594709002288215983138639795339074636346684901407089126224870186;
    uint256 constant IC43y = 13270743851471017866117659672410379933402962635951682796879042831086578882155;
    
    uint256 constant IC44x = 5181104398249599494103000216596847772760485135770847130435363950597943689377;
    uint256 constant IC44y = 16429500961793588356398156580049885988343577771591222501972681973284603967859;
    
    uint256 constant IC45x = 13712414017523891020728718133432194309572731502215591624768529184263683678278;
    uint256 constant IC45y = 9403418973807208844717834765908314774760509448373934069589659952264341479314;
    
    uint256 constant IC46x = 20492874854945859795917226240396815971803488139698954755581262939355861015421;
    uint256 constant IC46y = 20565449468316209399990302934997415005027026292248187407447684961680804746700;
    
    uint256 constant IC47x = 9099683923013624892220163905124374376698119289255156208969327295953044462128;
    uint256 constant IC47y = 12317052012902218219811224325995065713600851183551688281788467070009418576798;
    
    uint256 constant IC48x = 17569656990460567211766736384976259951936165451114905955843879441586927605387;
    uint256 constant IC48y = 14271623494050456772947270777283234387655866280270538788732069859040068638873;
    
    uint256 constant IC49x = 20108715916218465250198774506754403035778373125938627354909762324265128572565;
    uint256 constant IC49y = 12482776873449494865506691258337026423304769827109419611611790356894795831431;
    
    uint256 constant IC50x = 15057499421452701597268423315238244112085831120739849580003640782680617859896;
    uint256 constant IC50y = 4743864049143326608196491160550483098798677503802044432066529052748923294791;
    
    uint256 constant IC51x = 9301453863284620832761526510590158636560773923585605443347125502672929963743;
    uint256 constant IC51y = 21386699332908523686633446620131193657313769349003107344723627935243594179132;
    
    uint256 constant IC52x = 14689451077702658654629882097007678055008357103926414055586963163709688126601;
    uint256 constant IC52y = 16335149502693650142504724313098890962172751252519195979956976037361326720468;
    
    uint256 constant IC53x = 7150709985987880872877038285392676459343315131445474549253989171094330186775;
    uint256 constant IC53y = 9479565608112394315218472894931948890207027292919600575163464692434569433600;
    
    uint256 constant IC54x = 19753038472212931882463779247174698521974303866226392339886118711164749039858;
    uint256 constant IC54y = 18480293662182347317541079906465749661251170646779546423757365307495411674824;
    
    uint256 constant IC55x = 9512071764636037669059968617530410859246670607325202978473713083953647867887;
    uint256 constant IC55y = 18444012603031927125190940364292254124192547602433448920401772759277749980158;
    
    uint256 constant IC56x = 5095358747166782761311944608200877763896106268576213765425766257803334549936;
    uint256 constant IC56y = 8950613224071833860684957229369510452482123987114006915494054025826743413129;
    
 
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
