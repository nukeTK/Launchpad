// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/MockUSDC.sol";
import "../src/Launchpad.sol";

contract DeployScript is Script {
    address public constant UNISWAP = 0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3;

    function run() external {
        vm.startBroadcast();

        // Deploy Mock USDC
        MockUSDC mockUSDC = new MockUSDC();
        console2.log("MockUSDC deployed at:", address(mockUSDC));

        // Deploy Launchpad Implementation
        Launchpad launchpadImpl = new Launchpad();
        console2.log("Launchpad Implementation deployed at:", address(launchpadImpl));

        // Deploy Proxy
        bytes memory data = abi.encodeWithSelector(Launchpad.initialize.selector, address(mockUSDC), UNISWAP);
        ERC1967Proxy proxy = new ERC1967Proxy(address(launchpadImpl), data);
        console2.log("Launchpad Proxy deployed at:", address(proxy));

        // Cast the proxy to Launchpad
        Launchpad launchpad = Launchpad(address(proxy));
        console2.log("Launchpad (proxy) owner:", launchpad.owner());

        vm.stopBroadcast();
    }
}
