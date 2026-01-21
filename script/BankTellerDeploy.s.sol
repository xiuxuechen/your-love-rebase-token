// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {BankTeller} from "../src/BankTeller.sol";
import {LoveReBaseToken} from "../src/LoveReBaseToken.sol";
import {ILoveReBaseToken} from "../src/interfaces/ILoveReBaseToken.sol";

contract BankTellerDeploy is Script {
    function deployBankTeller(
        address _LoveReBaseToken
    ) public returns (BankTeller) {
        BankTeller bankTeller = new BankTeller(
            ILoveReBaseToken(_LoveReBaseToken)
        );
        ILoveReBaseToken(_LoveReBaseToken).grantMintAndBurnRole(
            address(bankTeller)
        );
        return bankTeller;
    }

    function run(address _tokenAddress) external returns (BankTeller) {
        uint256 deployerPrivateKey;
        if (block.chainid == vm.envUint("LOCAL_CHAIN_ID")) {
            deployerPrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        } else {
            deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
        }
        vm.startBroadcast(deployerPrivateKey);
        BankTeller bankTeller = deployBankTeller(_tokenAddress);
        ILoveReBaseToken(_tokenAddress).grantMintAndBurnRole(
            address(bankTeller)
        );
        vm.stopBroadcast();
        return bankTeller;
    }
}
