// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    //events for transaction interactions
    event Deposit(address indexed sender, uint amount);
    event SubmitTransaction(address indexed owner, uint indexed txIndex, address indexed to, uint value, bytes data);
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    //efficient transaction data structure
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        mapping(address => bool) isConfirmed;
        uint numConfirmations;
    }

    Transaction[] public transactions;

    //modifiers for requires
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!transactions[_txIndex].isConfirmed[msg.sender], "tx already confirmed");
        _;
    }

    //constructor which establishes correct instantiating owner and other owners efficiently
    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length, "invalid number of required confirmations");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // Function to submit a transaction proposal by an owner.
    function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner {
        // Increment the transaction index based on the current number of transactions
        uint txIndex = transactions.length;

        // Add a new transaction to the array
        transactions.push();
        Transaction storage transaction = transactions[txIndex];

        // Set the details of the new transaction
        transaction.to = _to;
        transaction.value = _value;
        transaction.data = _data;

        // Emit an event indicating a transaction has been submitted
        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    // Function to confirm a transaction by an owner.
    function confirmTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        // Mark the transaction as confirmed by the current owner
        transaction.isConfirmed[msg.sender] = true;

        // Increment the number of confirmations for the transaction
        transaction.numConfirmations += 1;

        // Emit an event indicating the transaction has been confirmed
        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    // Function to execute a transaction after required confirmations are met.
    function executeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(transaction.numConfirmations >= numConfirmationsRequired, "cannot execute tx");

        transaction.executed = true;

        // Execute the transaction by calling the external address with the specified value and data
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed");

        // Emit an event indicating the transaction has been executed
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    // Function for an owner to revoke their confirmation of a transaction.
    function revokeConfirmation(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(transaction.isConfirmed[msg.sender], "tx not confirmed");

        // Revoke the confirmation and decrement the confirmation count
        transaction.isConfirmed[msg.sender] = false;
        transaction.numConfirmations -= 1;

        // Emit an event indicating the confirmation has been revoked
        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    //get the transaction data
    function getTransaction(uint _txIndex) public view returns (address to, uint value, bytes memory data, bool executed, uint numConfirmations) {
        require(_txIndex < transactions.length, "Transaction does not exist");
        Transaction storage transaction = transactions[_txIndex];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}