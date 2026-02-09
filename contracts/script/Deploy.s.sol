// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/DAOMembership.sol";

/**
 * @title DeployScript
 * @notice Script de déploiement des smart contracts sur testnet Paseo
 * @dev Utilise forge script avec --broadcast pour déployer
 *
 * Usage:
 * forge script contracts/script/Deploy.s.sol --rpc-url polkadot_hub_paseo --broadcast
 *
 * Prérequis:
 * - Fichier .env avec PRIVATE_KEY
 * - Wallet avec ≥1 PAS (tokens testnet)
 */
contract DeployScript is Script {
    function run() external {
        // Charger clé privée depuis .env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Obtenir adresse du déployeur
        address deployer = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("Deploying contracts with:");
        console.log("Deployer address:", deployer);
        console.log("========================================");

        // Démarrer broadcast (envoie transactions on-chain)
        vm.startBroadcast(deployerPrivateKey);

        // Déployer DAOMembership
        DAOMembership membership = new DAOMembership();
        console.log("");
        console.log("DAOMembership deployed at:", address(membership));

        // Ajouter le déployeur comme premier membre (Rang 4 - Partner)
        membership.addMember(deployer, 4, "deployer-admin");
        console.log("Deployer added as member (Rank 4)");

        vm.stopBroadcast();

        console.log("");
        console.log("========================================");
        console.log("Deployment complete!");
        console.log("Save these addresses:");
        console.log("- DAOMembership:", address(membership));
        console.log("========================================");
    }
}
