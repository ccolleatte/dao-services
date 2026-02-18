// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import "../src/DAOMembership.sol";
import "../src/ComplianceRegistry.sol";
import "../src/Reputation.sol";
import "../src/ServiceMarketplace.sol";
import "../src/DAOTreasury.sol";
import "../src/DAOGovernor.sol";

/**
 * @title DeployScript
 * @notice Script de déploiement des smart contracts sur testnet Paseo
 * @dev Utilise forge script avec --broadcast pour déployer
 *
 * Ordre de déploiement (plan T12) :
 * 1. DAOMembership
 * 2. ComplianceRegistry
 * 3. Reputation (nouveau — remplace ReputationTracker archivé)
 * 4. ServiceMarketplace (T3 + T11 intégrés : matching on-chain + compliance KBIS)
 * 5. DAOTreasury
 * 6. TimelockController + DAOGovernor
 *
 * Usage:
 * forge script contracts/script/Deploy.s.sol --rpc-url polkadot_hub_paseo --broadcast
 *
 * Prérequis:
 * - Fichier .env avec PRIVATE_KEY
 * - Wallet avec ≥1 PAS (tokens testnet Paseo)
 */
contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("Deploying DAO Services MVP contracts");
        console.log("Deployer:", deployer);
        console.log("========================================");

        vm.startBroadcast(deployerPrivateKey);

        // 1. DAOMembership — contrat fondateur
        DAOMembership membership = new DAOMembership();
        console.log("1. DAOMembership:", address(membership));

        membership.addMember(deployer, 4, "deployer-admin");
        console.log("   Deployer added as member (Rank 4 - Partner)");

        // 2. ComplianceRegistry — KYC/KBIS hash-only (RGPD)
        ComplianceRegistry compliance = new ComplianceRegistry();
        console.log("2. ComplianceRegistry:", address(compliance));

        // 3. Reputation — nouveau (remplace ReputationTracker archivé)
        Reputation reputation = new Reputation(address(membership));
        console.log("3. Reputation:", address(reputation));

        // Déléguer MEMBER_MANAGER_ROLE à Reputation pour updateTrackRecord()
        membership.grantRole(membership.MEMBER_MANAGER_ROLE(), address(reputation));
        console.log("   Reputation granted MEMBER_MANAGER_ROLE on Membership");

        // 4. ServiceMarketplace — T3 + T11 : matching on-chain + vérification KBIS
        ServiceMarketplace marketplace = new ServiceMarketplace(
            address(membership),
            address(compliance),
            deployer
        );
        console.log("4. ServiceMarketplace:", address(marketplace));

        // Accorder VERIFIER_ROLE au deployer pour émettre des attestations KBIS
        compliance.grantRole(compliance.VERIFIER_ROLE(), deployer);
        console.log("   Deployer granted VERIFIER_ROLE on ComplianceRegistry");

        // 5. DAOTreasury
        DAOTreasury treasury = new DAOTreasury(membership, deployer);
        console.log("5. DAOTreasury:", address(treasury));

        // 6. TimelockController + DAOGovernor
        address[] memory proposers = new address[](1);
        proposers[0] = deployer;
        address[] memory executors = new address[](1);
        executors[0] = address(0); // Tout le monde peut exécuter

        TimelockController timelock = new TimelockController(
            2 days,       // minDelay
            proposers,
            executors,
            deployer      // admin initial
        );
        console.log("6. TimelockController:", address(timelock));

        DAOGovernor governor = new DAOGovernor(membership, timelock);
        console.log("   DAOGovernor:", address(governor));

        vm.stopBroadcast();

        console.log("");
        console.log("========================================");
        console.log("Deployment complete -- save these addresses:");
        console.log("  DAOMembership:     ", address(membership));
        console.log("  ComplianceRegistry:", address(compliance));
        console.log("  Reputation:        ", address(reputation));
        console.log("  DAOTreasury:       ", address(treasury));
        console.log("  TimelockController:", address(timelock));
        console.log("  DAOGovernor:       ", address(governor));
        console.log("  ServiceMarketplace:", address(marketplace));
        console.log("========================================");
    }
}
