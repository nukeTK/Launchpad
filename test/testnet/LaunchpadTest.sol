// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "forge-std/Test.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
// import "../../src/Launchpad.sol";
// import "../../src/libraries/CustomBondingCurve.sol";

// contract MockUSDC is ERC20 {
//     constructor() ERC20("Mock USDC", "USDC") {
//         _mint(msg.sender, 1_000_000 * 10 ** decimals());
//     }

//     function mint(address to, uint256 amount) public {
//         _mint(to, amount);
//     }
// }

// contract LaunchpadTest is Test {
//     Launchpad public launchpad;
//     MockUSDC public usdc;
//     address public constant ADMIN = 0xbbCff2Fcf443f54e84ce93d23C679ae8F626cAAC;
//     address public constant UNISWAP = 0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3;

//     address public user1 = makeAddr("user1");
//     address public user2 = makeAddr("user2");
//     address public user3 = makeAddr("user3");

//     function setUp() public {
//         vm.startPrank(ADMIN);
//         // Create fork of Sepolia
//         vm.createSelectFork("https://sepolia.infura.io/v3/d670ac7f22c94d45a4a8729e2daf865a");

//         // Deploy USDC token
//         usdc = new MockUSDC();

//         // Deploy Launchpad implementation
//         Launchpad implementation = new Launchpad();

//         // Deploy proxy
//         bytes memory data = abi.encodeWithSelector(Launchpad.initialize.selector, address(usdc), UNISWAP);

//         ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), data);
//         launchpad = Launchpad(address(proxy));

//         // Fund test users with USDC
//         usdc.transfer(user1, 10_000 * 10 ** usdc.decimals());
//         usdc.transfer(user2, 10_000 * 10 ** usdc.decimals());
//         usdc.transfer(user3, 10_000 * 10 ** usdc.decimals());
//         vm.stopPrank();
//     }

//     // // Test createFundraise function
//     // function testCreateFundraise() public {
//     //     uint256 targetFunding = 200_000 * 10 ** 6; // 200K USDC
//     //     string memory tokenName = "Test Token";
//     //     string memory tokenSymbol = "TEST";
//     //     uint256 startTime = block.timestamp + 1 days;

//     //     vm.prank(user1);
//     //     launchpad.createFundraise(targetFunding, startTime, tokenName, tokenSymbol);

//     //     (
//     //         address creator,
//     //         uint256 target,
//     //         uint256 current,
//     //         uint256 sold,
//     //         bool completed,
//     //         address token,
//     //         uint256 start,
//     //         uint256 end,
//     //         uint256 basePrice,
//     //         uint256 slope
//     //     ) = launchpad.getFundraiser(1);

//     //     assertEq(creator, user1);
//     //     assertEq(target, targetFunding);
//     //     assertEq(current, 0);
//     //     assertEq(sold, 0);
//     //     assertFalse(completed);
//     //     assertTrue(token != address(0));
//     //     assertEq(start, startTime);
//     //     assertEq(end, 0);
//     //     assertTrue(basePrice > 0);
//     //     assertTrue(slope > 0);
//     // }

//     // function testCreateFundraiseInvalidTarget() public {
//     //     // Test minimum target
//     //     vm.expectRevert("Target funding too low");
//     //     launchpad.createFundraise(199_999 * 10 ** 6, block.timestamp + 1 days, "Test", "TEST");

//     //     // Test maximum target
//     //     vm.expectRevert("Target funding too high");
//     //     launchpad.createFundraise(1_000_000_001 * 10 ** 6, block.timestamp + 1 days, "Test", "TEST");

//     //     // Test non-whole USDC amount
//     //     vm.expectRevert("Target funding must be in whole USDC");
//     //     launchpad.createFundraise(200_000 * 10 ** 6 + 1, block.timestamp + 1 days, "Test", "TEST");

//     //     // Test start time in past
//     //     vm.expectRevert("Start time must be in the future");
//     //     launchpad.createFundraise(200_000 * 10 ** 6, block.timestamp - 1, "Test", "TEST");
//     // }

//     // // Test purchaseTokens function
//     // function testPurchaseTokens() public {
//     //     // Create fundraiser
//     //     uint256 targetFunding = 200_000 * 10 ** 6; // 200K USDC
//     //     uint256 startTime = block.timestamp + 1 days;
//     //     launchpad.createFundraise(targetFunding, startTime, "Test", "TEST");

//     //     // Try to purchase before start time
//     //     vm.prank(user1);
//     //     usdc.approve(address(launchpad), 10 ** 6);
//     //     vm.expectRevert("Fundraise not started");
//     //     launchpad.purchaseTokens(1, 10 ** 6);

