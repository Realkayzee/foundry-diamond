// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import { Diamond } from "../src/Diamond.sol";
import { DiamondCutFacet } from "../src/facets/DiamondCutFacet.sol";
import { IDiamondCut } from "../src/interfaces/IDiamondCut.sol";
import { DiamondLoupeFacet } from "../src/facets/DiamondLoupeFacet.sol";
import { OwnershipFacet } from "../src/facets/OwnershipFacet.sol";
import { DiamondInit } from "../src/upgradeInitializers/DiamondInit.sol";
import "./Helper.sol";

contract DeployDiamondScript is Script, IDiamondCut, Helper {
    function run() external {
        vm.startBroadcast(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);

        // deploy diamondCutFacet
        DiamondCutFacet diamondCutDeploy = new DiamondCutFacet();
        console.log("Diamond cut address deployed:", address(diamondCutDeploy));

        // deploy diamond
        Diamond diamond = new Diamond(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, address(diamondCutDeploy));
        console.log("Diamond address deployed:", address(diamond));

        // deploy diamondInit
        DiamondInit diamondInit = new DiamondInit();
        console.log("Diamond init deployed:", address(diamondInit));

        // deploy facets
        console.log("deploying facets.....");
        FacetCut[] memory cut = new FacetCut[](2);

        // diamond loupe facet
        DiamondLoupeFacet diamondLoupe = new DiamondLoupeFacet();
        cut[0] = FacetCut({
            facetAddress: address(diamondLoupe),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("DiamondLoupeFacet")
        });

        // Ownership facet
        OwnershipFacet ownership = new OwnershipFacet();
        cut[1] = FacetCut({
            facetAddress: address(ownership),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("OwnershipFacet")
        });
        bytes memory functionCall = abi.encodeWithSignature("init()");

        // upgrade diamond with facet
        IDiamondCut(address(diamond)).diamondCut(cut, address(diamondInit), functionCall);

        // call a function
        address[] memory facetAddresses =  DiamondLoupeFacet(address(diamond)).facetAddresses();

        for (uint256 i = 0; i < facetAddresses.length; i++) {
            console.log("facet addresses", facetAddresses[i]);
        }

        vm.stopBroadcast();
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}