// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// contract 배포자만 특정 함수에 접근할 수 있게 하는 라이브러리
import "@openzeppelin/contracts/access/Ownable.sol";
// 숫자를 string으로 변환
import "@openzeppelin/contracts/utils/Strings.sol";
// ID를 increment(증가)할 때
import "@openzeppelin/contracts/utils/Counters.sol";
// 토큰 아이디가 몇개 minting됐는지 알려주는 
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract SnowmenGame is ERC1155Supply, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter public folderId;

    // 폴더의 id를 string으로 맵핑
    mapping(uint256 => string) public metadataHash;
    mapping(address => bool) private _authorized; // false: 권한 없음

    modifier onlyAuthorized() {
        require(
            _authorized[msg.sender] || owner() == msg.sender,
            "not authorized"
        );
        _;
    }
    // Ownable(_msgSender()) 로 이 함수의 주인이 누군지
    // ERC1155(서버주소)
    constructor() Ownable(_msgSender()) ERC1155("") {
        folderId.increment();
    }

    function mint(address receiver, uint256 tokenId, uint256 quantity) external onlyAuthorized{
        _mint(receiver, tokenId, quantity, "");
    }

    function confirmUpload(string calldata cidHash) external onlyOwner {
        metadataHash[folderId.current()] = cidHash; //current에 cidHash mapping 해라
        folderId.increment(); // 다음 폴더 번호 ㄱㄱ
    }

    function getIds(uint256 numOfMeta) external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](numOfMeta);

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 tokenId = (folderId.current() << 128) | i;
            ids[i] = tokenId;
        }

        return ids;
    }

    //메타데이터 저장하는 곳
    //tokenId.js로 Metadata 저장해놔야 나중에 파일 찾기 쉬움
    // 아 오른쪽 쉬프트로 진짜 아이템 ID를 알 수 있는 거고, 왼쪽으로는 아이템 ID (sword) 의 복사본을 만든다는 개념

    function tokenToFolderId(uint256 tokenId) public pure returns (uint256) {
        return tokenId >> 128;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return (
            string( // 2. string으로 변환
                abi.encodePacked( // 1. bytetype으로 변환하고
                    "ipfs://",
                    metadataHash[tokenToFolderId(tokenId)],
                    "/",
                    Strings.toString(tokenId),
                    ".json"
                )
            )
        );
    }

    function addAuthorized(address authorized) external onlyOwner {
        _authorized[authorized] = true;
    }

    function removeAuthorized(address authorized) external onlyOwner {
        _authorized[authorized] = false;
    }
}