// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// openzeppelin 라이브러리에 ERC1155를 Import
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

// is 키워드를 사용해 ERC1155를 상속 
// -> ERC1155 내 함수를 Contract 안에 사용 가능
contract AwesomeGame is ERC1155 {
    uint256 public constant GOLD = 0;
    uint256 public constant SILVER = 1;
    uint256 public constant SWORD = 2;
    uint256 public constant SHIELD = 3;
    uint256 public constant CROWN = 4;

    // 메타데이터를 관리하는 서버 주소로 ERC1155를 초기화시킨다.
    // 근데 이 서버 주소는 뭘까..?
    constructor() ERC1155("https://awesomegame.com/assets/{id}.json") {
        _mint(msg.sender, GOLD, 100 * 10**18, ""); // 마치 ERC20 - 10**18개가 모여야 1토큰이라고 블록체인에서 인식함
        _mint(msg.sender, SILVER, 500 * 10**18, ""); // 마치 ERC20
        _mint(msg.sender, SWORD, 1000, ""); // 마치 ERC721(NFT)
        _mint(msg.sender, SHIELD, 1000, "");
        _mint(msg.sender, CROWN, 1, ""); // 근데 사실 CROWN만 NFT - 개수가 1개니까
    }
}

// ERC-1155에서, uri 3의 메타데이터에 접근하고 싶다?
// 프론트엔드에서 직접 16진수 바꾸고 64자리 padding해서 id에 넣어라
//  https://awesomegame.com/assets/{id}.json