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

    
    uint256 constant IC0x = 1992732376952638283660788703886383128685912464041799030807076488788246026725;
    uint256 constant IC0y = 12678404509310737021570453893845449687217078792712031512979435365189415037880;
    
    uint256 constant IC1x = 10979831610747121285168263087078943126943204277737699161963794841411783525954;
    uint256 constant IC1y = 9797535760738687451016150160304110277250783440107034048442300867496050512412;
    
    uint256 constant IC2x = 196465450958050646580185051354183410514743451666492166138053734368704751112;
    uint256 constant IC2y = 403098343053339195951564457448283715124963399128151907355653241499817244995;
    
    uint256 constant IC3x = 770723969155493978319301352796914129417261151810977237088437071122289360673;
    uint256 constant IC3y = 20942519151664077094590144851514069212451491935502450405211977032705967415344;
    
    uint256 constant IC4x = 20486448240515871880980379350591782475351992895568036976065754149166631608455;
    uint256 constant IC4y = 13370548796457962284800741450561711074450933068574878030870100545185440702574;
    
    uint256 constant IC5x = 16891197602885850692457454295764611802093228524192226863761580688718504749419;
    uint256 constant IC5y = 4775391605855236832365630554041299044912217742005907167458753289448502663212;
    
    uint256 constant IC6x = 1689573108536830951811090994646399129422983773400473670765752639085623804860;
    uint256 constant IC6y = 7002124665543270863665967988316991525606831765813605146953835937420513645196;
    
    uint256 constant IC7x = 9231363177230200098901168870126648127536835624359487179178361949994244822344;
    uint256 constant IC7y = 19828196596804265037526077019290173993186221158770936392425753744790414519182;
    
    uint256 constant IC8x = 2843639097142972979509101204322181991250915720628636885528765676736574170382;
    uint256 constant IC8y = 13082951512734457758001388251374676536004601445699933055762155786703641789425;
    
    uint256 constant IC9x = 4977659470058641585385976212383094800902499084627046450680891971830177505690;
    uint256 constant IC9y = 18096016577562404225014678751058921860037487734296724215383714719068450959621;
    
    uint256 constant IC10x = 20462436356475130989179592073636664918275982506962326526872362267136712921724;
    uint256 constant IC10y = 4220281408032109286517594789085196048073394215014145582283604939758319569360;
    
    uint256 constant IC11x = 475042547631957677633750376280094153456148198335180125436011212489740357186;
    uint256 constant IC11y = 9223111335334919270825091839541009586759514236268432398047793205735208824714;
    
    uint256 constant IC12x = 8764378688863761367382612667984447805783658581450925220526438900592162586411;
    uint256 constant IC12y = 10035774973955069917797183382944248527098418277872272349003623534034474623615;
    
    uint256 constant IC13x = 5572560339466060932085486164406509697390001705666091351558192134729583282635;
    uint256 constant IC13y = 21341712043987729047736692165572782257624381518044310808086704098892887489220;
    
    uint256 constant IC14x = 1024676756329273861045321783054732144851812618203670775468983465618048397156;
    uint256 constant IC14y = 17559912596972090406358673531986537838630657656707192513250790103688602349251;
    
    uint256 constant IC15x = 3385786518203040002271510659370572593420947368800573553773475402751241553660;
    uint256 constant IC15y = 11737367477475023296290234701184083413918906943053345736525857246335075728118;
    
    uint256 constant IC16x = 5520278014866711820083356085179697408677808339414656199969325424660547031632;
    uint256 constant IC16y = 13201258326029916415236486236741650368610507640997457968317403948378683468484;
    
    uint256 constant IC17x = 7148233953029496069314759706054124843055571285544796925095399732414822659053;
    uint256 constant IC17y = 254828827692644207980357394999350148699967652145455806416695290896985071854;
    
    uint256 constant IC18x = 6542124613841436715967835891532238546432613986078313520746042157035376999480;
    uint256 constant IC18y = 15648864480027576248147968857366121412607066739374656762298173212181689191039;
    
    uint256 constant IC19x = 10044096692674592693794868515604392283149107970066465660944115042540628126449;
    uint256 constant IC19y = 163751476770701302075298774563437452276393270525259337737913278399656500654;
    
    uint256 constant IC20x = 5222171893411828099769995131602825255361769590398885094962968148482153722732;
    uint256 constant IC20y = 13089460839403762352246926406053948667241286044173741084026650640957282502039;
    
    uint256 constant IC21x = 14948612129069444947817514745750382808776900723972366154704384317279431155561;
    uint256 constant IC21y = 20826402782948493441947777603835581567353757024415446458907007016493537017576;
    
    uint256 constant IC22x = 10212406731871020989588307560005194566616632743734945943997384594311357605830;
    uint256 constant IC22y = 7854921814222896438752720849021156649926872340605940500838982931736285457931;
    
    uint256 constant IC23x = 1412087816677808807712754632203993227647682911124067941915954725991395293943;
    uint256 constant IC23y = 6423391164065426612942705089792983534954503208880800883337286391864818440938;
    
    uint256 constant IC24x = 4393157315366295609427095925328225652802377222939785522103525488639170136634;
    uint256 constant IC24y = 20864786665732229330263787147037887572250381461962388617435050836408673474197;
    
    uint256 constant IC25x = 11306099237749922367046312893393571275318140427955579996048997731953663252522;
    uint256 constant IC25y = 4403441413215784880469273147652943587984115267489035232678252238815396226537;
    
    uint256 constant IC26x = 10170267622830800368814125092298544489850315650290100876954222276649056428790;
    uint256 constant IC26y = 18143252048867797423432649415854758333201948617581605504869856815364377071178;
    
    uint256 constant IC27x = 18793288551932469717603865228475828073053403177097047525180122431321421825074;
    uint256 constant IC27y = 4140976753732538125595614118059289360970271418186831855155385851210893827401;
    
    uint256 constant IC28x = 260440620857270668005633428323513831046075924696849529872284858503074199477;
    uint256 constant IC28y = 6846614451998823453936415885812046795754286603373198911684208777530500015048;
    
    uint256 constant IC29x = 5635530747016894009775335799993513908828594257219386988862891544363489442392;
    uint256 constant IC29y = 5002026371953139494928715952894390577043255732945711267960840166785284301313;
    
    uint256 constant IC30x = 16139982693405705594307662311979448337977234150661187253234485783753169543949;
    uint256 constant IC30y = 17852501508431335831673438789327081238455565960342429811680992334515150561800;
    
    uint256 constant IC31x = 6857292430098656520761043307619976564186034131361158283486311091298358959707;
    uint256 constant IC31y = 11415227265433937402012020899035362480846271171210715322437628927492996408894;
    
    uint256 constant IC32x = 16705197043639202223588562235611600168211984935209008721273672703782277897099;
    uint256 constant IC32y = 2101969460685270675472563795641285119622047485811367483271596900872327764355;
    
    uint256 constant IC33x = 11997373176207782993965302316861148971981908892997183206001937061215481449255;
    uint256 constant IC33y = 12071228368537374840236106608391797258811183815909134229128052831091056972296;
    
    uint256 constant IC34x = 12369227497307930917074294964179576913333689532092894649387420685544526926680;
    uint256 constant IC34y = 1022683426622707516083424766785647296666106089297567002125967394926460848457;
    
    uint256 constant IC35x = 14862771325893905130352288191400276893964817086340330709016103502210650613947;
    uint256 constant IC35y = 20570927954978099502787397404309976955924205673641131098417274193702388863555;
    
    uint256 constant IC36x = 16807905891068035971551358208739632393684210331810085680186779362452422798427;
    uint256 constant IC36y = 3937253080223379304317852468458742977867341548394807040497012373350036902771;
    
    uint256 constant IC37x = 19306380017060110022246452773600717121759507594289098881105677507302079346565;
    uint256 constant IC37y = 5108839810099644873048543260110608225766357793292865552454818853877055299313;
    
    uint256 constant IC38x = 14331681302174230353564785685023383570330476700151841203939554349659678999998;
    uint256 constant IC38y = 1344487681291494282658706213755513073829797501719239854574606911358520967499;
    
    uint256 constant IC39x = 19976227680656516121067398837331782889622516350473976196018871176061056002182;
    uint256 constant IC39y = 4284850169936246157870865671243833467815190743031306318074429111425990713052;
    
    uint256 constant IC40x = 6233086851275703425805329352734761865962582684894930885244203574086075200681;
    uint256 constant IC40y = 18227842318226349989357706337477405512682632549614073469425447564340062589046;
    
    uint256 constant IC41x = 20377373784379846751804648503063292368622386388204835750295347243689953568718;
    uint256 constant IC41y = 21207251559827689478756938180755845612636610718657799184604741103956999135198;
    
    uint256 constant IC42x = 10206203295852125961862468015205755758267711898434131296619394023831944602314;
    uint256 constant IC42y = 5527463191854666127724086179619583003353072969521581318378406434395225322126;
    
    uint256 constant IC43x = 18880364653371201937006433661733596626962801747364949384781705469304056071367;
    uint256 constant IC43y = 3681487540868940961302787921673757655430467811435320709691124392411305648674;
    
    uint256 constant IC44x = 20705388783772206819522645625906738625095434006849777832393155953724578669472;
    uint256 constant IC44y = 9998877399499146077009798828811797005536840790982001703282268107206356631152;
    
    uint256 constant IC45x = 12104200436486663091314877784161887681248382092439375609367503734265570392441;
    uint256 constant IC45y = 8598077220350259558163076101631427173325500166974190126608292337439541027637;
    
    uint256 constant IC46x = 19717821229665744237770322364553832129368084046099759210006233716065164837269;
    uint256 constant IC46y = 17925694682778032622059885045893782082887966960964477292124245930969890466337;
    
    uint256 constant IC47x = 12596290080400795544166938376260815031334832179697857701003175241410916253156;
    uint256 constant IC47y = 6777050575014620849017098694639138573123970124640824362288051823206730004558;
    
    uint256 constant IC48x = 16377273126605905401060860233528916873431261431116653028516174200958670644300;
    uint256 constant IC48y = 10896197410076532083541628594267008072501085313249671164201789117302115988666;
    
    uint256 constant IC49x = 3743698900423818072534690274345755120738260474810231876427299165988142665860;
    uint256 constant IC49y = 12130931834134819376167421485418297180968636285838261015886839333918152150458;
    
    uint256 constant IC50x = 13506715418478204351710548054381206216686895626892324628657130046651407132043;
    uint256 constant IC50y = 10165296031233421190067805423875599064663322306129151201622305234418492065875;
    
    uint256 constant IC51x = 3951442926973226825393146438078129819839192947200760000699435620772764978309;
    uint256 constant IC51y = 14262912478904177301269979664732744387497115874454171208367179790794987331056;
    
    uint256 constant IC52x = 808906172494019538191308328127318357772921742653386483389355170032470130658;
    uint256 constant IC52y = 9861071971501929171506140545169657692602114274373243572253409819367929111246;
    
 
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