//     //     // Move time forward
//     //     vm.warp(startTime + 1);

//     //     // Purchase tokens
//     //     vm.prank(user1);
//     //     launchpad.purchaseTokens(1, 10 ** 6);

//     //     // Verify purchase
//     //     assertEq(launchpad.userPurchases(1, user1), 10 ** 18); // 1 token with 18 decimals
//     //     assertEq(usdc.balanceOf(address(launchpad)), 10 ** 6);

//     //     // Purchase more tokens
//     //     vm.prank(user2);
//     //     usdc.approve(address(launchpad), 10 ** 6);
//     //     launchpad.purchaseTokens(1, 10 ** 6);

//     //     // Verify second purchase
//     //     assertEq(launchpad.userPurchases(1, user2), 10 ** 18);
//     //     assertEq(usdc.balanceOf(address(launchpad)), 2 * 10 ** 6);
//     // }

//     // function testPurchaseTokensEdgeCases() public {
//     //     // Create fundraiser
//     //     uint256 targetFunding = 200_000 * 10 ** 6;
//     //     uint256 startTime = block.timestamp + 1 days;
//     //     launchpad.createFundraise(targetFunding, startTime, "Test", "TEST");

//     //     // Test purchasing from inactive fundraiser
//     //     vm.prank(user1);
//     //     usdc.approve(address(launchpad), 10_000 * 10 ** 6);
//     //     launchpad.pause();
//     //     vm.expectRevert("Pausable: paused");
//     //     launchpad.purchaseTokens(1, 10_000 * 10 ** 6);
//     //     launchpad.unpause();

//     //     // Test purchasing with insufficient allowance
//     //     vm.prank(user1);
//     //     usdc.approve(address(launchpad), 0);
//     //     vm.expectRevert();
//     //     launchpad.purchaseTokens(1, 10_000 * 10 ** 6);

//     //     // Test purchasing with zero amount
//     //     vm.prank(user1);
//     //     usdc.approve(address(launchpad), 10_000 * 10 ** 6);
//     //     vm.expectRevert("Amount too small");
//     //     launchpad.purchaseTokens(1, 0);

//     //     // Test purchasing with insufficient balance
//     //     vm.prank(user1);
//     //     usdc.transfer(user2, usdc.balanceOf(user1));
//     //     vm.expectRevert();
//     //     launchpad.purchaseTokens(1, 10_000 * 10 ** 6);

//     //     // Test purchasing after completion
//     //     vm.warp(startTime + 1);
//     //     vm.prank(user1);
//     //     usdc.approve(address(launchpad), targetFunding);
//     //     launchpad.purchaseTokens(1, targetFunding);
//     //     vm.expectRevert("Fundraise completed");
//     //     launchpad.purchaseTokens(1, 10 ** 6);
//     // }

//     // function testPurchaseTokensReentrancy() public {
//     //     // Create fundraiser
//     //     uint256 targetFunding = 200_000 * 10 ** 6;
//     //     uint256 startTime = block.timestamp + 1 days;
//     //     launchpad.createFundraise(targetFunding, startTime, "Test", "TEST");

//     //     // Setup reentrancy attack
//     //     vm.prank(user1);
//     //     usdc.approve(address(launchpad), type(uint256).max);

//     //     // Attempt reentrancy
//     //     vm.warp(startTime + 1);
//     //     vm.prank(user1);
//     //     launchpad.purchaseTokens(1, 10_000 * 10 ** 6);
//     //     // Should not be able to reenter due to nonReentrant modifier
//     // }

//     // Test claimTokens function
//     // function test_purchaseTokens_exceedsTargetTokens() public {
//     //     // Create and complete fundraiser
//     //     uint256 targetFunding = 200_000 * 10 ** 6;
//     //     uint256 startTime = block.timestamp + 1 days;
//     //     launchpad.createFundraise(targetFunding, startTime, "Test", "TEST");

//     //     // Purchase tokens
//     //     vm.warp(startTime + 1);
//     //     vm.startPrank(user1);
//     //     usdc.approve(address(launchpad), targetFunding);
//     //     vm.expectRevert("Exceeds target tokens");
//     //     launchpad.purchaseTokens(1, targetFunding);
//     //     vm.stopPrank();
//     // }

//     function test_ClaimTokensEdgeCases() public {
//         // Create fundraiser
//         uint256 targetFunding = 500_000 * 10 ** 6;
//         uint256 startTime = block.timestamp + 1 days;
//         launchpad.createFundraise(targetFunding, startTime, "Test", "TEST");

//         // Test claiming from active fundraiser
//         vm.expectRevert("Fundraise still active");
//         launchpad.claimTokens(1);

