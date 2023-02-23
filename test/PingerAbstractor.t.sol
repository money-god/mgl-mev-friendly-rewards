// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.7;

import "forge-std/Test.sol";
import "../src/PingerAbstractor.sol";

import "ds-token/token.sol";
import "geb/single/SAFEEngine.sol";
import { StabilityFeeTreasury } from "geb/single/StabilityFeeTreasury.sol";
import { CoinJoin } from "geb/shared/BasicTokenAdapters.sol";
import "geb-treasury-reimbursement/reimbursement/single/IncreasingTreasuryReimbursement.sol";

contract Pinger is IncreasingTreasuryReimbursement {
    constructor(address treasury_, uint256 baseUpdateCallerReward_, uint maxUpdateCallerReward_, uint perSecondCallerRewardIncrease_) public
    IncreasingTreasuryReimbursement(treasury_, baseUpdateCallerReward_, maxUpdateCallerReward_, perSecondCallerRewardIncrease_)
    {}

    function ping(address receiver, uint value) public {
        rewardCaller(receiver, value);
    }

    function modifyParameters(bytes32 param, uint value) public {
        if (param == "maxRewardIncreaseDelay")
            maxRewardIncreaseDelay = value;
        else revert("");
    }
}

contract PingerAbstractorTest is Test {
    PingerAbstractor abstractor;

    Pinger pinger;
    SAFEEngine safeEngine;
    StabilityFeeTreasury treasury;
    CoinJoin coinJoin;
    DSToken coin;

    uint256 startTime                     = 1577836800;
    uint256 baseCallerReward              = 15 ether;
    uint256 maxCallerReward               = 45 ether;
    uint256 perSecondCallerRewardIncrease = 1000192559420674483977255848; // 100% over one hour

    uint256 RAY                           = 10 ** 27;    
    uint256 RAD                           = 10 ** 45;    

    function setUp() public {
        // Create token
        coin = new DSToken("RAI", "RAI");

        // Create treasury
        safeEngine = new SAFEEngine();
        coinJoin = new CoinJoin(address(safeEngine), address(coin));
        treasury = new StabilityFeeTreasury(address(safeEngine), address(0x1), address(coinJoin));
        coin.setOwner(address(coinJoin));

        safeEngine.createUnbackedDebt(address(0), address(treasury), 1000 * RAD);

        pinger = new Pinger(address(treasury), baseCallerReward, maxCallerReward, perSecondCallerRewardIncrease);

        // Setup treasury allowance
        treasury.setTotalAllowance(address(pinger), uint(-1));
        treasury.setPerBlockAllowance(address(pinger), uint(-1));

        // setUp abstractor        
        abstractor = new PingerAbstractor(
            address(coinJoin)
        );
    }

    function testPing() public {
        abstractor.ping(address(pinger), abi.encodeWithSignature("ping(address,uint256)", address(0), 1 ether));
        assertEq(coin.balanceOf(address(this)), 1 ether);

        abstractor.ping(address(pinger), abi.encodeWithSignature("ping(address,uint256)", address(0), 1 ether));
        assertEq(coin.balanceOf(address(this)), 2 ether);        
    }
}
