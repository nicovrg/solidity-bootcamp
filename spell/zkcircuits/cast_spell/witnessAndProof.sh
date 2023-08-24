#!/bin/bash

# Variable to store the name of the circuit
CIRCUIT=castSpell

# In case there is a circuit name as an input
if [ "$1" ]; then
    CIRCUIT=$1
fi

# Generate the witness.wtns -- MUST BE DONE WHEN INPUT CHANGES 
echo "----- Generating witness -----"
node ${CIRCUIT}_js/generate_witness.js ${CIRCUIT}_js/${CIRCUIT}.wasm input.json ${CIRCUIT}_js/witness.wtns

# Copy witness to main circuit folder
cd ${CIRCUIT}_js
cp witness.wtns ../witness.wtns
cd ..

# 3. Prove ----- FROM HERE TO CREATE PROOF

echo "----- Generate zk-proof -----"
# Generate a zk-proof associated to the circuit and the witness. This generates proof.json and public.json
snarkjs groth16 prove ${CIRCUIT}_final.zkey ${CIRCUIT}_js/witness.wtns proof.json public.json

echo "----- Verify the proof -----"
# Verify the proof
snarkjs groth16 verify verification_key.json public.json proof.json

echo "----- Generate and print parameters of call -----"
# Generate and print parameters of call
snarkjs generatecall | tee parameters.txt

#$SHELL