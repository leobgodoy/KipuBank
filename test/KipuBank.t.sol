// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {KipuBank} from "../src/KipuBank.sol";

contract KipuBankTest is Test {
    //Instances
    KipuBank bank;

    //Variables ~ Users
    address user = makeAddr("user");
    address student1 = makeAddr("student1");
    address student2 = makeAddr("student2");

    //Variables ~ Utils
    uint256 constant BANK_CAP = 10*10**18;
    uint256 constant INITIAL_BALANCE = 100*10**18;


    //Setup Testing
    function setUp() public {
        bank = new KipuBank(BANK_CAP);

        vm.deal(user, INITIAL_BALANCE);
        vm.deal(student1, INITIAL_BALANCE);
        vm.deal(student2, INITIAL_BALANCE);
    }

    modifier processDeposit() {
        uint256 amount = 1*10**18;
        vm.prank(user);
        bank.deposit{value: amount}();
        _;
    }

    /// Testing functions ///
    error KipuBank_BankCapReached(uint256);
    function test_depositFailsBecauseOfCap() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(KipuBank_BankCapReached.selector, BANK_CAP));
        bank.deposit{value: INITIAL_BALANCE}();
    }

    event KipuBank_SuccessfulDeposited(address, uint256);
    function test_depositSucceed() public {
        uint256 amount = 1*10**18;
        uint256 userBalance = student1.balance;

        vm.prank(student1);
        vm.expectEmit();
        emit KipuBank_SuccessfulDeposited(student1, amount);
        bank.deposit{value: amount}();

        uint256 contractBalance = bank.getContractBalance();
        assertEq(student1.balance, userBalance - amount);
        assertEq(contractBalance, amount);
    }

    error KipuBank_AmountOverflowBalance(uint256, uint256);
    function test_withdrawFailedBecauseOfUserBalance() public processDeposit {
        uint256 amountToBeReduced = 1*10**15;
        uint256 overflowAmount = 1*10**18;

        vm.prank(student1);
        vm.expectRevert(abi.encodeWithSelector(KipuBank_AmountOverflowBalance.selector, amountToBeReduced, 0));
        bank.withdraw(amountToBeReduced);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(KipuBank_AmountOverflowBalance.selector, overflowAmount, overflowAmount));
        bank.withdraw(overflowAmount);

        assertEq(bank.getContractBalance(), overflowAmount);
    }

    event KipuBank_SuccessfullyWithdrawn(address, uint256);
    function test_WithdrawSucceed() public processDeposit {
        uint256 amountToBeReduced = 1*10**15;
        uint256 amountPostWithdrawal = 1*10**18 - amountToBeReduced;

        vm.prank(user);
        vm.expectEmit();
        emit KipuBank_SuccessfullyWithdrawn(user, amountToBeReduced);
        bank.withdraw(amountToBeReduced);

        assertEq(bank.getContractBalance(), amountPostWithdrawal);
    }
}