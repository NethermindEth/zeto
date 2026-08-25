pragma circom 2.2.2;

include "../../../circuits/lib/check-babyjub-public-key.circom";

component main { public [ publicKey ] } = CheckBabyJubPublicKey();