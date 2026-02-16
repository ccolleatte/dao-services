// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MilestoneEscrow.sol";
import "../src/ServiceMarketplace.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MilestoneEscrowTest
 * @notice TDD RED phase - Tests written BEFORE implementation
 * @dev Phase 2 Extension: Escrow + Milestones management
 */
contract MilestoneEscrowTest is Test {
    MilestoneEscrow public escrow;
    MockServiceMarketplace public marketplace;
    MockDAOSToken public daosToken;

    address client = makeAddr("client");
    address consultant = makeAddr("consultant");
    address admin = makeAddr("admin");

    uint256 missionId = 1;
    uint256 budget = 1000 ether;

    // Events (for testing)
    event MilestonesSetup(uint256 indexed missionId, uint256 milestoneCount, uint256 totalAmount);
    event DeliverableSubmitted(uint256 indexed missionId, uint256 milestoneIndex, bytes32 deliverableHash);
    event DeliverableAccepted(uint256 indexed missionId, uint256 milestoneIndex, uint256 amount);
    event DeliverableRejected(uint256 indexed missionId, uint256 milestoneIndex, string reason);
    event FundsReleased(uint256 indexed missionId, address indexed consultant, uint256 amount);
    event MissionCancelled(uint256 indexed missionId, uint256 refundAmount);

    function setUp() public {
        // Deploy mock contracts
        daosToken = new MockDAOSToken();
        marketplace = new MockServiceMarketplace();

        // Deploy MilestoneEscrow
        escrow = new MilestoneEscrow(
            address(marketplace),
            address(daosToken)
        );

        // Fund client
        daosToken.mint(client, 10000 ether);

        // Client approves escrow
        vm.prank(client);
        daosToken.approve(address(escrow), type(uint256).max);

        // Setup mock mission
        marketplace.setMissionClient(missionId, client);
        marketplace.setMissionBudget(missionId, budget);
    }

    /*//////////////////////////////////////////////////////////////
                        SETUP MILESTONES TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Client can setup milestones successfully
    function test_SetupMilestones_Success() public {
        MilestoneEscrow.MilestoneInput[] memory milestones = new MilestoneEscrow.MilestoneInput[](3);
        milestones[0] = MilestoneEscrow.MilestoneInput({
            description: "Phase 1: Design",
            acceptanceCriteriaHash: keccak256("IPFS_CRITERIA_1"),
            amount: 300 ether
        });
        milestones[1] = MilestoneEscrow.MilestoneInput({
            description: "Phase 2: Development",
            acceptanceCriteriaHash: keccak256("IPFS_CRITERIA_2"),
            amount: 400 ether
        });
        milestones[2] = MilestoneEscrow.MilestoneInput({
            description: "Phase 3: Testing",
            acceptanceCriteriaHash: keccak256("IPFS_CRITERIA_3"),
            amount: 300 ether
        });

        // Expect event emission
        vm.expectEmit(true, true, true, true);
        emit MilestonesSetup(missionId, 3, 1000 ether);

        // Client setup milestones
        vm.prank(client);
        escrow.setupMilestones(missionId, milestones);

        // Verify milestones stored
        MilestoneEscrow.Milestone memory m1 = escrow.getMilestone(missionId, 0);
        assertEq(m1.description, "Phase 1: Design");
        assertEq(m1.amount, 300 ether);
        assertEq(uint(m1.status), uint(MilestoneEscrow.MilestoneStatus.Pending));

        // Verify escrow balance
        MilestoneEscrow.EscrowBalance memory balance = escrow.getEscrowBalance(missionId);
        assertEq(balance.totalLocked, 1000 ether);
        assertEq(balance.released, 0);
        assertEq(balance.refunded, 0);
        assertFalse(balance.finalized);
    }

    /// @notice Test: Non-client cannot setup milestones
    function test_SetupMilestones_RevertIfNotClient() public {
        MilestoneEscrow.MilestoneInput[] memory milestones = new MilestoneEscrow.MilestoneInput[](1);
        milestones[0] = MilestoneEscrow.MilestoneInput({
            description: "Phase 1",
            acceptanceCriteriaHash: keccak256("CRITERIA"),
            amount: 1000 ether
        });

        vm.expectRevert(MilestoneEscrow.NotMissionClient.selector);
        vm.prank(consultant);
        escrow.setupMilestones(missionId, milestones);
    }

    /// @notice Test: Cannot setup milestones if total exceeds budget
    function test_SetupMilestones_RevertIfTotalExceedsBudget() public {
        MilestoneEscrow.MilestoneInput[] memory milestones = new MilestoneEscrow.MilestoneInput[](2);
        milestones[0] = MilestoneEscrow.MilestoneInput({
            description: "Phase 1",
            acceptanceCriteriaHash: keccak256("CRITERIA_1"),
            amount: 600 ether
        });
        milestones[1] = MilestoneEscrow.MilestoneInput({
            description: "Phase 2",
            acceptanceCriteriaHash: keccak256("CRITERIA_2"),
            amount: 500 ether // Total 1100 > 1000 budget
        });

        vm.expectRevert(MilestoneEscrow.MilestonesTotalExceedsBudget.selector);
        vm.prank(client);
        escrow.setupMilestones(missionId, milestones);
    }

    /*//////////////////////////////////////////////////////////////
                        SUBMIT DELIVERABLE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Consultant can submit deliverable
    function test_SubmitDeliverable_Success() public {
        // Setup milestones first
        _setupDefaultMilestones();

        // Select consultant
        marketplace.setMissionConsultant(missionId, consultant);

        bytes32 deliverableHash = keccak256("IPFS_DELIVERABLE_1");

        // Expect event
        vm.expectEmit(true, true, true, true);
        emit DeliverableSubmitted(missionId, 0, deliverableHash);

        // Consultant submit deliverable
        vm.prank(consultant);
        escrow.submitDeliverable(missionId, 0, deliverableHash);

        // Verify milestone updated
        MilestoneEscrow.Milestone memory m = escrow.getMilestone(missionId, 0);
        assertEq(uint(m.status), uint(MilestoneEscrow.MilestoneStatus.Submitted));
        assertEq(m.deliverableHash, deliverableHash);
        assertEq(m.submittedAt, block.timestamp);
    }

    /// @notice Test: Non-consultant cannot submit deliverable
    function test_SubmitDeliverable_RevertIfNotConsultant() public {
        _setupDefaultMilestones();
        marketplace.setMissionConsultant(missionId, consultant);

        vm.expectRevert(MilestoneEscrow.NotSelectedConsultant.selector);
        vm.prank(client);
        escrow.submitDeliverable(missionId, 0, keccak256("DELIVERABLE"));
    }

    /*//////////////////////////////////////////////////////////////
                        ACCEPT DELIVERABLE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Client can accept deliverable and funds released
    function test_AcceptDeliverable_Success() public {
        _setupDefaultMilestones();
        marketplace.setMissionConsultant(missionId, consultant);

        // Consultant submit deliverable
        vm.prank(consultant);
        escrow.submitDeliverable(missionId, 0, keccak256("DELIVERABLE_1"));

        uint256 consultantBalanceBefore = daosToken.balanceOf(consultant);

        // Expect events
        vm.expectEmit(true, true, true, true);
        emit DeliverableAccepted(missionId, 0, 300 ether);

        vm.expectEmit(true, true, true, true);
        emit FundsReleased(missionId, consultant, 300 ether);

        // Client accept deliverable
        vm.prank(client);
        escrow.acceptDeliverable(missionId, 0);

        // Verify milestone status
        MilestoneEscrow.Milestone memory m = escrow.getMilestone(missionId, 0);
        assertEq(uint(m.status), uint(MilestoneEscrow.MilestoneStatus.Accepted));
        assertEq(m.validator, client);
        assertEq(m.validatedAt, block.timestamp);

        // Verify funds released
        assertEq(daosToken.balanceOf(consultant), consultantBalanceBefore + 300 ether);

        // Verify escrow balance updated
        MilestoneEscrow.EscrowBalance memory balance = escrow.getEscrowBalance(missionId);
        assertEq(balance.released, 300 ether);
    }

    /// @notice Test: Cannot accept deliverable if not client
    function test_AcceptDeliverable_RevertIfNotClient() public {
        _setupDefaultMilestones();
        marketplace.setMissionConsultant(missionId, consultant);

        vm.prank(consultant);
        escrow.submitDeliverable(missionId, 0, keccak256("DELIVERABLE"));

        vm.expectRevert(MilestoneEscrow.NotMissionClient.selector);
        vm.prank(consultant);
        escrow.acceptDeliverable(missionId, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        REJECT DELIVERABLE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Client can reject deliverable, funds NOT released
    function test_RejectDeliverable_Success() public {
        _setupDefaultMilestones();
        marketplace.setMissionConsultant(missionId, consultant);

        vm.prank(consultant);
        escrow.submitDeliverable(missionId, 0, keccak256("DELIVERABLE"));

        uint256 consultantBalanceBefore = daosToken.balanceOf(consultant);

        string memory reason = "Does not meet acceptance criteria";

        // Expect event
        vm.expectEmit(true, true, true, true);
        emit DeliverableRejected(missionId, 0, reason);

        // Client reject
        vm.prank(client);
        escrow.rejectDeliverable(missionId, 0, reason);

        // Verify status
        MilestoneEscrow.Milestone memory m = escrow.getMilestone(missionId, 0);
        assertEq(uint(m.status), uint(MilestoneEscrow.MilestoneStatus.Rejected));

        // Verify NO funds released
        assertEq(daosToken.balanceOf(consultant), consultantBalanceBefore);

        // Verify escrow balance unchanged
        MilestoneEscrow.EscrowBalance memory balance = escrow.getEscrowBalance(missionId);
        assertEq(balance.released, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        CANCEL MISSION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Client can cancel mission and get refund if no consultant selected
    function test_CancelMission_RefundClient() public {
        _setupDefaultMilestones();

        uint256 clientBalanceBefore = daosToken.balanceOf(client);

        // Expect event
        vm.expectEmit(true, true, true, true);
        emit MissionCancelled(missionId, 1000 ether);

        // Client cancel mission
        vm.prank(client);
        escrow.cancelMissionAndRefund(missionId);

        // Verify escrow balance
        MilestoneEscrow.EscrowBalance memory balance = escrow.getEscrowBalance(missionId);
        assertEq(balance.refunded, 1000 ether);
        assertTrue(balance.finalized);

        // Verify client refunded
        assertEq(daosToken.balanceOf(client), clientBalanceBefore + 1000 ether);
    }

    /// @notice Test: Cannot cancel if consultant already selected
    function test_CancelMission_RevertIfConsultantSelected() public {
        _setupDefaultMilestones();
        marketplace.setMissionConsultant(missionId, consultant);

        vm.expectRevert(MilestoneEscrow.CannotCancelAfterConsultantSelected.selector);
        vm.prank(client);
        escrow.cancelMissionAndRefund(missionId);
    }

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _setupDefaultMilestones() internal {
        MilestoneEscrow.MilestoneInput[] memory milestones = new MilestoneEscrow.MilestoneInput[](3);
        milestones[0] = MilestoneEscrow.MilestoneInput({
            description: "Phase 1: Design",
            acceptanceCriteriaHash: keccak256("CRITERIA_1"),
            amount: 300 ether
        });
        milestones[1] = MilestoneEscrow.MilestoneInput({
            description: "Phase 2: Development",
            acceptanceCriteriaHash: keccak256("CRITERIA_2"),
            amount: 400 ether
        });
        milestones[2] = MilestoneEscrow.MilestoneInput({
            description: "Phase 3: Testing",
            acceptanceCriteriaHash: keccak256("CRITERIA_3"),
            amount: 300 ether
        });

        vm.prank(client);
        escrow.setupMilestones(missionId, milestones);
    }
}

/*//////////////////////////////////////////////////////////////
                        MOCK CONTRACTS
//////////////////////////////////////////////////////////////*/

contract MockDAOSToken is ERC20 {
    constructor() ERC20("DAOS Token", "DAOS") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract MockServiceMarketplace {
    mapping(uint256 => address) public missionClients;
    mapping(uint256 => address) public missionConsultants;
    mapping(uint256 => uint256) public missionBudgets;

    function setMissionClient(uint256 missionId, address client) external {
        missionClients[missionId] = client;
    }

    function setMissionConsultant(uint256 missionId, address consultant) external {
        missionConsultants[missionId] = consultant;
    }

    function setMissionBudget(uint256 missionId, uint256 budget) external {
        missionBudgets[missionId] = budget;
    }

    function getMissionClient(uint256 missionId) external view returns (address) {
        return missionClients[missionId];
    }

    function getMissionConsultant(uint256 missionId) external view returns (address) {
        return missionConsultants[missionId];
    }

    function getMissionBudget(uint256 missionId) external view returns (uint256) {
        return missionBudgets[missionId];
    }
}
