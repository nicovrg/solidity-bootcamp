# zk README

**Example runs for both circuits stored in testruns.txt**

## Intro

* We need a way to proof that the user had selected a "spell" which is represented by a number between 1 and 3.

* We need a way to reveal the selected spell of the previous case

## Approach

We created two identical circuits: 
* select_spell
* cast_spell
 
Both are identical except that in "cast_spell" the input signal representing the spell, is public. 

They both mimc hash the selected spell and a secret that is a number known by the user to avoid reverse calculation since the spell is known to be a number between 1 and 3.

Since they both do the same operation, to "cast" or reveal a selected spell, the output signal of running the same inputs signals on both circuits are compared. When the match, this means that the proof presented with "select_spell" was created with the private signal that "cast_spell" has defined as a public signal. Meaning:
* spell used privately in "select_spell" == spell used publicly in "cast_spell" => the "spell" is revealed

### compileGenKeyContract.sh

This script should only be run once since it:

* Compiles de circom circuit
* generates zkey file used for generating proofs
* generates verifying Solidity contract

### witnessAndProof.sh

This script should be run everytime the input is changed to generate a new witness and proof:

* Inputs signals are set on input.json
* pi's are stored in proof.json 
* public signals to be used as inputs for the verifier are stored in public.json
* both the proof and the verifiers input are stored ready to be used in "parameters.txt"

### Notes

* circom, circomlib and snarkjs are required
* ptau hasta powers of tau as verified setup, running ptau.sh will rewrite this
* Order of execution in case of wanting to re generate every file from starting circuit: 
    * ptau.sh -> add pot12_final.ptau to each circuit folder -> run compileGenKeyContract.sh once -> run witnessAndProof.sh for each input you want to generate proof

### TODO

Script everything in a convinent way for testing