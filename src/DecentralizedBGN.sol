// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedBGN is ERC20Burnable, Ownable {
    
    error StableCoinBGN__NotEnoughBalance(uint256 balance, uint256 amount);
    error StableCoinBGN__AmountIsZero();

    constructor() ERC20("StableCoinBGN", "BGN") {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if(balance < _amount) {
            revert StableCoinBGN__NotEnoughBalance(balance, _amount);
        }

        if(_amount == 0) {
            revert StableCoinBGN__AmountIsZero();
        }

        super.burn(_amount);
    }
    
    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_amount == 0) {
            revert StableCoinBGN__AmountIsZero();
        }
        _mint(_to, _amount);

        return true; //???
    }
}