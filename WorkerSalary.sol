// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";


contract WorkerSalary{
    struct Employee{
        address employeeAdd;
        uint256 salary;//salary is stored as usd or inr 
    }
    AggregatorV3Interface internal dataFeed;

    uint256 public id;
    address owner;
    uint256 public finalTime;
    uint256 MONTHLY_DAYS = 30.42 days;// 365/12 days taken average days in a month
    uint256 constant public COMPENSATION = 0.00001 ether;


    /**
     * Network: Sepolia
     * Aggregator: ETH/USD
     * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
     */
    constructor(){
        owner=msg.sender;
        finalTime=block.timestamp + MONTHLY_DAYS;
        dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
    }

    function getEtherPerUSD() public view returns (int) {
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }
    mapping(uint256=>Employee) public company_wallet;
    mapping(address=>uint256) salaryInfo;

    modifier onlyOwner{
        require(msg.sender==owner ,"you are not owner");
        _;
    }

    function depositMoney()payable public onlyOwner{
        require(msg.value > 0,"value is less than or equal to zero");
    }

    function checkBalance() public view onlyOwner returns(uint256){
        return address(this).balance;
    }
    /** author : anurag agarwal
    * params: employee Address , employee salary
    * description: register a employee in company database only owner can do that 
    */
    function registerEmployee(address employeeAddress,uint256 empSalary)public onlyOwner{
        require(empSalary>0,"salary should be greater than 0");
        require(salaryInfo[employeeAddress] == 0,"you can't register employee twice");
        company_wallet[id]=Employee(employeeAddress,empSalary);
        salaryInfo[employeeAddress]=empSalary;
        ++id;
    }

    function SendSalary() public payable{
        require(block.timestamp >finalTime,"you can't get salary before payday");
        require(block.timestamp - finalTime < 3 days,"company not send money use late payement method to get additional bonus");
        uint256 limit = id;
        for (uint256 i=0;i<limit ; i++){
            address add =(company_wallet[i].employeeAdd);
            uint256 salaryInEther = _getSalaryInEth(salaryInfo[add]);
           (bool sent, /*bytes memory data*/) = payable(add).call{value: salaryInEther}("");
            require(sent, "Failed to send Ether");
        }
        finalTime = block.timestamp + MONTHLY_DAYS;
    }
    
    function LatePayement() public payable{
        require(block.timestamp - finalTime > 1 days ,"NO late payment option");
        uint256 LateDays =(block.timestamp - finalTime)/1 days;
        uint256 compenstaionTotal = LateDays * COMPENSATION;
        uint256 limit = id;
        for(uint256 i = 0; i<limit;i++){
            address add=(company_wallet[i].employeeAdd);
            uint256 salary = _getSalaryInEth(salaryInfo[add]) + compenstaionTotal;
            (bool sent,)=payable(add).call{value:salary}("");
            require(sent,"Failed to sent transaction");
        }
        finalTime = block.timestamp + 100 seconds;
    }

    function ChangeSalaryOfEmployee(address _empadd,uint _newSalary)public onlyOwner{
        require(salaryInfo[_empadd]>0,"Register for a new employee");
        require(_newSalary>0,"please check newSalary balance can't be take as zero");
        salaryInfo[_empadd]=_newSalary;

    }

    function _getSalaryInEth(uint256 _salary) public view returns(uint256){
        uint256 priceOfEther = uint256(getEtherPerUSD());//price of one ether
        uint256 etherAmount = (_salary * 10**26 / priceOfEther);
        return etherAmount;
    }
}