// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;


import "forge-std/console.sol";
import "forge-std/Test.sol";
import "solady/src/utils/LibString.sol";
import "./Libraries/LibBytes.sol";



contract Helper is Test {
    using LibString for string;
    using BytesLib for bytes;

    function generateSelectors(string memory facetName) internal returns(bytes4[] memory functionSelectors) {
        // prepare command for cli
        string[] memory cmd = new string[](4);

        cmd[0] = "forge";
        cmd[1] = "inspect";
        cmd[2] = facetName;
        cmd[3] = "methods";

        bytes memory res = vm.ffi(cmd);
        string memory json = string(res);

        // remove curly braces
        string memory fir = json.replace("{", "");
        string memory sr = fir.replace("}", "");
        string[] memory result = sr.split("\n");
        functionSelectors = new bytes4[](result.length - 2);

        for (uint256 i = 1; i < result.length - 1; i++) {
            string[] memory item = result[i].split(":");

            string memory parsedSignatures = item[0];
            bytes memory signatureBytes = bytes(parsedSignatures);
            bytes memory sigres = signatureBytes.slice(3, (signatureBytes.length -3));
            bytes memory fnSignature = sigres.slice(0, (sigres.length - 1));

            bytes4 selector = bytes4(keccak256(fnSignature));

            functionSelectors[i - 1] = selector;
            console.logBytes4(selector);
        }
    }

    function assertEqSelectors(bytes4[] memory firstArray, bytes4[] memory secondArray) internal pure returns(bool) {
        if(firstArray.length != secondArray.length) return false;

        for (uint256 i = 0; i < firstArray.length; i++) {
            if(containSelector(firstArray, secondArray[i])) return true;
        }

        return false;
    }

    function containSelector(bytes4[] memory selectors, bytes4 selector) internal pure returns(bool) {
        for (uint256 i = 0; i < selectors.length; i++) {
            if(selector == selectors[i]) return true;
        }

        return false;
    }
}