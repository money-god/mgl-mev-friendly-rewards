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
    address immutable target;
    bytes data;

    constructor(address coinJoin_, address target_, bytes memory data_) public {
        coinJoin = CoinJoinLike(coinJoin_);
        safeEngine = SafeEngineLike(CoinJoinLike(coinJoin_).safeEngine());
        target = target_;
        data = data_;

        SafeEngineLike(CoinJoinLike(coinJoin_).safeEngine()).approveSAFEModification(coinJoin_);
    }

    function ping() external {
        (bool success, ) = target.call(data);
        require(success);

        coinJoin.exit(msg.sender, safeEngine.coinBalance(address(this)) / 10**27);
    }
}
