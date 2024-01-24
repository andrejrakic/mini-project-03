// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract TrueDegenHelper {
  // Check NftP2PDexForTrueDegens.t.sol for usage
  function generateInitiateSwapExtraData(
    address _from,
    address _leftSideNftAddress,
    uint256 _leftSideNftInId,
    address _rightSideNftAddress,
    uint256 _rightSideNftId
  ) external pure returns (bytes memory) {
    return
      abi.encodeWithSignature(
        "initiateSwap(address,address,uint256,address,uint256)",
        _from,
        _leftSideNftAddress,
        _leftSideNftInId,
        _rightSideNftAddress,
        _rightSideNftId
      );
  }

  function generateAcceptSwapExtraData(
    address _from,
    address _leftSideNftAddress,
    uint256 _leftSideNftInId,
    address _rightSideNftAddress,
    uint256 _rightSideNftId
  ) external pure returns (bytes memory) {
    return
      abi.encodeWithSignature(
        "acceptSwap(address,address,uint256,address,uint256)",
        _from,
        _leftSideNftAddress,
        _leftSideNftInId,
        _rightSideNftAddress,
        _rightSideNftId
      );
  }
}
