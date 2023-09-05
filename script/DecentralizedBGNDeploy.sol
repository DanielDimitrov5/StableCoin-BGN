// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {DecentralizedBGN} from "../src/DecentralizedBGN.sol";

contract SDecentralizedBGNDeploy is Script {
    
    function run() external returns (DecentralizedBGN) {
        DecentralizedBGN stableCoinBGN = new DecentralizedBGN();
        return stableCoinBGN;
    }
}