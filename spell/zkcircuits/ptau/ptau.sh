#!/bin/bash

# 1. Powers of tau -- TODO: IF ptau already done do not calculate again. 

echo "-----  Create new powersoftau ceremony -----"
snarkjs powersoftau new bn128 12 pot12_0000.ptau -v

echo "-----  Contribute to the created ceremony -----"
snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="First contribution" -v

echo "-----  Second contribution to the created ceremony -----"
snarkjs powersoftau contribute pot12_0001.ptau pot12_0002.ptau --name="Second contribution" -v -e="some random text"

echo "-----  Third contribution to the creatd from third party -----"
snarkjs powersoftau export challenge pot12_0002.ptau challenge_0003
snarkjs powersoftau challenge contribute bn128 challenge_0003 response_0003 -e="some random text"
snarkjs powersoftau import response pot12_0002.ptau response_0003 pot12_0003.ptau -n="Third contribution name"

echo "-----  Verify up to this point -----"
snarkjs powersoftau verify pot12_0003.ptau

echo "-----  Apply random beacon -----"
snarkjs powersoftau beacon pot12_0003.ptau pot12_beacon.ptau 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon"

# 2. Phase 2 

echo "-----  Prepare to the phase 2 -----"
snarkjs powersoftau prepare phase2 pot12_beacon.ptau pot12_final.ptau -v

echo "-----  Verify final ptau -----"
snarkjs powersoftau verify pot12_final.ptau


#$SHELL