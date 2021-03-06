pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../HandlerBase.sol";
import "./IMinter.sol";
import "./ILiquidityGauge.sol";

contract HCurveDao is HandlerBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // prettier-ignore
    address public constant CURVE_MINTER = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
    // prettier-ignore
    address public constant CRV_TOKEN = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    function getContractName() public pure override returns (string memory) {
        return "HCurveDao";
    }

    function mint(address gaugeAddr) external payable returns (uint256) {
        IMinter minter = IMinter(CURVE_MINTER);
        address user = _getSender();
        uint256 beforeCRVBalance = IERC20(CRV_TOKEN).balanceOf(user);
        if (minter.allowed_to_mint_for(address(this), user) == false)
            _revertMsg("mint", "not allowed to mint");

        try minter.mint_for(gaugeAddr, user) {} catch Error(
            string memory reason
        ) {
            _revertMsg("mint", reason);
        } catch {
            _revertMsg("mint");
        }
        uint256 afterCRVBalance = IERC20(CRV_TOKEN).balanceOf(user);

        _updateToken(CRV_TOKEN);
        return afterCRVBalance.sub(beforeCRVBalance);
    }

    function mintMany(address[] calldata gaugeAddrs)
        external
        payable
        returns (uint256)
    {
        IMinter minter = IMinter(CURVE_MINTER);
        address user = _getSender();
        uint256 beforeCRVBalance = IERC20(CRV_TOKEN).balanceOf(user);
        if (minter.allowed_to_mint_for(address(this), user) == false)
            _revertMsg("mintMany", "not allowed to mint");

        for (uint256 i = 0; i < gaugeAddrs.length; i++) {
            try minter.mint_for(gaugeAddrs[i], user) {} catch Error(
                string memory reason
            ) {
                _revertMsg(
                    "mintMany",
                    string(abi.encodePacked(reason, " on ", _uint2String(i)))
                );
            } catch {
                _revertMsg(
                    "mintMany",
                    string(abi.encodePacked("Unspecified on ", _uint2String(i)))
                );
            }
        }

        _updateToken(CRV_TOKEN);
        return IERC20(CRV_TOKEN).balanceOf(user).sub(beforeCRVBalance);
    }

    function deposit(address gaugeAddress, uint256 _value) external payable {
        ILiquidityGauge gauge = ILiquidityGauge(gaugeAddress);
        address token = gauge.lp_token();
        address user = _getSender();

        // if amount == uint256(-1) return balance of Proxy
        _value = _getBalance(token, _value);
        _tokenApprove(token, gaugeAddress, _value);

        try gauge.deposit(_value, user) {} catch Error(string memory reason) {
            _revertMsg("deposit", reason);
        } catch {
            _revertMsg("deposit");
        }
    }
}
