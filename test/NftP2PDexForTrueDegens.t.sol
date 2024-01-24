// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Test} from "forge-std/Test.sol";
import {NftP2PDexForTrueDegens} from "../src/NftP2PDexForTrueDegens.sol";
import {TrueDegenHelper} from "../src/TrueDegenHelper.sol";
import {ERC721} from "../src/vendor/@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockNft is ERC721 {
  uint256 private _nextTokenId;

  constructor() ERC721("MockNft", "$MOCK") {}

  function mint() external returns (uint256 tokenId) {
    tokenId = _nextTokenId++;
    _safeMint(msg.sender, tokenId);
  }
}

contract NftP2PDexForTrueDegensTest is Test {
  NftP2PDexForTrueDegens public dex;
  TrueDegenHelper internal helper;
  MockNft internal nft;

  address internal alice;
  address internal bob;
  uint256 internal leftTokenId;
  uint256 internal rightTokenId;

  function setUp() public {
    alice = makeAddr("alice");
    bob = makeAddr("bob");

    nft = new MockNft();

    vm.startPrank(alice);
    leftTokenId = nft.mint();
    vm.stopPrank();

    vm.startPrank(bob);
    rightTokenId = nft.mint();
    vm.stopPrank();

    assertEq(nft.ownerOf(leftTokenId), alice);
    assertEq(nft.ownerOf(rightTokenId), bob);

    dex = new NftP2PDexForTrueDegens();
    helper = new TrueDegenHelper();
  }

  function test_InitiateSwap() public {
    vm.startPrank(alice);
    bytes memory data = helper.generateInitiateSwapExtraData(
      alice,
      address(nft),
      leftTokenId,
      address(nft),
      rightTokenId
    );
    nft.safeTransferFrom(alice, address(dex), leftTokenId, data);
    vm.stopPrank();

    assertEq(nft.ownerOf(leftTokenId), address(dex));
  }

  function test_CancelSwap() external {
    test_InitiateSwap();

    vm.startPrank(alice);
    dex.cancelSwap(address(nft), leftTokenId, address(nft), rightTokenId);
    assertEq(nft.ownerOf(leftTokenId), alice);
    vm.stopPrank();
  }

  function test_CancelSwap_RevertIfCallerIsNotInitiator() external {
    test_InitiateSwap();

    vm.startPrank(bob);

    vm.expectRevert("Only swap initiator can call");
    dex.cancelSwap(address(nft), leftTokenId, address(nft), rightTokenId);

    vm.stopPrank();
  }

  function test_AcceptSwap() external {
    test_InitiateSwap();

    vm.startPrank(bob);
    bytes memory acceptSwapData = helper.generateAcceptSwapExtraData(
      bob,
      address(nft),
      leftTokenId,
      address(nft),
      rightTokenId
    );
    nft.safeTransferFrom(bob, address(dex), rightTokenId, acceptSwapData);
    vm.stopPrank();

    assertEq(nft.ownerOf(leftTokenId), bob);
    assertEq(nft.ownerOf(rightTokenId), alice);
  }

  function test_AcceptSwap_RevertIfInvalidSwapDetailsAreProvided() external {
    test_InitiateSwap();

    vm.startPrank(bob);
    bytes memory acceptSwapData = helper.generateAcceptSwapExtraData(
      bob,
      address(nft),
      rightTokenId,
      address(nft),
      rightTokenId
    );

    vm.expectRevert("Invalid swap details");
    nft.safeTransferFrom(bob, address(dex), rightTokenId, acceptSwapData);

    vm.stopPrank();
  }
}
