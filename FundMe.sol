// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// 1. 创建一个收款函数
// 2. 记录投资人并且查看
// 3. 在锁定期内,达到目标值,生产商可以提款
// 4. 在锁定期内,没有达到目标值,投资人在锁定期以后退款

contract FundMe {
    mapping(address => uint256) public funderToAmount;

    AggregatorV3Interface internal dataFeed;

    uint256 constant MINIMUM_VALUE = 100 * 10**18; // USD

    address public owner;

    uint256 constant TARGET = 1000 * 10**18;

    uint256 deploymentTimestamp;
    uint256 lockTime;

    constructor(uint256 _lockTime) {
        // sepolia test
        dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        owner = msg.sender;
        deploymentTimestamp = block.timestamp;
        lockTime = _lockTime;
    }

    /**
     * 筹款
     */
    function fund() external payable {
        require(convertEthToUsd(msg.value) >= MINIMUM_VALUE, "Send more ETH");
        require(
            block.timestamp < deploymentTimestamp + lockTime,
            " window is closed"
        );
        funderToAmount[msg.sender] = msg.value;
    }

    /**
     * 获取最新的汇率
     */
    function getChainlinkDataFeedLatestAnswer() public view returns (int256) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    /**
     * Eth=> Usd
     */
    function convertEthToUsd(uint256 ethAmount)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = uint256(getChainlinkDataFeedLatestAnswer());
        return (ethAmount * ethPrice) / (10**8);
    }

    /**
     * 获取当前筹款金额
     */
    function getFund() external windowClose onlyOwner(){
        require(
            convertEthToUsd(address(this).balance) >= TARGET,
            "Not enough funds"
        );

        // transfer : transfer ETH and revert it tx failed
        // payable(msg.sender).transfer(address(this).balance);
        // send : transfer ETH and return false if failed
        // bool success = payable(msg.sender).send(address(this).balance)
        // require(success,"send tx failed");
        // call : transfer ETH with data return value of function and bool
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "send tx failed");
    }

    /**
     * 更改合约所有权
     */
    function transferOwnership(address newOwner) public onlyOwner{
        owner = newOwner;
    }

    /**
     * 提取筹款
     */
    function refund() external windowClose(){
        require(
            convertEthToUsd(address(this).balance) < TARGET,
            "Target is reached"
        );
        require(funderToAmount[msg.sender] != 0, "there is no fund for you");


        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "transfer tx failed");
        funderToAmount[msg.sender] = 0;
    }

    /**
    * 锁定期结束后
    */
    modifier windowClose() {
        require(
            block.timestamp >= deploymentTimestamp + lockTime,
            "window is not closed"
        );
        _;
    }
    /**
    * 只有合约所有人可以操作
    */
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "this function can only be called by owner"
        );
        _;
    }
}
