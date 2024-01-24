// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IERC721} from "./vendor/@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "./vendor/@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ReentrancyGuard} from "./vendor/@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Check NftP2PDexForTrueDegens.t.sol for usage
contract NftP2PDexForTrueDegens is IERC721Receiver, ReentrancyGuard {
  mapping(bytes32 nftSwapDetails => address swapInitiator) public s_ongoingSwaps;

  modifier onlySelf() {
    require(msg.sender == address(this), "Only Self");
    _;
  }

  event SwapInitiated(
    address swapInitiator,
    address leftSideNftAddress,
    uint256 leftSideNftId,
    address rightSideNftAddress,
    uint256 rightSideNftId
  );
  event SwapPerformed(
    address swapInitiator,
    address swapAcceptor,
    address leftSideNftAddress,
    uint256 leftSideNftId,
    address rightSideNftAddress,
    uint256 rightSideNftId
  );
  event SwapCanceled(
    address swapInitiator,
    address leftSideNftAddress,
    uint256 leftSideNftId,
    address rightSideNftAddress,
    uint256 rightSideNftId
  );

  function onERC721Received(
    address /*operator*/,
    address /*from*/,
    uint256 /*tokenId*/,
    bytes calldata data
  ) external returns (bytes4) {
    (bool success, bytes memory returnData) = address(this).call(data);
    if (!success) {
      assembly {
        revert(add(returnData, 32), returnData)
      }
    }
    return IERC721Receiver.onERC721Received.selector;
  }

  function initiateSwap(
    address _from,
    address _leftSideNftAddress,
    uint256 _leftSideNftInId,
    address _rightSideNftAddress,
    uint256 _rightSideNftId
  ) public onlySelf {
    bytes32 nftSwapDetails = keccak256(
      abi.encodePacked(_leftSideNftAddress, _leftSideNftInId, _rightSideNftAddress, _rightSideNftId)
    );

    require(s_ongoingSwaps[nftSwapDetails] == address(0), "Already initiated");

    s_ongoingSwaps[nftSwapDetails] = _from;

    emit SwapInitiated(_from, _leftSideNftAddress, _leftSideNftInId, _rightSideNftAddress, _rightSideNftId);
  }

  function acceptSwap(
    address _from,
    address _leftSideNftAddress,
    uint256 _leftSideNftInId,
    address _rightSideNftAddress,
    uint256 _rightSideNftId
  ) public onlySelf nonReentrant {
    bytes32 nftSwapDetails = keccak256(
      abi.encodePacked(_leftSideNftAddress, _leftSideNftInId, _rightSideNftAddress, _rightSideNftId)
    );

    address swapInitiator = s_ongoingSwaps[nftSwapDetails];

    require(swapInitiator != address(0), "Invalid swap details");

    IERC721(_leftSideNftAddress).safeTransferFrom(address(this), _from, _leftSideNftInId);
    IERC721(_rightSideNftAddress).safeTransferFrom(address(this), swapInitiator, _rightSideNftId);

    delete s_ongoingSwaps[nftSwapDetails];

    emit SwapPerformed(
      swapInitiator,
      _from,
      _leftSideNftAddress,
      _leftSideNftInId,
      _rightSideNftAddress,
      _rightSideNftId
    );
  }

  function cancelSwap(
    address _leftSideNftAddress,
    uint256 _leftSideNftInId,
    address _rightSideNftAddress,
    uint256 _rightSideNftId
  ) external nonReentrant {
    bytes32 nftSwapDetails = keccak256(
      abi.encodePacked(_leftSideNftAddress, _leftSideNftInId, _rightSideNftAddress, _rightSideNftId)
    );

    require(s_ongoingSwaps[nftSwapDetails] == msg.sender, "Only swap initiator can call");

    IERC721(_leftSideNftAddress).safeTransferFrom(address(this), msg.sender, _leftSideNftInId);

    emit SwapCanceled(msg.sender, _leftSideNftAddress, _leftSideNftInId, _rightSideNftAddress, _rightSideNftId);
  }
}