//         // Test claiming with no tokens
//         // Purchase tokens in a loop to reach target funding
//         for (uint256 i = 0; i < 9; i++) {
//             vm.warp(startTime + 1);
//             vm.startPrank(user1);
//             console2.log("currentPrice", launchpad.getCurrentPrice(1));
//             usdc.approve(address(launchpad), 50_000 * 1e6);
//             launchpad.purchaseTokens(1, 50_000 * 1e6);
//             console2.log("user balance", launchpad.userPurchases(1, user1));
//             vm.stopPrank();
//         }

//         vm.startPrank(user1);
//         usdc.approve(address(launchpad), 90_000 * 1e6);
//         launchpad.purchaseTokens(1, 90_000 * 1e6);
//         vm.stopPrank();


//         // Test claiming twice
//         // vm.prank(user1);
//         //launchpad.claimTokens(1);
//         (
//             address creator,
//             uint256 targetFunding_,
//             uint256 currentFunding,
//             uint256 tokensSold,
//             bool isCompleted,
//             address tokenAddress,
//             uint256 startTime_,
//             uint256 endTime,
//             uint256 basePrice,
//             uint256 slope
//         ) = launchpad.getFundraiser(1);
//         console2.log("token", tokenAddress);
//         console2.log("currentFunding", currentFunding);
//         console2.log("tokensSold", tokensSold);
//         console2.log("isCompleted", isCompleted);
//         console2.log("startTime", startTime);
//         console2.log("endTime", endTime);
//         console2.log("basePrice", basePrice);
//         console2.log("slope", slope);
//     }

//     // // Test completeFundraise function
//     // function testCompleteFundraise() public {
//     //     // Create fundraiser
//     //     uint256 targetFunding = 200_000 * 10 ** 6;
//     //     uint256 startTime = block.timestamp + 1 days;
//     //     launchpad.createFundraise(targetFunding, startTime, "Test", "TEST");

//     //     // Complete fundraiser
//     //     vm.warp(startTime + 1);
//     //     vm.prank(user1);
//     //     usdc.approve(address(launchpad), targetFunding);
//     //     launchpad.purchaseTokens(1, targetFunding);

//     //     // Verify completion
//     //     (,,, uint256 sold, bool completed, address token, uint256 start, uint256 end,,) = launchpad.getFundraiser(1);
//     //     assertTrue(completed);
//     //     assertEq(end, block.timestamp);
//     //     assertTrue(end > start);
//     // }

//     // function testCompleteFundraiseDistribution() public {
//     //     // Create fundraiser
//     //     uint256 targetFunding = 200_000 * 10 ** 6;
//     //     uint256 startTime = block.timestamp + 1 days;
//     //     launchpad.createFundraise(targetFunding, startTime, "Test", "TEST");

//     //     // Complete fundraiser
//     //     vm.warp(startTime + 1);
//     //     vm.prank(user1);
//     //     usdc.approve(address(launchpad), targetFunding);
//     //     launchpad.purchaseTokens(1, targetFunding);

//     //     // Verify token distribution
//     //     (,,, uint256 sold, bool completed, address token, uint256 start, uint256 end,,) = launchpad.getFundraiser(1);
//     //     LaunchpadToken tokenContract = LaunchpadToken(token);

//     //     // Check creator tokens
//     //     assertEq(tokenContract.balanceOf(user1), launchpad.CREATOR_TOKENS());

//     //     // Check platform fee tokens
//     //     assertEq(tokenContract.balanceOf(ADMIN), launchpad.PLATFORM_FEE_TOKENS());

//     //     // Check liquidity tokens
//     //     assertEq(tokenContract.balanceOf(address(launchpad)), 0);

//     //     // Check USDC distribution
//     //     assertEq(usdc.balanceOf(user1), targetFunding * 50 / 100); // 50% to creator
//     //     assertEq(usdc.balanceOf(UNISWAP), targetFunding * 50 / 100); // 50% to liquidity
//     // }

//     // // Test pause/unpause functionality
//     // function testPauseUnpause() public {
//     //     // Test pause
//     //     vm.prank(ADMIN);
//     //     launchpad.pause();
//     //     assertTrue(launchpad.paused());

//     //     // Test unpause
//     //     vm.prank(ADMIN);
//     //     launchpad.unpause();
//     //     assertFalse(launchpad.paused());
//     // }

//     // function testPauseUnpauseAuthorization() public {
//     //     // Test non-owner pause
//     //     vm.prank(user1);
//     //     vm.expectRevert("Ownable: caller is not the owner");
//     //     launchpad.pause();

//     //     // Test non-owner unpause
//     //     vm.prank(user1);
//     //     vm.expectRevert("Ownable: caller is not the owner");
//     //     launchpad.unpause();
//     // }
// }
