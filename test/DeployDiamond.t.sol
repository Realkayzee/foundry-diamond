// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;


import "forge-std/Test.sol";
import { Diamond } from "../src/Diamond.sol";
import { DiamondCutFacet } from "../src/facets/DiamondCutFacet.sol";
import { DiamondLoupeFacet } from "../src/facets/DiamondLoupeFacet.sol";
import { OwnershipFacet } from "../src/facets/OwnershipFacet.sol";
import { IDiamondCut } from "../src/interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "../src/interfaces/IDiamondLoupe.sol";
import { DiamondInit } from "../src/upgradeInitializers/DiamondInit.sol";
import "../script/Helper.sol";


contract DeployDiamondTest is Test, IDiamondCut, Helper {

    Diamond diamond;
    DiamondCutFacet diamondCutDeploy;
    DiamondLoupeFacet diamondLoupe;
    DiamondInit diamondInit;
    OwnershipFacet ownership;
    address[] facetAddressList;
    function setUp() public {
        diamondCutDeploy = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(diamondCutDeploy));
        diamondInit = new DiamondInit();
        diamondLoupe = new DiamondLoupeFacet();
        ownership = new OwnershipFacet();


        // upgrade diamond with facets
        FacetCut[] memory cut = new FacetCut[](2);

        cut[0] = FacetCut({
            facetAddress: address(diamondLoupe),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("DiamondLoupeFacet")
        });

        cut[1] = FacetCut({
            facetAddress: address(ownership),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("OwnershipFacet")
        });

        // upgrade diamond with facet
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // call a function
        facetAddressList = DiamondLoupeFacet(address(diamond)).facetAddresses();
    }

    // check the recent added facet
    function testHasThreeFacet() public {
        assertEq(facetAddressList.length, 3);
    }

    // check facet selectors of diamond loupe address present in diamond
    function testFacetFunctionSelectors() public {
        bytes4[] memory computedSelectors = generateSelectors("DiamondLoupeFacet");
        bytes4[] memory facetFunctionSelectors = IDiamondLoupe(address(diamond)).facetFunctionSelectors(address(diamondLoupe));

        assertEqSelectors(computedSelectors, facetFunctionSelectors);

    }

    // remove a function selector and test if avaialble after removal
    function testRemoveAddFacetFunctionSelector() public {
        // compute facet address function selector
        bytes4 computeSelector = bytes4(bytes32(keccak256("facetAddress(bytes4)")));
        bytes4[] memory _selector = new bytes4[](1);
        _selector[0] = computeSelector;
        FacetCut[] memory cut = new FacetCut[](1);
        cut[0] = FacetCut({
            facetAddress: address(0),
            action: FacetCutAction.Remove,
            functionSelectors: _selector
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
        bytes4[] memory facetFunctionSelectors = IDiamondLoupe(address(diamond)).facetFunctionSelectors(address(diamondLoupe));
        assertFalse(containSelector(facetFunctionSelectors, computeSelector));

        cut[0] = FacetCut({
            facetAddress: address(diamondLoupe),
            action: FacetCutAction.Add,
            functionSelectors: _selector
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
        bytes4[] memory facetFunctionSelectorsAfter = IDiamondLoupe(address(diamond)).facetFunctionSelectors(address(diamondLoupe));
        assertTrue(containSelector(facetFunctionSelectorsAfter, computeSelector));
    }


    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}