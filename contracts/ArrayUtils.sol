pragma solidity ^0.4.18;

library ArrayUtils {
    function indexOfAddress(address[] memory elements, address searchElement, uint fromIndex) public pure returns(int) {
        for (fromIndex; fromIndex < elements.length; fromIndex++) {
            if (elements[fromIndex] == searchElement) {
                return int(fromIndex);
            }
        }
        return -1;
    }
    
    function bytesEqual(bytes memory _a, bytes memory _b) public pure returns (bool) {
        if (_a.length != _b.length)
            return false;
        for (uint i = 0; i < _a.length; i ++)
            if (_a[i] != _b[i])
                return false;
        return true;
    }
}
