// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SpellStrikerDuels.sol";
import "../src/Errors.sol";
import "openzeppelin-contracts/token/ERC721/ERC721.sol";

contract SpellStrikerDuelTest is Test {
    SpellStrikers strikers;
    SpellStrikerDuels duels;
    SelectSpellVerifier selectSpellVerifier;
    CastSpellVerifier castSpellVerifier;

    modifier assumeValidAddress(address a) {
        vm.assume(a > address(10));
        vm.assume(a != address(this));
        vm.assume(a != address(vm));
        _;
    }

    modifier assumeValidTokenId(uint256 tokenId) {
        vm.assume(tokenId != 0);
        _;
    }

    function setUp() public {
        selectSpellVerifier = new SelectSpellVerifier();
        castSpellVerifier = new CastSpellVerifier();
        strikers = new SpellStrikers();
        duels = new SpellStrikerDuels(
            strikers,
            selectSpellVerifier,
            castSpellVerifier
        );
    }

    function testCreateDuelRightfulOwner(address host, uint256 spellStrikerId)
        public
        assumeValidAddress(host)
        assumeValidTokenId(spellStrikerId)
    {
        // mock that guarantees that host is owner of spellstriker id
        _mockSpellStriker(host, spellStrikerId, 1, 1);
        uint256 id = _createDuel(host, spellStrikerId);
        SpellStrikerDuels.Duel memory duel = duels.get(id);
        assertEq(duel.id, id);
        assertTrue(duel.status == SpellStrikerDuels.DuelStatus.PENDING);
    }

    function testCreateDuelDifferentOwner(
        address host,
        address other,
        uint256 spellStrikerId
    )
        public
        assumeValidAddress(host)
        assumeValidAddress(other)
        assumeValidTokenId(spellStrikerId)
    {
        vm.assume(host != other);
        // mock that guarantees that `other` is owner of spellstriker id
        _mockSpellStriker(other, spellStrikerId, 1, 1);
        vm.expectRevert(Unauthorized.selector);
        _createDuel(host, spellStrikerId);
    }

    function testJoinAndStartDuelActive(
        address host,
        uint256 hostSpellStrikerId,
        address guest,
        uint256 guestSpellStrikerId
    )
        public
        assumeValidAddress(host)
        assumeValidAddress(guest)
        assumeValidTokenId(hostSpellStrikerId)
        assumeValidTokenId(guestSpellStrikerId)
    {
        vm.assume(host != guest);
        vm.assume(hostSpellStrikerId != guestSpellStrikerId);

        // joining with a mocked spell striker that should definately lose independently of the duel logic:
        //  10/10 (host) vs 2/2 (guest)
        _mockSpellStriker(host, hostSpellStrikerId, 10, 10);
        _mockSpellStriker(guest, guestSpellStrikerId, 2, 2);

        uint256 id = _createDuel(host, hostSpellStrikerId);

        _joinDuel(guest, id, guestSpellStrikerId);
        _startDuel(host, id);

        SpellStrikerDuels.Duel memory duel = duels.get(id);
        SpellStrikerDuels.Record memory hostRecord = duels
            .getSpellStrikerRecord(hostSpellStrikerId);
        SpellStrikerDuels.Record memory guestRecord = duels
            .getSpellStrikerRecord(guestSpellStrikerId);

        assertTrue(duel.status == SpellStrikerDuels.DuelStatus.RESOLVED);
        assertEq(duel.winner, hostSpellStrikerId);
        assertEq(hostRecord.wins, 1);
        assertEq(hostRecord.losses, 0);
        assertEq(hostRecord.draws, 0);
        assertEq(guestRecord.wins, 0);
        assertEq(guestRecord.losses, 1);
        assertEq(guestRecord.draws, 0);
    }

    function testJoinDuelFinished(
        address host,
        uint256 hostSpellStrikerId,
        address guest,
        uint256 guestSpellStrikerId
    )
        public
        assumeValidAddress(host)
        assumeValidAddress(guest)
        assumeValidTokenId(hostSpellStrikerId)
        assumeValidTokenId(guestSpellStrikerId)
    {
        vm.assume(host != guest);
        vm.assume(hostSpellStrikerId != guestSpellStrikerId);

        _mockSpellStriker(host, hostSpellStrikerId, 10, 10);
        _mockSpellStriker(guest, guestSpellStrikerId, 2, 2);
        uint256 id = _createDuel(host, hostSpellStrikerId);

        _joinDuel(guest, id, guestSpellStrikerId);

        vm.expectRevert(DuelNotActive.selector);
        _joinDuel(guest, id, guestSpellStrikerId);
    }

    function testJoinDuelUnexisting(
        address guest,
        uint256 guestSpellStrikerId,
        uint256 duelId
    ) public assumeValidAddress(guest) assumeValidTokenId(guestSpellStrikerId) {
        _mockSpellStriker(guest, guestSpellStrikerId, 2, 2);

        vm.expectRevert(DuelNotFound.selector);
        _joinDuel(guest, duelId, guestSpellStrikerId);
    }

    function testManaRegen(address owner, uint256 spellStrikerId)
        public
        assumeValidAddress(owner)
        assumeValidTokenId(spellStrikerId)
    {
        _mockSpellStriker(owner, spellStrikerId, 2, 2);

        uint256 manaBefore = duels.getSpellStrikerRecord(spellStrikerId).mana;
        skip(5 days);
        uint256 manaAfter = duels.getSpellStrikerRecord(spellStrikerId).mana;
        assertGt(manaAfter, manaBefore);
    }

    function testManaBurn(
        address host,
        uint256 hostSpellStrikerId,
        address guest,
        uint256 guestSpellStrikerId
    )
        public
        assumeValidAddress(host)
        assumeValidAddress(guest)
        assumeValidTokenId(hostSpellStrikerId)
        assumeValidTokenId(guestSpellStrikerId)
    {
        vm.assume(host != guest);
        vm.assume(hostSpellStrikerId != guestSpellStrikerId);

        _mockSpellStriker(host, hostSpellStrikerId, 2, 2);
        _mockSpellStriker(guest, guestSpellStrikerId, 2, 2);

        uint256 id = _createDuel(host, hostSpellStrikerId);

        uint256 hostManaBefore = duels
            .getSpellStrikerRecord(hostSpellStrikerId)
            .mana;
        uint256 guestManaBefore = duels
            .getSpellStrikerRecord(guestSpellStrikerId)
            .mana;

        _joinDuel(guest, id, guestSpellStrikerId);
        _startDuel(host, id);

        uint256 hostManaAfter = duels
            .getSpellStrikerRecord(hostSpellStrikerId)
            .mana;
        uint256 guestManaAfter = duels
            .getSpellStrikerRecord(guestSpellStrikerId)
            .mana;

        assertLt(hostManaAfter, hostManaBefore);
        assertLt(guestManaAfter, guestManaBefore);
    }

    function testCreateDuelNoMana(address host, uint256 spellStrikerId)
        public
        assumeValidAddress(host)
        assumeValidTokenId(spellStrikerId)
    {
        vm.mockCall(
            address(duels),
            abi.encodeWithSelector(
                SpellStrikerDuels.getSpellStrikerRecord.selector,
                spellStrikerId
            ),
            abi.encode(
                SpellStrikerDuels.Record({
                    wins: 0,
                    losses: 0,
                    draws: 0,
                    mana: 0,
                    lastManaRefresh: block.timestamp
                })
            )
        );

        // mock that guarantees that host is owner of spellstriker id
        _mockSpellStriker(host, spellStrikerId, 1, 1);
        vm.expectRevert(NotEnoughMana.selector);
        _createDuel(host, spellStrikerId);
    }

    function testJoinDuelNoMana(
        address host,
        uint256 hostSpellStrikerId,
        address guest,
        uint256 guestSpellStrikerId
    )
        public
        assumeValidAddress(host)
        assumeValidAddress(guest)
        assumeValidTokenId(hostSpellStrikerId)
        assumeValidTokenId(guestSpellStrikerId)
    {
        vm.assume(host != guest);
        vm.assume(hostSpellStrikerId != guestSpellStrikerId);

        _mockSpellStriker(host, hostSpellStrikerId, 1, 1);
        _mockSpellStriker(guest, guestSpellStrikerId, 1, 1);

        uint256 id = _createDuel(host, hostSpellStrikerId);

        vm.mockCall(
            address(duels),
            abi.encodeWithSelector(
                SpellStrikerDuels.getSpellStrikerRecord.selector,
                guestSpellStrikerId
            ),
            abi.encode(
                SpellStrikerDuels.Record({
                    wins: 0,
                    losses: 0,
                    draws: 0,
                    mana: 0,
                    lastManaRefresh: block.timestamp
                })
            )
        );

        vm.expectRevert(NotEnoughMana.selector);
        _joinDuel(guest, id, guestSpellStrikerId);
    }

    function testJoinDuelHostNoMana(
        address host,
        uint256 hostSpellStrikerId,
        address guest,
        uint256 guestSpellStrikerId
    )
        public
        assumeValidAddress(host)
        assumeValidAddress(guest)
        assumeValidTokenId(hostSpellStrikerId)
        assumeValidTokenId(guestSpellStrikerId)
    {
        vm.assume(host != guest);
        vm.assume(hostSpellStrikerId != guestSpellStrikerId);

        _mockSpellStriker(host, hostSpellStrikerId, 1, 1);
        _mockSpellStriker(guest, guestSpellStrikerId, 1, 1);

        uint256 id = _createDuel(host, hostSpellStrikerId);

        vm.mockCall(
            address(duels),
            abi.encodeWithSelector(
                SpellStrikerDuels.getSpellStrikerRecord.selector,
                hostSpellStrikerId
            ),
            abi.encode(
                SpellStrikerDuels.Record({
                    wins: 0,
                    losses: 0,
                    draws: 0,
                    mana: 0,
                    lastManaRefresh: block.timestamp
                })
            )
        );

        vm.expectRevert(NotEnoughMana.selector);
        _joinDuel(guest, id, guestSpellStrikerId);
    }

    function _createDuel(address host, uint256 spellStrikerId)
        internal
        returns (uint256)
    {
        vm.prank(host);
        return
            duels.create(
                spellStrikerId,
                [
                    0x2fe835bf4075b4e6096bb78a8573c7eb9ce52d5426d058659a227839617dda02,
                    0x2e9d057b49b56f94e6a6915b364cf13da928286b635f6ddb00ac09a8e1d7367a
                ],
                [
                    [
                        0x118805b490d9227d3f7e0f55f103d5c32e1004f4fa08c4d95673fd6e70fbf904,
                        0x17d9f5b071bd9d7893852060d97074a472541f9fbe4cc3b182a859f239bf3efb
                    ],
                    [
                        0x0d8074ebb2fe66663a56206d1c3246be7ceb025c77af27e6087722660ac45fe5,
                        0x05817b5629e6b6353753a579313dcf6f4c6e6100390b7e7b1fef87e4d7506621
                    ]
                ],
                [
                    0x2e376b79795597f2764af79186dc1bcaace67757cecb7f4bf2a4e12f25295599,
                    0x08630a885420e35e9b0bb1338a620fa22f66d54c76dfc3f53bcaacc05097f04b
                ],
                [
                    0x0e87f011687d4e5a7b11dd54b8eaad4c2188865b9691a0086b3ac3859c956187
                ]
            );
    }

    function _joinDuel(
        address guest,
        uint256 duelId,
        uint256 spellStrikerId
    ) internal returns (uint256) {
        vm.prank(guest);
        return
            duels.join(
                duelId,
                spellStrikerId,
                [
                    0x1536e43af1154706fd2e109885901948deb97ac2415e888e7f2c7b3abbac51be,
                    0x028d7da49c1bc655ac2015e58bb31891124491d4a6cec05809b10fd32447b7e3
                ],
                [
                    [
                        0x04083341066f3445d794e35a9a5cd7ce4708617e275b3d376c413239e2458811,
                        0x02aef41a7f82f6677fbb16a57edb24216d3578c9725a5943291db9dfebdc2e15
                    ],
                    [
                        0x12c844fb3b3276acc0b0f6c3d2271ee24fcfc754b23303335b109421a28cfd60,
                        0x0e79bb2c730b35902a5467b01b19402fd9f5f59f2dbb2e8d2d583352e247f8c3
                    ]
                ],
                [
                    0x1b67c9468f8a70f9bcc296b71a9f57ce46d9417eef8d1afdf13ce0269dd9957b,
                    0x24f3823c51d3fb38dfc7794e8fee295eeca1a5f3f5f53574848baf7c187fa957
                ],
                [
                    0x0e87f011687d4e5a7b11dd54b8eaad4c2188865b9691a0086b3ac3859c956187,
                    0x0000000000000000000000000000000000000000000000000000000000000001
                ]
            );
    }

    function _startDuel(address host, uint256 id) internal {
        vm.prank(host);
        duels.start(
            id,
            [
                0x1536e43af1154706fd2e109885901948deb97ac2415e888e7f2c7b3abbac51be,
                0x028d7da49c1bc655ac2015e58bb31891124491d4a6cec05809b10fd32447b7e3
            ],
            [
                [
                    0x04083341066f3445d794e35a9a5cd7ce4708617e275b3d376c413239e2458811,
                    0x02aef41a7f82f6677fbb16a57edb24216d3578c9725a5943291db9dfebdc2e15
                ],
                [
                    0x12c844fb3b3276acc0b0f6c3d2271ee24fcfc754b23303335b109421a28cfd60,
                    0x0e79bb2c730b35902a5467b01b19402fd9f5f59f2dbb2e8d2d583352e247f8c3
                ]
            ],
            [
                0x1b67c9468f8a70f9bcc296b71a9f57ce46d9417eef8d1afdf13ce0269dd9957b,
                0x24f3823c51d3fb38dfc7794e8fee295eeca1a5f3f5f53574848baf7c187fa957
            ],
            [
                0x0e87f011687d4e5a7b11dd54b8eaad4c2188865b9691a0086b3ac3859c956187,
                0x0000000000000000000000000000000000000000000000000000000000000001
            ]
        );
    }

    function _mockSpellStriker(
        address owner,
        uint256 spellStrikerId,
        uint8 power,
        uint8 resistance
    ) internal {
        vm.mockCall(
            address(strikers),
            abi.encodeWithSelector(ERC721.ownerOf.selector, spellStrikerId),
            abi.encode(owner)
        );

        vm.mockCall(
            address(strikers),
            abi.encodeWithSelector(SpellStrikers.get.selector, spellStrikerId),
            abi.encode(_createSpellStriker(spellStrikerId, power, resistance))
        );
    }

    function _createSpellStriker(
        uint256 id,
        uint8 power,
        uint8 resistance
    ) internal pure returns (SpellStrikers.SpellStriker memory) {
        return
            SpellStrikers.SpellStriker({
                id: id,
                name: bytes32("test"),
                resistance: resistance,
                power: power,
                level: 0
            });
    }
}