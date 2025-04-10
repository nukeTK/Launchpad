// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "forge-std/Test.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
// import "../../src/Launchpad.sol";
// import "../../src/libraries/BancorBondingCurve.sol";

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
//     //     uint256 targetFunding = 100000 * 10**6; // 100K USDC
//     //     string memory tokenName = "Test Token";
//     //     string memory tokenSymbol = "TEST";

//     //     vm.prank(user1);
//     //     launchpad.createFundraise(targetFunding, tokenName, tokenSymbol);

//     //     (address creator, uint256 target, uint256 current, uint256 sold, bool completed, address token, uint256
//     // start, uint256 end) =
//     //         launchpad.getFundraiser(0);

//     //     assertEq(creator, user1);
//     //     assertEq(target, targetFunding);
//     //     assertEq(current, 0);
//     //     assertEq(sold, 0);
//     //     assertFalse(completed);
//     //     assertTrue(token != address(0));
//     //     assertEq(start, block.timestamp);
//     //     assertEq(end, 0);
//     // }

//     // function testCreateFundraiseInvalidTarget() public {
//     //     // Test minimum target
//     //     vm.expectRevert("Target funding too low");
//     //     launchpad.createFundraise(99999 * 10**6, "Test", "TEST");

//     //     // Test maximum target
//     //     vm.expectRevert("Target funding too high");
//     //     launchpad.createFundraise(1000000001 * 10**6, "Test", "TEST");

//     //     // Test non-whole USDC amount
//     //     vm.expectRevert("Target funding must be in whole USDC");
//     //     launchpad.createFundraise(100000 * 10**6 + 1, "Test", "TEST");
//     // }

//     // Test purchaseTokens function
//     function testPurchaseTokens() public {
//         // Create fundraiser
//         uint256 targetFunding = 100_000 * 10 ** 6; // 100K USDC
//         launchpad.createFundraise(targetFunding, "Test", "TEST");

//         (,, uint256 current, uint256 sold, bool completed, address token, uint256 start, uint256 end) =
//             launchpad.getFundraiser(1);

//         // Approve USDC spending
//         vm.startPrank(user1);
//         usdc.approve(address(launchpad), 10_000 * 10 ** 6);
//         launchpad.purchaseTokens(1, 10_000 * 10 ** 6);
//         console2.log("balance", launchpad.userPurchases(1, user1));
//         vm.stopPrank();

//         // vm.startPrank(user2);
//         // usdc.approve(address(launchpad), 10_000 * 10 ** 6);
//         // launchpad.purchaseTokens(1, 10_000 * 10 ** 6);
//         // IERC20(token).balanceOf(user2);
//         // vm.stopPrank();

//         // vm.startPrank(user3);
//         // usdc.approve(address(launchpad), 9000 * 10 ** 6);
//         // launchpad.purchaseTokens(1, 9000 * 10 ** 6);
//         // IERC20(token).balanceOf(user3);
//         // vm.stopPrank();

//         (,, uint256 current1, uint256 sold1, bool completed1, address token1, uint256 start1, uint256 end1) =
//             launchpad.getFundraiser(1);

//         console.log("current1", current1);
//         console.log("sold1", sold1);
//         console.log("completed1", completed1);
//         console.log("token1", token);
//         console.log("start1", start);
//         console.log("end1", end);
//     }

//     // function testPurchaseTokensEdgeCases() public {
//     //     // Create fundraiser
//     //     uint256 targetFunding = 100000 * 10**6;
//     //     launchpad.createFundraise(targetFunding, "Test", "TEST");

//     //     // Test purchasing from inactive fundraiser
//     //     vm.prank(user1);
//     //     usdc.approve(address(launchpad), 10000 * 10**6);
//     //     launchpad.pause();
//     //     vm.expectRevert("Pausable: paused");
//     //     launchpad.purchaseTokens(0, 10000 * 10**6);
//     //     launchpad.unpause();

//     //     // Test purchasing with insufficient allowance
//     //     vm.prank(user1);
//     //     usdc.approve(address(launchpad), 0);
//     //     vm.expectRevert();
//     //     launchpad.purchaseTokens(0, 10000 * 10**6);

