#!/bin/bash

# Variable to store the name of the circuit
CIRCUIT=selectSpell

# In case there is a circuit name as an input
if [ "$1" ]; then
    CIRCUIT=$1
fi

# Compile the circuit
echo "----- Compiling -----"
circom ${CIRCUIT}.circom --r1cs --wasm --sym --c

echo "----- Generate .zkey file -----"
# Generate a .zkey file that will contain the proving and verification keys together with all phase 2 contributions
snarkjs groth16 setup ${CIRCUIT}.r1cs pot12_final.ptau ${CIRCUIT}_0000.zkey

echo "----- Contribute to the phase 2 of the ceremony -----"
# Contribute to the phase 2 of the ceremony
snarkjs zkey contribute ${CIRCUIT}_0000.zkey ${CIRCUIT}_final.zkey --name="1st Contributor Name" -v -e="some random text"

echo "----- Export the verification key -----"
# Export the verification key
snarkjs zkey export verificationkey ${CIRCUIT}_final.zkey verification_key.json

echo "----- Generate Solidity verifier -----"
# Generate a Solidity verifier that allows verifying proofs on Ethereum blockchain
snarkjs zkey export solidityverifier ${CIRCUIT}_final.zkey ${CIRCUIT}Verifier.sol
# Update the solidity version in the Solidity verifier
sed -i 's/0.6.11;/0.8.13;/g' ${CIRCUIT}Verifier.sol
# Update the contract name in the Solidity verifier
sed -i "s/contract Verifier/contract ${CIRCUIT^}Verifier/g" ${CIRCUIT}Verifier.sol

#$SHELL