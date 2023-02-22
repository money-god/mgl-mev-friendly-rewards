// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.7;

abstract contract CoinJoinLike {
    function safeEngine() virtual external view returns (address);
    function exit(address, uint) virtual external;
}

abstract contract SafeEngineLike {
    function approveSAFEModification(address) external virtual;
    function coinBalance(address) external virtual view returns (uint256);
}

/// Make rewards calls more easily noticed on chain (ERC20 events) and easier to integrate 
contract PingerAbstractor {
    CoinJoinLike immutable coinJoin;
    SafeEngineLike immutable safeEngine;

    constructor(address coinJoin_) public {
        coinJoin = CoinJoinLike(coinJoin_);
        safeEngine = SafeEngineLike(CoinJoinLike(coinJoin_).safeEngine());

        SafeEngineLike(CoinJoinLike(coinJoin_).safeEngine()).approveSAFEModification(coinJoin_);
    }

    function ping(address target_, bytes calldata data_) external {
        (bool success, ) = target_.call(data_);
        require(success);

        coinJoin.exit(msg.sender, safeEngine.coinBalance(address(this)) / 10**27);
    }
}
