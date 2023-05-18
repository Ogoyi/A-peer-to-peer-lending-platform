 // SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IERC20Token {
    function transfer(address, uint256) external returns (bool);

    function approve(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PeerToPeerLending {
    using SafeMath for uint256;

    address private cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    struct Loan {
        address payable borrower;
        uint256 amount;
        uint256 interestRate;
        uint256 duration;
        uint256 endTime;
        bool isActive;
        bool isCompleted;
    }

    uint256 private loanIdCounter = 0;
    mapping(uint256 => Loan) private loans;

    modifier onlyActiveLoan(uint256 loanId) {
        require(loans[loanId].isActive, "Loan is not active");
        _;
    }

    function createLoan(uint256 amount, uint256 interestRate, uint256 duration) external {
        require(amount > 0, "Loan amount must be greater than zero");
        require(interestRate > 0, "Interest rate must be greater than zero");
        require(duration > 0, "Loan duration must be greater than zero");

        Loan storage newLoan = loans[loanIdCounter];
        newLoan.borrower = payable(msg.sender);
        newLoan.amount = amount;
        newLoan.interestRate = interestRate;
        newLoan.duration = duration;
        newLoan.endTime = block.timestamp.add(duration);
        newLoan.isActive = true;
        newLoan.isCompleted = false;

        loanIdCounter++;
    }

    function getLoan(uint256 loanId) public view returns (address payable, uint256, uint256, uint256, uint256, bool, bool) {
        Loan storage loan = loans[loanId];
        return (
            loan.borrower,
            loan.amount,
            loan.interestRate,
            loan.duration,
            loan.endTime,
            loan.isActive,
            loan.isCompleted
        );
    }

    function fundLoan(uint256 loanId) external payable onlyActiveLoan(loanId) {
        Loan storage loan = loans[loanId];
        require(msg.value == loan.amount, "Incorrect loan amount");

        IERC20Token(cUsdTokenAddress).transferFrom(msg.sender, loan.borrower, loan.amount);

        loan.isActive = false;
    }
 function interestAmount(Loan storage loan) internal view returns (uint256) {
    uint256 calculatedInterestAmount = loan.amount.mul(loan.interestRate).div(100);
    uint256 remainingDays = loan.endTime.sub(block.timestamp).div(1 days);
    return calculatedInterestAmount.mul(remainingDays).div(365);
}


     
}