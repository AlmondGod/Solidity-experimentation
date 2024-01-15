// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../MultiSigWallet.sol";

contract MultiSigWalletTest is DSTest {
    MultiSigWallet public wallet;
    address[] public owners;

    function setUp() public {
        owners = new address[](3);
        owners[0] = address(1);
        owners[1] = address(2);
        owners[2] = address(3);
        wallet = new MultiSigWallet(owners, 2);
    }

    function testOwnerManagement() public {
        assertTrue(wallet.isOwner(owners[0]), "Owner 0 should be valid");
        assertTrue(wallet.isOwner(owners[1]), "Owner 1 should be valid");
        assertTrue(wallet.isOwner(owners[2]), "Owner 2 should be valid");
        assertEq(wallet.numConfirmationsRequired(), 2, "Confirmation number should be 2");
    }

    function testSubmitTransaction() public {
        vm.prank(owners[0]);
        wallet.submitTransaction(address(this), 0, "");
        (address to, uint value, bytes memory data, bool executed, uint numConfirmations) = wallet.getTransaction(0);
        assertEq(to, address(this), "Transaction to address mismatch");
        assertEq(value, 0, "Transaction value mismatch");
        assertEq(executed, false, "Transaction should not be executed");
        assertEq(numConfirmations, 0, "Transaction should have 0 confirmations");
    }

    function testConfirmTransaction() public {
        vm.prank(owners[0]);
        wallet.submitTransaction(address(this), 0, "");
        vm.prank(owners[1]);
        wallet.confirmTransaction(0);
        (, , , , uint numConfirmations) = wallet.getTransaction(0);
        assertEq(numConfirmations, 1, "Transaction should have 1 confirmation");
    }

    function testExecuteTransaction() public {
        vm.prank(owners[0]);
        wallet.submitTransaction(address(this), 0, "");
        vm.prank(owners[1]);
        wallet.confirmTransaction(0);
        vm.prank(owners[2]);
        wallet.confirmTransaction(0);
        vm.prank(owners[1]);
        wallet.executeTransaction(0);
        (, , , bool executed, ) = wallet.getTransaction(0);
        assertTrue(executed, "Transaction should be executed");
    }

    function testRevokeConfirmation() public {
        vm.prank(owners[0]);
        wallet.submitTransaction(address(this), 0, "");
        vm.prank(owners[1]);
        wallet.confirmTransaction(0);
        vm.prank(owners[1]);
        wallet.revokeConfirmation(0);
        (, , , , uint numConfirmations) = wallet.getTransaction(0);
        assertEq(numConfirmations, 0, "Transaction should have 0 confirmations after revocation");
    }
}
