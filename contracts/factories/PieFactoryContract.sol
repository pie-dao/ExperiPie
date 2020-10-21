// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "diamond-3/contracts/Diamond.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IExperiPie.sol";

contract PieFactoryContract is Ownable {

    address[] public pies;
    mapping(address => bool) public isPie;
    address public defaultController;

    IDiamondCut.FacetCut[] public defaultCut;

    function setDefaultController(address _controller) external onlyOwner {
        defaultController = _controller;
    }

    function removeFacet(uint256 _index) external onlyOwner {
        defaultCut[_index] = defaultCut[defaultCut.length - 1];
        defaultCut.pop();
    }

    function addFacet(IDiamondCut.FacetCut memory _facet) external onlyOwner {
        defaultCut.push(_facet);
    }

    function bakePie(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _initialSupply,
        string memory _symbol,
        string memory _name
    ) external {
        Diamond d = new Diamond(defaultCut, address(this));

        pies.push(address(d));
        isPie[address(d)] = true;

        // emit DiamondCreated(address(d));
        require(_tokens.length != 0, "CANNOT_CREATE_ZERO_TOKEN_LENGTH_PIE");
        require(_tokens.length == _amounts.length, "ARRAY_LENGTH_MISMATCH");

        IExperiPie pie = IExperiPie(address(d));
        
        // Init erc20 facet
        pie.initialize(_initialSupply, _name, _symbol, 18);

        // Transfer and add tokens
        for(uint256 i = 0; i < _tokens.length; i ++) {
            IERC20 token = IERC20(_tokens[i]);
            require(token.transferFrom(msg.sender, address(pie), _amounts[i]), "TRANSFER_FAILED");
            pie.addToken(_tokens[i]);
        }

        // Unlock pool
        pie.setLock(1);

        // Uncap pool
        pie.setMaxCap(uint256(-1));

        // Send minted pie to msg.sender
        pie.transfer(msg.sender, _initialSupply);
        pie.transferOwnership(defaultController);
    }


}