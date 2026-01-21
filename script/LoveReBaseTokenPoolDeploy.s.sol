// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {LoveReBaseToken} from "../src/LoveReBaseToken.sol";
import {ILoveReBaseToken} from "../src/interfaces/ILoveReBaseToken.sol";
import {LoveReBaseTokenPool} from "../src/LoveReBaseTokenPool.sol";
import {
    CCIPLocalSimulatorFork,
    Register
} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {
    RegistryModuleOwnerCustom
} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {
    TokenAdminRegistry
} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {
    IERC20
} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

contract LoveReBaseTokenPoolDeploy is Script {
    function run(
        string memory _symbol
    )
        external
        returns (
            LoveReBaseToken,
            LoveReBaseTokenPool,
            Register.NetworkDetails memory
        )
    {
        CCIPLocalSimulatorFork ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        Register.NetworkDetails
            memory sepoliaNetworkDetails = ccipLocalSimulatorFork
                .getNetworkDetails(block.chainid);
        vm.startBroadcast();
        LoveReBaseToken loveReBaseToken = new LoveReBaseToken(_symbol);

        LoveReBaseTokenPool pool = new LoveReBaseTokenPool(
            IERC20(address(loveReBaseToken)),
            new address[](0),
            sepoliaNetworkDetails.rmnProxyAddress,
            sepoliaNetworkDetails.routerAddress
        );
        loveReBaseToken.grantMintAndBurnRole(address(pool));

        RegistryModuleOwnerCustom registryModuleOwnerCustomSepolia = RegistryModuleOwnerCustom(
                sepoliaNetworkDetails.registryModuleOwnerCustomAddress
            );
        //注册管理员
        registryModuleOwnerCustomSepolia.registerAdminViaOwner(
            address(loveReBaseToken)
        );
        //确认管理员
        TokenAdminRegistry tokenAdminRegistrySepolia = TokenAdminRegistry(
            sepoliaNetworkDetails.tokenAdminRegistryAddress
        );
        tokenAdminRegistrySepolia.acceptAdminRole(address(loveReBaseToken));
        //关联代币与代币池
        tokenAdminRegistrySepolia.setPool(
            address(loveReBaseToken),
            address(pool)
        );
        vm.stopBroadcast();

        return (loveReBaseToken, pool, sepoliaNetworkDetails);
    }
}
