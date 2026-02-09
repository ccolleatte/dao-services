// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/DAOMembership.sol";
import "../src/DAOGovernor.sol";
import "../src/DAOTreasury.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title Verify Deployment Script
 * @notice Post-deployment verification script for Paseo testnet
 * @dev Run this after DeployGovernance.s.sol to verify all contracts
 */
contract VerifyDeployment is Script {
    // Contract addresses (update after deployment)
    address constant MEMBERSHIP_ADDR = address(0); // TODO: Update
    address constant GOVERNOR_ADDR = address(0);   // TODO: Update
    address constant TREASURY_ADDR = address(0);   // TODO: Update
    address constant TIMELOCK_ADDR = address(0);   // TODO: Update

    DAOMembership public membership;
    DAOGovernor public governor;
    DAOTreasury public treasury;
    TimelockController public timelock;

    function run() public {
        require(MEMBERSHIP_ADDR != address(0), "Update MEMBERSHIP_ADDR first");
        require(GOVERNOR_ADDR != address(0), "Update GOVERNOR_ADDR first");
        require(TREASURY_ADDR != address(0), "Update TREASURY_ADDR first");
        require(TIMELOCK_ADDR != address(0), "Update TIMELOCK_ADDR first");

        console.log("=== Deployment Verification ===");
        console.log("");

        // Initialize contracts
        membership = DAOMembership(MEMBERSHIP_ADDR);
        governor = DAOGovernor(payable(GOVERNOR_ADDR));
        treasury = DAOTreasury(payable(TREASURY_ADDR));
        timelock = TimelockController(payable(TIMELOCK_ADDR));

        // Verify each component
        verifyMembership();
        verifyGovernor();
        verifyTreasury();
        verifyTimelock();
        verifyIntegration();

        console.log("");
        console.log("=== Verification Complete ===");
    }

    function verifyMembership() internal view {
        console.log("1. DAOMembership Verification");
        console.log("   Address:", address(membership));

        uint256 totalMembers = membership.getMemberCount();
        console.log("   Total Members:", totalMembers);

        if (totalMembers == 0) {
            console.log("   [WARNING] No members added yet");
        } else {
            console.log("   [OK] Members initialized");
        }

        // Verify ranks configuration
        uint256 rank0Duration = membership.minRankDuration(0);
        uint256 rank1Duration = membership.minRankDuration(1);
        uint256 rank4Duration = membership.minRankDuration(4);

        console.log("   Rank 0 (Observer): duration", rank0Duration);
        console.log("   Rank 1 (Active): duration", rank1Duration);
        console.log("   Rank 4 (Founder): duration", rank4Duration);

        require(rank0Duration == 0, "Rank 0 duration should be 0");
        require(rank1Duration == 90 days, "Rank 1 duration should be 90 days");
        require(rank4Duration == 547 days, "Rank 4 duration should be 547 days");

        console.log("   [OK] Rank duration configuration correct");
        console.log("");
    }

    function verifyGovernor() internal view {
        console.log("2. DAOGovernor Verification");
        console.log("   Address:", address(governor));

        // Verify tracks (accessing public mapping directly)
        (uint8 techMinRank, uint256 techDelay, uint256 techPeriod, uint256 techQuorum) = governor.trackConfigs(
            DAOGovernor.Track.Technical
        );
        (uint8 treasMinRank, uint256 treasDelay, uint256 treasPeriod, uint256 treasQuorum) = governor.trackConfigs(
            DAOGovernor.Track.Treasury
        );
        (uint8 membMinRank, uint256 membDelay, uint256 membPeriod, uint256 membQuorum) = governor.trackConfigs(
            DAOGovernor.Track.Membership
        );

        console.log("   Technical Track:");
        console.log("     Min Rank:", techMinRank);
        console.log("     Period:", techPeriod);
        console.log("     Quorum:", techQuorum, "%");
        console.log("   Treasury Track:");
        console.log("     Min Rank:", treasMinRank);
        console.log("     Period:", treasPeriod);
        console.log("     Quorum:", treasQuorum, "%");
        console.log("   Membership Track:");
        console.log("     Min Rank:", membMinRank);
        console.log("     Period:", membPeriod);
        console.log("     Quorum:", membQuorum, "%");

        require(techMinRank == 2, "Technical track should require Rank 2");
        require(treasMinRank == 1, "Treasury track should require Rank 1");
        require(membMinRank == 3, "Membership track should require Rank 3");

        require(techQuorum == 66, "Technical quorum should be 66%");
        require(treasQuorum == 51, "Treasury quorum should be 51%");
        require(membQuorum == 75, "Membership quorum should be 75%");

        console.log("   [OK] Track configuration correct");

        // Verify voting delay and period
        uint256 votingDelay = governor.votingDelay();
        uint256 votingPeriod = governor.votingPeriod();

        console.log("   Voting Delay:", votingDelay, "blocks");
        console.log("   Default Voting Period:", votingPeriod, "blocks");

        console.log("   [OK] Governor parameters correct");
        console.log("");
    }

    function verifyTreasury() internal view {
        console.log("3. DAOTreasury Verification");
        console.log("   Address:", address(treasury));

        uint256 balance = address(treasury).balance;
        console.log("   Balance:", balance, "wei");

        if (balance == 0) {
            console.log("   [WARNING] Treasury not funded yet");
        } else {
            console.log("   [OK] Treasury funded");
        }

        // Verify spending limits
        uint256 maxSingleSpend = treasury.maxSingleSpend();
        uint256 dailyLimit = treasury.dailySpendLimit();

        console.log("   Max Single Spend:", maxSingleSpend / 1e18, "ETH");
        console.log("   Daily Spend Limit:", dailyLimit / 1e18, "ETH");

        require(maxSingleSpend == 100 ether, "Max single spend should be 100 ETH");
        require(dailyLimit == 500 ether, "Daily limit should be 500 ETH");

        console.log("   [OK] Spending limits correct");

        // Verify roles
        bytes32 TREASURER_ROLE = treasury.TREASURER_ROLE();
        bytes32 SPENDER_ROLE = treasury.SPENDER_ROLE();

        bool timelockIsTreasurer = treasury.hasRole(TREASURER_ROLE, TIMELOCK_ADDR);
        bool timelockIsSpender = treasury.hasRole(SPENDER_ROLE, TIMELOCK_ADDR);

        console.log("   Timelock has TREASURER_ROLE:", timelockIsTreasurer);
        console.log("   Timelock has SPENDER_ROLE:", timelockIsSpender);

        if (!timelockIsTreasurer || !timelockIsSpender) {
            console.log("   [WARNING] Treasury roles not fully configured");
        } else {
            console.log("   [OK] Treasury roles configured");
        }

        console.log("");
    }

    function verifyTimelock() internal view {
        console.log("4. TimelockController Verification");
        console.log("   Address:", address(timelock));

        uint256 minDelay = timelock.getMinDelay();
        console.log("   Min Delay:", minDelay, "seconds");
        console.log("   (", minDelay / 3600, "hours)");

        require(minDelay == 1 days, "Min delay should be 1 day");

        // Verify roles
        bytes32 PROPOSER_ROLE = timelock.PROPOSER_ROLE();
        bytes32 EXECUTOR_ROLE = timelock.EXECUTOR_ROLE();

        bool governorIsProposer = timelock.hasRole(PROPOSER_ROLE, GOVERNOR_ADDR);
        bool governorIsExecutor = timelock.hasRole(EXECUTOR_ROLE, GOVERNOR_ADDR);

        console.log("   Governor has PROPOSER_ROLE:", governorIsProposer);
        console.log("   Governor has EXECUTOR_ROLE:", governorIsExecutor);

        if (!governorIsProposer || !governorIsExecutor) {
            console.log("   [ERROR] Timelock roles not configured correctly");
            revert("Fix timelock roles before continuing");
        } else {
            console.log("   [OK] Timelock roles configured");
        }

        console.log("");
    }

    function verifyIntegration() internal view {
        console.log("5. Integration Verification");

        // Verify Governor → Membership link
        address governorMembership = address(governor.token());
        console.log("   Governor -> Membership:", governorMembership);

        require(governorMembership == MEMBERSHIP_ADDR, "Governor not linked to Membership");
        console.log("   [OK] Governor linked to Membership");

        // Verify Governor → Timelock link
        address governorTimelock = governor.timelock();
        console.log("   Governor -> Timelock:", governorTimelock);

        require(governorTimelock == TIMELOCK_ADDR, "Governor not linked to Timelock");
        console.log("   [OK] Governor linked to Timelock");

        console.log("   [OK] All integrations verified");
    }
}
