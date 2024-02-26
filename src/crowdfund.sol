// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract crowdfund{
    address private  owner;
    IERC20 public token;
    uint public count;

    constructor(address _token){
        owner=msg.sender;
        token = IERC20(_token);
    }

    event pledgedTokens(
        uint _id,
        uint _amount,
        address indexed user
    );

    event unpldgedtokens(
        uint _id,
        uint _amount,
        address indexed user
    );

    event launched(
        address indexed creator,
        uint id,
        uint32 _startAt,
        uint32 _endAt
    );

    event Cancled(
        address indexed  creator,
        uint id
    );

    event claimed(
        uint id,
        address creator,
        uint claimedTokens,
        uint256 calimedAt
    );

    event refunded(
        uint id,
        address indexed user,
        uint refundedTokens,
        uint256 refundedAt
    );

    struct Campaign{
        address _creator;
        uint _goal;
        uint _pledged;
        uint256 _startAt;
        uint256 _endAt;
        bool claimed;
    }


    mapping (uint => Campaign) public Campaigns;
    mapping (uint => mapping(address => uint)) public pledged;

    function launch(
        uint _goal,
        uint32 _startAt,
        uint32 _endAt
    ) external {
        // require(_startAt >= block.timestamp,"Starting time is less than current time");
        // require(_endAt <= block.timestamp + 90 days && _endAt > _startAt,"End time is more than 90 days or less than starting time");
        count += 1;
        uint256 endtime= block.timestamp + 2 minutes;
        Campaigns[count] = Campaign(
            msg.sender,_goal,0,block.timestamp,endtime,false
        );
        emit launched(msg.sender, count, _startAt, _endAt);
    }

    function cancel(uint _id) external  {
    Campaign storage camp = Campaigns[_id];
        require(camp._startAt > block.timestamp,"Allready started");
        require(camp._creator==msg.sender,"Invalid creator");
        delete Campaigns[_id];
        emit Cancled (msg.sender, _id);
    }


    function pledge(uint _id, uint _amount) external {
         Campaign storage camp = Campaigns[_id];
         require(camp._startAt <block.timestamp,"Not yet started");
         require(camp._endAt > block.timestamp,"Ended");
         pledged[_id][msg.sender] += _amount;
         camp._pledged += _amount;
         token.transferFrom(msg.sender,address(this), _amount);
         emit pledgedTokens(_id, _amount, msg.sender);
    }

    function unfledge(uint _id, uint _amount) external{
        Campaign storage camp = Campaigns[_id];
         require(camp._endAt > block.timestamp,"Ended");
         require(pledged[_id][msg.sender]>= _amount,"Insufficent amount to unfledge");
         pledged[_id][msg.sender] -= _amount;
         camp._pledged -= _amount;
        token.transfer(msg.sender, _amount);
        emit unpldgedtokens(_id, _amount, msg.sender);
    }

    function claim(uint _id) external{
        Campaign storage camp = Campaigns[_id];
        require(camp._creator==msg.sender,"Invalid creator");
        require(camp._endAt < block.timestamp,"Not Ended");
        require(!camp.claimed,"Allready claimed");
        require(camp._pledged >= camp._goal,"fledge < goal");
        camp.claimed=true;
        token.transfer(msg.sender,camp._pledged);
        emit claimed(_id, msg.sender, camp._pledged,block.timestamp);
    }

    function refund(uint _id) external {
        Campaign storage camp = Campaigns[_id];
        require(camp._endAt < block.timestamp,"Not Ended");
        require(!camp.claimed,"Allready claimed");
        require(camp._pledged < camp._goal,"fledge < goal"); 
    
        uint bal = pledged[_id][msg.sender];
        pledged[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);
        emit  refunded(_id,msg.sender,camp._pledged,block.timestamp);
    }











}