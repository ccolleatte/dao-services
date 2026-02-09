// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/DAOMembership.sol";
import "../src/DAOGovernor.sol";
import "../src/DAOTreasury.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract DeployGovernance is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying contracts with account:", deployer);
        console.log("Account balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy DAOMembership
        console.log("\n1. Deploying DAOMembership...");
        DAOMembership membership = new DAOMembership(deployer);
        console.log("   DAOMembership deployed at:", address(membership));

        // Step 2: Deploy TimelockController
        console.log("\n2. Deploying TimelockController...");
        uint256 minDelay = 1 days;
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        proposers[0] = address(0); // Governor will be granted proposer role
        executors[0] = address(0); // Anyone can execute after timelock

        TimelockController timelock = new TimelockController(
            minDelay,
            proposers,
            executors,
            deployer
        );
        console.log("   TimelockController deployed at:", address(timelock));

        // Step 3: Deploy DAOGovernor
        console.log("\n3. Deploying DAOGovernor...");
        DAOGovernor governor = new DAOGovernor(membership, timelock);
        console.log("   DAOGovernor deployed at:", address(governor));

        // Step 4: Grant roles to Governor
        console.log("\n4. Granting timelock roles to Governor...");
        bytes32 PROPOSER_ROLE = timelock.PROPOSER_ROLE();
        bytes32 EXECUTOR_ROLE = timelock.EXECUTOR_ROLE();
        bytes32 CANCELLER_ROLE = timelock.CANCELLER_ROLE();

        timelock.grantRole(PROPOSER_ROLE, address(governor));
        timelock.grantRole(EXECUTOR_ROLE, address(governor));
        timelock.grantRole(CANCELLER_ROLE, address(governor));
        console.log("   Roles granted successfully");

        // Step 5: Deploy DAOTreasury
        console.log("\n5. Deploying DAOTreasury...");
        DAOTreasury treasury = new DAOTreasury(membership, deployer);
        console.log("   DAOTreasury deployed at:", address(treasury));

        // Step 6: Setup initial members (deployer as founder)
        console.log("\n6. Adding initial members...");
        membership.addMember(deployer, 4); // Founder rank
        console.log("   Deployer added as Founder (Rank 4)");

        // Step 7: Grant treasury roles
        console.log("\n7. Setting up Treasury roles...");
        treasury.grantRole(treasury.TREASURER_ROLE(), deployer);
        treasury.grantRole(treasury.SPENDER_ROLE(), deployer);
        console.log("   Treasury roles granted to deployer");

        vm.stopBroadcast();

        // Summary
        console.log("\n========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("DAOMembership:        ", address(membership));
        console.log("TimelockController:   ", address(timelock));
        console.log("DAOGovernor:          ", address(governor));
        console.log("DAOTreasury:          ", address(treasury));
        console.log("========================================");
        console.log("\nNext steps:");
        console.log("1. Add members via DAOMembership.addMember(address, rank)");
        console.log("2. Fund treasury by sending ETH to:", address(treasury));
        console.log("3. Create proposals via DAOGovernor.proposeWithTrack(...)");
        console.log("========================================\n");
    }
}
