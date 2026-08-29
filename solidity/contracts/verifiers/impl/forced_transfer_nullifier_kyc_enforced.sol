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

    
    uint256 constant IC0x = 2402912714467057399057720286800939578362704484320798993216529800364906430846;
    uint256 constant IC0y = 8349944376883505719087602654450874166796096528804340537428866681699533855864;
    
    uint256 constant IC1x = 2103478041565166873465926545978523462810044097265770235539246896385001431911;
    uint256 constant IC1y = 19235151313106373339501148618542893392719241531793830752191488471798715108826;
    
    uint256 constant IC2x = 18723994830719812174785814957093464137938602368290239548745567994035164206384;
    uint256 constant IC2y = 9364996399215774273644867930428033952782695675718226029925425044111643849601;
    
    uint256 constant IC3x = 2746766137500119255941464838412398303215397965061222834114219031484850149431;
    uint256 constant IC3y = 9528871377825728360117622891297599266376165185082896269981846549254872520510;
    
    uint256 constant IC4x = 6039142607401640840728727565815065547530245122720636961812094384117891791691;
    uint256 constant IC4y = 7120823863301059595681958430899402511717757176899511471332313596773122199974;
    
    uint256 constant IC5x = 13682807044190271567828017427653770489908260105721034216859028133117584911747;
    uint256 constant IC5y = 21496000758358494226402873703309251377437597702599872348298385819151011923115;
    
    uint256 constant IC6x = 2989150755472326790154292831391198873481997355835445798991906977092647568944;
    uint256 constant IC6y = 1611591140557950700195348944987775486799989145836892631324167689166643166940;
    
    uint256 constant IC7x = 14591486780822523409167174365759146365167360329328951692820665694366343572935;
    uint256 constant IC7y = 15863428630423615497299543086119438772547355645626738781344532453841504426340;
    
    uint256 constant IC8x = 7655330577220350225389354904254973591377622181856315148458470924631065162126;
    uint256 constant IC8y = 9634781080758990637498539422942374572573487995141596698085042911201138862664;
    
    uint256 constant IC9x = 16247132711719452553750242994946390526621469062356703252861361605811656293647;
    uint256 constant IC9y = 990479009095488437668455848640065561176398024543481756818917234778891075732;
    
    uint256 constant IC10x = 4433071322156898573161140839290653418445432438007505059917736376519288524578;
    uint256 constant IC10y = 11691941146317955018883364313302780768618143358671317250507846412403656911275;
    
    uint256 constant IC11x = 16206632586173558549104275079527982352193684121558360825290413366394355368951;
    uint256 constant IC11y = 11494851693780849759078617561417154770621683203817302245112081657815919882625;
    
    uint256 constant IC12x = 15509028065789473551822918637391673450325323642058708884778991980363092026258;
    uint256 constant IC12y = 5280030152688412489042371300832270096865634086048692180886615131975587496180;
    
    uint256 constant IC13x = 8038167566338610474144873306275837765054616823487106486838921269678038675209;
    uint256 constant IC13y = 19757587279418350979806988697676445359709728851814333146428926164147423499748;
    
    uint256 constant IC14x = 13859168284680484190699782240675844286221388034312773869249275401661420131297;
    uint256 constant IC14y = 14514826459937067546474335130621485785708812241707182333682831421988704541042;
    
    uint256 constant IC15x = 465366243929184371230527961584304872385414129507852335085391222121034369857;
    uint256 constant IC15y = 7439433572978803470964751992278315575561338098283932864533290285603221613843;
    
    uint256 constant IC16x = 5689389756409208739338518077544139458097637410809558045634633485329483476071;
    uint256 constant IC16y = 42644931372198381656217477652984648146227687720046489442513906250093009804;
    
    uint256 constant IC17x = 5433005283890383251661146980571182520884833703958533933258423721995493540411;
    uint256 constant IC17y = 20530328388677116534108827214646200192727864238958650057488055043652777825835;
    
    uint256 constant IC18x = 19895928794468745295614691539607633954496492361340763129245743220031362368119;
    uint256 constant IC18y = 18863842224957615254992056689799030836807258711111407716971359550438792482295;
    
    uint256 constant IC19x = 390412380328135160203212861492660773708998967656045519784559722546364091294;
    uint256 constant IC19y = 5403473897535383997117396709558413124165518249839780917567328431080175016816;
    
    uint256 constant IC20x = 11670472458146225271618624844936539049227773322727006349035160728433495858989;
    uint256 constant IC20y = 21518319850451169808677075844795713149912478831247127242453877429992239184804;
    
    uint256 constant IC21x = 5596249913807379080540564947027061811348768271370517349046302349740944983490;
    uint256 constant IC21y = 7896177231550751917016660128889563527579224593656080799897084913510822365345;
    
    uint256 constant IC22x = 19377688202983106781857901667092880210201897038067764812506524581992319260079;
    uint256 constant IC22y = 13273575254887410776929382529105382930795994114314760368930909755147284292150;
    
    uint256 constant IC23x = 2262257736547899747020839456498681869004004148266678284426472864456661820713;
    uint256 constant IC23y = 7682682481493088967686770073734774011004607581397286770251166586301660741070;
    
    uint256 constant IC24x = 8523739540067768573705971089614393087137074051106732359219622975534614402587;
    uint256 constant IC24y = 10254996341684950703559033351708130310247464350848486211100997806071857879429;
    
    uint256 constant IC25x = 6452378222960593769415703033826397217374211775435811622441154735731217318748;
    uint256 constant IC25y = 12226159407244260676776999856436250552664321487030276651576557061346508845752;
    
    uint256 constant IC26x = 5605712061375415259351992529961568966334156802367333979399036996685202141008;
    uint256 constant IC26y = 19242989968105431031765710919281344533303237929902826380169942193958951861485;
    
    uint256 constant IC27x = 8804212804302992519682033945455204539170319282041491204560871221910360387153;
    uint256 constant IC27y = 15635391911184010180766654271266392379815604016441115434940520253827125703962;
    
    uint256 constant IC28x = 12873948960226554491431709177805746081250299672483267295904957358274127802180;
    uint256 constant IC28y = 11982366151945898675960952495173580985994210624606939874435966693997909459040;
    
    uint256 constant IC29x = 7257820408109991270940313150868600802152409635857669657934905005894224910618;
    uint256 constant IC29y = 13886089634112182876609590657564942099961951480290165808041750436919547117679;
    
    uint256 constant IC30x = 16760295543969897387869026063266627279418718795604811122782733087338781701756;
    uint256 constant IC30y = 19360520075981730847908508550164563378104937953576013785957225303594018107996;
    
    uint256 constant IC31x = 8510346633671526303887637992842961770948070709990991402692404503946509610419;
    uint256 constant IC31y = 18042147757955427310881382158795215927877894852544570731243452568255073399615;
    
    uint256 constant IC32x = 407599998063626600875737139978110984824177610925046351384455232122358156014;
    uint256 constant IC32y = 18100241663569519417468614731430811457542936395461217863459984092556645763642;
    
    uint256 constant IC33x = 16884460013581263324530001184661199273559312684386966135091492676234740932643;
    uint256 constant IC33y = 3178885432478671218064816730964932595116872378299878183090531947262933562828;
    
    uint256 constant IC34x = 15629316236907016059245083478323556681043422847468278772152422151479247567405;
    uint256 constant IC34y = 5607185681719637792141205376469712679050822364094654002008384871257611531898;
    
    uint256 constant IC35x = 6571140429887189676349921029774645887691087468459991460574388478218608946013;
    uint256 constant IC35y = 20652537535971286744083158959030681353396639252291135151051552885108929980025;
    
    uint256 constant IC36x = 12349834885412051111568521387352783485289718079028566267846479834612540197374;
    uint256 constant IC36y = 12590680537145568044776604560747204586527030313141313498842179009761289155436;
    
    uint256 constant IC37x = 2932638213330677598664961161178295452572654335693555653521372965729948034721;
    uint256 constant IC37y = 13075774124420813755273011275500826355729074034675138855888969845755824312702;
    
    uint256 constant IC38x = 17968072090205591744047471244916624398165590763941650224304469211933042539294;
    uint256 constant IC38y = 16889204341813802565362362369634547496332488432757890535035171440380417337323;
    
    uint256 constant IC39x = 13879621566898016941266809483622289233866792951534273984991409650612497704429;
    uint256 constant IC39y = 10138797226366016406777361819888931627544641732526527188679343306924758968158;
    
    uint256 constant IC40x = 11741938138249411773886652301641529891908365050863530897557571562546403635370;
    uint256 constant IC40y = 7178814054740690620373808714685119311589092284563115811910966235568934368659;
    
    uint256 constant IC41x = 15665836570738239686589030624230370069666341712703043253545217999454498796210;
    uint256 constant IC41y = 15805713180530261934369799835764968152482185483212847448994238414695810783569;
    
    uint256 constant IC42x = 1854054571943393681847426469021953316175747190971480412319929443568808196156;
    uint256 constant IC42y = 1635488672953393208657951459055436158713266466607717598351123865790356472680;
    
    uint256 constant IC43x = 16810901383038137668766467585339831903648547338745139973470931591347428601742;
    uint256 constant IC43y = 3256454229971895586573712913913435838804154476979851210660892291795260037129;
    
    uint256 constant IC44x = 18754757190633420364127172885710146399987903170222386709202881748811977718361;
    uint256 constant IC44y = 5784647686065250606346053701895633637896017748842526449895645074707892920331;
    
    uint256 constant IC45x = 17090902988526957680228330278826887017557589479606233297907072802243038427436;
    uint256 constant IC45y = 16440308686210451235267619684252921168820620722794905839373914167329817712047;
    
    uint256 constant IC46x = 21699759584904518447901267493373142711292107353151142014782135210415953000432;
    uint256 constant IC46y = 21338818040619289666466105641227044494820245519303549102431776628828962701722;
    
    uint256 constant IC47x = 15099318585988237835758988379780411125221842848296464993868518282565293999344;
    uint256 constant IC47y = 2394318125829825799836818714481785841072115067167079748718936041274776977533;
    
    uint256 constant IC48x = 9588202948224052542981352350025282604046985612571881589722450167773142975030;
    uint256 constant IC48y = 8373348165138529189806739914708439373375147475950515246355567690664499775371;
    
    uint256 constant IC49x = 21800795612652179568209959470154902007423125473490302381352953058169582292223;
    uint256 constant IC49y = 12205854534438042902892099070098408109013811247678064816581166859848171957737;
    
    uint256 constant IC50x = 16614077188613270070392849952969264933271685903033810337911707058690749820664;
    uint256 constant IC50y = 740070073332091455184886104274963571656772422795762667295342858408367257826;
    
    uint256 constant IC51x = 21328658952883417776083190467085301652100653056633751873592927658080781076381;
    uint256 constant IC51y = 11230233474509368266836276606021464284844922679746503280540943160393444292949;
    
    uint256 constant IC52x = 13970929152068540629444715920602531778887802332870784261705554054802131794312;
    uint256 constant IC52y = 2883753844776561071592452659380777325456329494899296219178465589336074908560;
    
    uint256 constant IC53x = 7916033351829014125972880097209563319511069016272470990452065376533485368747;
    uint256 constant IC53y = 15574928154287899427738722628949451089615154385350175567350585179414121114570;
    
    uint256 constant IC54x = 19909446072462233231907975032763249016336267293143503993655222869268428973274;
    uint256 constant IC54y = 3207374248260609665015450969233779548462958671279540898237562695494076291803;
    
    uint256 constant IC55x = 20341803352963567502453269830819024816949851415347417346022265404672443664629;
    uint256 constant IC55y = 19950089555705684399632961578579604932810656942203452400298538152913463644152;
    
    uint256 constant IC56x = 14670332188170608911436816570972810387687742534624499112374079690833509178915;
    uint256 constant IC56y = 14494043748534985337960076135576216114345892949511224390184194501004133881631;
    
 
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
