// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Script} from "forge-std/Script.sol";
import {MockIDRX} from "../src/MockIDRX.sol";
import {console2} from "forge-std/console2.sol";

contract MockIDRXScript is Script {
    MockIDRX public mockIDRX;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("Deploying MockIDRX with deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        mockIDRX = new MockIDRX(deployer);

        vm.stopBroadcast();

        console2.log("MockIDRX deployed at:", address(mockIDRX));
        console2.log("Deployer has DEFAULT_ADMIN_ROLE:", mockIDRX.hasRole(mockIDRX.DEFAULT_ADMIN_ROLE(), deployer));
        console2.log("Deployer has MINTER_ROLE:", mockIDRX.hasRole(mockIDRX.MINTER_ROLE(), deployer));
        console2.log("Deployer has PAUSER_ROLE:", mockIDRX.hasRole(mockIDRX.PAUSER_ROLE(), deployer));
        console2.log("Token name:", mockIDRX.name());
        console2.log("Token symbol:", mockIDRX.symbol());
        console2.log("Token decimals:", mockIDRX.decimals());
        console2.log("Max mint amount per tx:", mockIDRX.MAX_MINT_AMOUNT());
        console2.log("Total supply cap:", mockIDRX.cap());

        // Optional: Perform a test mint
        console2.log("\nPerforming test mint...");
        vm.broadcast(deployerPrivateKey);
        mockIDRX.mint(deployer, 1000 * 10**mockIDRX.decimals());
        console2.log("Test mint completed. Deployer balance:", mockIDRX.balanceOf(deployer));
    }
}
