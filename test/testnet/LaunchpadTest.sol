// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../src/Launchpad.sol";
import "forge-std/console2.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

contract LaunchpadTest is Test {
    Launchpad public launchpad;
    MockUSDC public usdc;
    address public constant ADMIN = 0xbbCff2Fcf443f54e84ce93d23C679ae8F626cAAC;
    address public constant UNISWAP = 0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3;

    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");

    function setUp() public {
        vm.startPrank(ADMIN);
        // Create fork of Sepolia
        vm.createSelectFork("https://sepolia.infura.io/v3/d670ac7f22c94d45a4a8729e2daf865a");

        // Deploy USDC token
        usdc = new MockUSDC();

        // Deploy Launchpad implementation
        Launchpad implementation = new Launchpad();

        // Deploy proxy
        bytes memory data = abi.encodeWithSelector(Launchpad.initialize.selector, address(usdc), UNISWAP);

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), data);
        launchpad = Launchpad(address(proxy));
        // Fund test users with USDC
        usdc.mint(user1, 10_000_000 * 10 ** usdc.decimals());
        usdc.mint(user2, 10_000_000 * 10 ** usdc.decimals());
        usdc.mint(user3, 10_000_000 * 10 ** usdc.decimals());
        vm.stopPrank();
    }

    function testCompleteFundraiseFlow() public {
        uint256 targetFunding = 500_000 * 10 ** 6; // 500K USDC
        uint256 startTime = block.timestamp + 1 days;
        string memory tokenName = "nuketTK";
        string memory tokenSymbol = "NTK";

        vm.prank(ADMIN);
        launchpad.createFundraise(targetFunding, startTime, tokenName, tokenSymbol);

        // Move time forward to start time
        vm.warp(startTime + 1);

        uint256 maxDepositPerUser = 10_000 * 10 ** 6; // 10k USDC max per user
        uint256 currentTotal = 0;
        bool fundraiserCompleted = false;

        // Array of users for easy iteration
        address[] memory users = new address[](3);
        users[0] = user1;
        users[1] = user2;
        users[2] = user3;

        // Continue depositing until fundraiser is complete
        while (!fundraiserCompleted) {
            for (uint256 i = 0; i < users.length; i++) {
                address currentUser = users[i];
                uint256 userDeposit = maxDepositPerUser;

                // Check if this deposit would exceed target
                if (currentTotal + userDeposit > targetFunding) {
                    userDeposit = targetFunding - currentTotal;
                }

                // Skip if no more funds needed
                if (userDeposit == 0) {
                    fundraiserCompleted = true;
                    break;
                }

                // Make deposit
                vm.startPrank(currentUser);
                usdc.approve(address(launchpad), userDeposit);
                launchpad.purchaseTokens(1, userDeposit);
                vm.stopPrank();

                // Update total
                currentTotal += userDeposit;

                // Check if fundraiser is complete
                (,,, uint256 tokensSold, bool isCompleted,,,) = launchpad.getFundraiser(1);
                if (isCompleted) {
                    fundraiserCompleted = true;
                    break;
                }
            }
        }

        // Verify final state
        (, uint256 targetFund, uint256 currentFunding, uint256 tokensSold, bool isCompleted, address tokenAddr,,) =
            launchpad.getFundraiser(1);
        uint256 targetTokensSold = launchpad.TARGET_TOKENS_SOLD();
        assertEq(tokensSold, targetTokensSold);
        assertEq(currentFunding, targetFund);
        assertTrue(isCompleted);
        IERC20 token = IERC20(tokenAddr);
        // Verify user balances
        for (uint256 i = 0; i < users.length; i++) {
            assertTrue(launchpad.userPurchases(1, users[i]) > 0);
        }

        // Store initial user purchase amounts
        uint256[] memory initialPurchases = new uint256[](users.length);
        for (uint256 i = 0; i < users.length; i++) {
            initialPurchases[i] = launchpad.userPurchases(1, users[i]);
            assertTrue(initialPurchases[i] > 0, "User should have tokens to claim");
        }

        // Claim tokens for each user and verify
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 expectedTokens = initialPurchases[i];

            uint256 balanceBefore = token.balanceOf(user);

            vm.prank(user);
            launchpad.claimTokens(1);

            uint256 balanceAfter = token.balanceOf(user);

            // Verify user received correct amount of tokens
            assertEq(balanceAfter - balanceBefore, expectedTokens, "Incorrect tokens claimed");

            // Verify purchase amount was reset to 0
            assertEq(launchpad.userPurchases(1, user), 0, "Purchase amount should be reset");
        }
    }
}
