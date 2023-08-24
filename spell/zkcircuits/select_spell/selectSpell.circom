pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/mimcsponge.circom";

template selectSpell() {
    
    // The public inputs
    signal input spell; //spell
    signal input spellSecret; //secret key
    signal output hashed;


    // Hash the spell and check if the result matches the hash.
    component hasher = MiMCSponge(2,220,1);
    hasher.ins[0] <== spell;
    hasher.ins[1] <== spellSecret;
    hasher.k <== 0;

    hashed <== hasher.outs[0] ;


 }

component main = selectSpell();