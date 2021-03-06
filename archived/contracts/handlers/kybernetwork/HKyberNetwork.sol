pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../HandlerBase.sol";
import "./IKyberNetworkProxy.sol";

contract HKyberNetwork is HandlerBase {
    using SafeERC20 for IERC20;

    // prettier-ignore
    address public constant ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // prettier-ignore
    address public constant KYBERNETWORK_PROXY = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755;

    function getContractName() public pure override returns (string memory) {
        return "HKyberNetwork";
    }

    function swapEtherToToken(
        uint256 value,
        address token,
        uint256 minRate
    ) external payable returns (uint256 destAmount) {
        IKyberNetworkProxy kyber = IKyberNetworkProxy(KYBERNETWORK_PROXY);
        value = _getBalance(ETH_TOKEN_ADDRESS, value);
        try
            kyber.swapEtherToToken.value(value)(IERC20(token), minRate)
        returns (uint256 amount) {
            destAmount = amount;
        } catch Error(string memory reason) {
            _revertMsg("swapEtherToToken", reason);
        } catch {
            _revertMsg("swapEtherToToken");
        }

        // Update involved token
        _updateToken(token);
    }

    function swapTokenToEther(
        address token,
        uint256 tokenQty,
        uint256 minRate
    ) external payable returns (uint256 destAmount) {
        IKyberNetworkProxy kyber = IKyberNetworkProxy(KYBERNETWORK_PROXY);
        tokenQty = _getBalance(token, tokenQty);
        IERC20(token).safeApprove(address(kyber), tokenQty);
        try kyber.swapTokenToEther(IERC20(token), tokenQty, minRate) returns (
            uint256 amount
        ) {
            destAmount = amount;
        } catch Error(string memory reason) {
            _revertMsg("swapTokenToEther", reason);
        } catch {
            _revertMsg("swapTokenToEther");
        }
        IERC20(token).safeApprove(address(kyber), 0);
    }

    function swapTokenToToken(
        address srcToken,
        uint256 srcQty,
        address destToken,
        uint256 minRate
    ) external payable returns (uint256 destAmount) {
        IKyberNetworkProxy kyber = IKyberNetworkProxy(KYBERNETWORK_PROXY);
        srcQty = _getBalance(srcToken, srcQty);
        IERC20(srcToken).safeApprove(address(kyber), srcQty);
        try
            kyber.swapTokenToToken(
                IERC20(srcToken),
                srcQty,
                IERC20(destToken),
                minRate
            )
        returns (uint256 amount) {
            destAmount = amount;
        } catch Error(string memory reason) {
            _revertMsg("swapTokenToToken", reason);
        } catch {
            _revertMsg("swapTokenToToken");
        }
        IERC20(srcToken).safeApprove(address(kyber), 0);

        // Update involved token
        _updateToken(destToken);
    }
}
