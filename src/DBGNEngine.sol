// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {DecentralizedBGN} from "./DecentralizedBGN.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DBGEngine {
    error DBGEngine__TokenAddressesAndPriceFeedAddressesLengthsDontMatch(
        uint256 tokenAddressesLength, uint256 priceFeedAddressesLength
    );
    error DBGEngine__AmountIsZero();
    error DBGEngine__TokenIsNotAllowed(address _tokenAddress);
    error DBGEngine__TransferFailed();
    error DBGNEngine__HealthFactorIsBelowMinHealthFactor(uint256 healthFactor, uint256 minHealthFactor);

    uint256 private constant MIN_HEALTH_FACTOR = 1;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    

    DecentralizedBGN private immutable i_stableCoinBGN;
    mapping(address collateralToken => address priceFeed) private s_priceFeeds;
    address[] private s_collateralTokens;
    mapping(address user => mapping(address collateralToken => uint256 amount)) private s_userCollateralAmounts;
    mapping (address user => uint256 tokensMinted) private s_userTokensMinted;

    constructor(DecentralizedBGN _stableCoinBGN, address[] memory tokenAddresses, address[] memory priceFeedAddresses) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            //TODO: Check gas usage
            revert DBGEngine__TokenAddressesAndPriceFeedAddressesLengthsDontMatch(
                tokenAddresses.length, priceFeedAddresses.length
            );
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_stableCoinBGN = _stableCoinBGN;
    }

    event CollateralDeposited(address indexed user, address indexed collateralToken, uint256 amount);

    modifier moreThanZero(uint256 _amount) {
        if (_amount == 0) {
            revert DBGEngine__AmountIsZero();
        }
        _;
    }

    modifier isAllowedToken(address _tokenAddress) {
        if (s_priceFeeds[_tokenAddress] == address(0)) {
            revert DBGEngine__TokenIsNotAllowed(_tokenAddress);
        }
        _;
    }

    function depositCollateralAndMintDBGN() external {}

    function depositCollateral(address _collateralTokenAddress, uint256 _amount)
        external
        moreThanZero(_amount)
        isAllowedToken(_collateralTokenAddress)
    {
        s_userCollateralAmounts[msg.sender][_collateralTokenAddress] += _amount;
        emit CollateralDeposited(msg.sender, _collateralTokenAddress, _amount);

        bool success = IERC20(_collateralTokenAddress).transferFrom(msg.sender, address(this), _amount);

        if (!success) {
            revert DBGEngine__TransferFailed();
        }
    }

    function redeemCollateralAndBurnDBGN() external {}

    function redeemCollateral() external {}

    function mintDBGN(uint256 _amountDBGNToMint) external moreThanZero(_amountDBGNToMint) {
        revertIfHealthFactorIsBelowMinHealthFactor(msg.sender);

        s_userTokensMinted[msg.sender] += _amountDBGNToMint;
    }
    function burnDBGN() external {}

    function liquidate() external {}

    function getAccountsCollateralValue(address _user) public view returns (uint256 totalCollateralValueUSD) {
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address collateralToken = s_collateralTokens[i];
            uint256 collateralAmount = s_userCollateralAmounts[_user][collateralToken];
            totalCollateralValueUSD += getUSDValue(collateralToken, collateralAmount);
        }
    }

    function getUSDValue(address _collateralToken, uint256 _amount) private view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[_collateralToken]);
        (,int256 price,,,) = priceFeed.latestRoundData();
        return uint256(price) * 1e10 * _amount / PRECISION; // TODO: Check if this is correct
    }

    function getAccountInformation(address _user) public view returns (uint256 totalDBGNMinted, uint256 totalCollateralValueUSD) {
        totalDBGNMinted = s_userTokensMinted[_user];
        totalCollateralValueUSD = getAccountsCollateralValue(_user);
    }

    function getHealthFactor(address _user) private view returns (uint256 healthFactor) {
        (uint256 totalDBGNMinted, uint256 totalCollateralValueUSD) = getAccountInformation(_user);
        uint256 collateralAdjustedThreshold = totalCollateralValueUSD * LIQUIDATION_THRESHOLD / LIQUIDATION_PRECISION;
        healthFactor = collateralAdjustedThreshold * PRECISION / totalDBGNMinted;
    }

    function revertIfHealthFactorIsBelowMinHealthFactor(address _user) private view {
        uint256 healthFactor = getHealthFactor(_user);
        if (healthFactor < MIN_HEALTH_FACTOR) {
            revert DBGNEngine__HealthFactorIsBelowMinHealthFactor(healthFactor, MIN_HEALTH_FACTOR);
        }
    }
}
