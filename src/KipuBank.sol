/**
 *Submitted for verification at Etherscan.io on 2025-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

////////////
///Errors///
////////////

error KipuBank_DepositLowerEqualThanZero();
error KipuBank_WithdrawLowerEqualThanZero();
error KipuBank_ExceedBankCap();
error KipuBank_ExceedUserCap();
error KipuBank_InsufficientBalance();
error KipuBank_TransferError();

contract KipuBank {

    /////////////////////
    ///State variables///
    /////////////////////

    /*
    - O contrato deve ter um construtor que receba como parâmetro o limite máximo de ETH que o banco pode armazenar (bankCap).
    - Este limite deve ser armazenado em uma variável imutável e usado para validar depósitos futuros.

    ...

    - Deve haver um limite fixo por saque, definido como uma constante no contrato.
    */

    uint256 public immutable i_bankCap = 0.01 ether;
    uint256 public constant WITHDRAW_LIMIT = 0.003 ether; // Limite fixo por saque
    mapping(address => uint256) private s_balance;

    ////////////
    ///Events///
    ////////////

    event KipuBank_DepositSuccessful(address indexed user, uint256 amount);
    event KipuBank_WithdrawSuccessful(address indexed user, uint256 amount);

    constructor(uint256 _i_bankCap) {
        i_bankCap = _i_bankCap;
    }

    //////////////
    ///external///
    //////////////

    /*
    
    A função _validateWithdrawal contém os critério de validação.
    Um evento é emitido ao final de cada depósito bem-sucedido.
    
    */
    
    function deposit() external payable validDeposit(msg.value) {
        emit KipuBank_DepositSuccessful(msg.sender, msg.value);
    }

    /*
    
    - O contrato deve permitir que qualquer pessoa consulte o saldo de ETH armazenado no contrato.
    - Deve ser implementada uma função de visualização para retornar este saldo.

    */

    function withdraw(uint256 amount) external validWithdrawal(msg.sender, amount) {
        s_balance[msg.sender] -= amount;
        _transferETH(msg.sender, amount);
        emit KipuBank_WithdrawSuccessful(msg.sender, amount);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    //////////////
    ///internal///
    //////////////

    /*
        A função _validateWithdrawal contém os critério de validação.
        Ao final de cada saque bem-sucedido, um evento é emitido.
    */

    function _transferETH(address recipient, uint256 amount) internal {
        (bool success, ) = payable(recipient).call{value: amount}("");
        if (!success) revert KipuBank_TransferError();
    }

    ///////////////
    ///modifiers///
    ///////////////

    /*

    - Use modificadores para validar condições que se repetem nas funções.
    - Centralize a lógica de transferências de ETH em uma função interna para evitar duplicação de código.    

    */

    modifier validDeposit(uint256 amount) {
        if (amount <= 0) revert KipuBank_DepositLowerEqualThanZero();
        if (address(this).balance + amount > i_bankCap) revert KipuBank_ExceedBankCap();
        _;
    }

    /*
    
    - O contrato deve permitir que os usuários realizem saques de valores previamente depositados.
    - Deve haver um limite fixo por saque, definido como uma constante no contrato.
    - O valor solicitado para saque não pode exceder o saldo do usuário nem o limite por saque. Caso isso ocorra, a transação deve reverter com uma mensagem de erro apropriada.

    */

    modifier validWithdrawal(address user, uint256 amount) {
        if (amount <= 0) revert KipuBank_WithdrawLowerEqualThanZero();
        if (amount > s_balance[user]) revert KipuBank_InsufficientBalance();
        if (amount > WITHDRAW_LIMIT) revert KipuBank_ExceedUserCap();
        _;
    }

}