//     //     // Test purchasing with zero amount
//     //     vm.prank(user1);
//     //     usdc.approve(address(launchpad), 10000 * 10**6);
//     //     vm.expectRevert("Amount too small");
//     //     launchpad.purchaseTokens(0, 0);
//     // }

//     // function testPurchaseTokensReentrancy() public {
//     //     // Create fundraiser
//     //     uint256 targetFunding = 100000 * 10**6;
//     //     launchpad.createFundraise(targetFunding, "Test", "TEST");

//     //     // Setup reentrancy attack
//     //     vm.prank(user1);
//     //     usdc.approve(address(launchpad), type(uint256).max);

//     //     // Attempt reentrancy
//     //     vm.prank(user1);
//     //     launchpad.purchaseTokens(0, 10000 * 10**6);
//     //     // Should not be able to reenter due to nonReentrant modifier
//     // }

//     // // Test claimTokens function
//     // function testClaimTokens() public {
//     //     // Create and complete fundraiser
//     //     uint256 targetFunding = 100000 * 10**6;
//     //     launchpad.createFundraise(targetFunding, "Test", "TEST");

//     //     // Purchase tokens
//     //     vm.prank(user1);
//     //     usdc.approve(address(launchpad), targetFunding);
//     //     vm.prank(user1);
//     //     launchpad.purchaseTokens(0, targetFunding);

//     //     // Claim tokens
//     //     vm.prank(user1);
//     //     launchpad.claimTokens(0);

//     //     // Verify tokens were claimed
//     //     (,,, uint256 sold, bool completed, address token, uint256 start, uint256 end) =
//     //         launchpad.getFundraiser(0);
//     //     assertEq(IERC20(token).balanceOf(user1), sold);
//     // }

//     // function testClaimTokensEdgeCases() public {
//     //     // Create fundraiser
//     //     uint256 targetFunding = 100000 * 10**6;
//     //     launchpad.createFundraise(targetFunding, "Test", "TEST");

//     //     // Test claiming from active fundraiser
//     //     vm.expectRevert("Fundraise still active");
//     //     launchpad.claimTokens(0);

//     //     // Test claiming with no tokens
//     //     vm.prank(user1);
//     //     usdc.approve(address(launchpad), targetFunding);
//     //     vm.prank(user1);
//     //     launchpad.purchaseTokens(0, targetFunding);
//     //     vm.prank(user2);
//     //     vm.expectRevert("No tokens to claim");
//     //     launchpad.claimTokens(0);
//     // }

//     // // Test completeFundraise function
//     // function testCompleteFundraise() public {
//     //     // Create fundraiser
//     //     uint256 targetFunding = 100000 * 10**6;
//     //     launchpad.createFundraise(targetFunding, "Test", "TEST");

//     //     // Complete fundraiser
//     //     vm.prank(user1);
//     //     usdc.approve(address(launchpad), targetFunding);
//     //     vm.prank(user1);
//     //     launchpad.purchaseTokens(0, targetFunding);

//     //     // Verify completion
//     //     (,,, uint256 sold, bool completed, address token, uint256 start, uint256 end) =
//     //         launchpad.getFundraiser(0);
//     //     assertTrue(completed);
//     //     assertEq(end, block.timestamp);
//     //     assertTrue(end > start);
//     // }

//     // function testCompleteFundraiseDistribution() public {
//     //     // Create fundraiser
//     //     uint256 targetFunding = 100000 * 10**6;
//     //     launchpad.createFundraise(targetFunding, "Test", "TEST");

//     //     // Complete fundraiser
//     //     vm.prank(user1);
//     //     usdc.approve(address(launchpad), targetFunding);
//     //     vm.prank(user1);
//     //     launchpad.purchaseTokens(0, targetFunding);

//     //     // Verify token distribution
//     //     (,,, uint256 sold, bool completed, address token, uint256 start, uint256 end) =
//     //         launchpad.getFundraiser(0);
//     //     LaunchpadToken tokenContract = LaunchpadToken(token);

//     //     // Check creator tokens
//     //     assertEq(tokenContract.balanceOf(user1), launchpad.CREATOR_TOKENS());

//     //     // Check platform fee tokens
//     //     assertEq(tokenContract.balanceOf(ADMIN), launchpad.PLATFORM_FEE_TOKENS());

//     //     // Check liquidity tokens
//     //     assertEq(tokenContract.balanceOf(address(launchpad)), 0);
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
