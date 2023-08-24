// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./SpellStrikers.sol";
import "./Errors.sol";
import "./CastSpellVerifier.sol";
import "./SelectSpellVerifier.sol";

contract SpellStrikerDuels {
    enum Spells {
        NO_SPELL,
        ATTACK_FRENZY,
        PROTECTIVE_AURA,
        WARRIOR_MIGHT
    }

    struct SpellEffects {
        uint256 power;
        uint256 resistance;
    }

    enum DuelStatus {
        NOT_CREATED,
        PENDING,
        WAITING_HOST_PROOF,
        RESOLVED
    }

    struct Duel {
        address host;
        uint256 id;
        uint256 hostSpellStrikerId;
        uint256 guestSpellStrikerId;
        Spells hostSpell;
        Spells guestSpell;
        uint256 hostSpellHash;
        DuelStatus status;
        uint256 winner;
    }

    struct Record {
        uint16 wins;
        uint16 losses;
        uint16 draws;
        uint16 mana;
        uint256 lastManaRefresh;
    }

    uint8 constant DUEL_MANA_COST = 1;
    uint8 constant INITIAL_MANA = 5;
    uint256 constant MANA_REGEN_INTERVAL = 1 days;

    SpellStrikers spellStrikers;
    mapping(uint256 => Duel) duelsById;
    mapping(uint256 => Record) recordsBySpellStrikerId;
    mapping(Spells => SpellEffects) effectsBySpell;

    /* ZK VERIFIERS */
    SelectSpellVerifier selectSpellVerifier;
    CastSpellVerifier castSpellVerifier;

    modifier ensureOwnerOf(uint256 spellStrikerId) {
        if (spellStrikers.ownerOf(spellStrikerId) != msg.sender) {
            revert Unauthorized();
        }
        _;
    }

    modifier ensureSpellStrikerExists(uint256 spellStrikerId) {
        if (spellStrikers.ownerOf(spellStrikerId) == address(0)) {
            revert SpellStrikerNotFound();
        }
        _;
    }

    modifier ensureValidDuelId(uint256 id) {
        if (duelsById[id].status == DuelStatus.NOT_CREATED) {
            revert DuelNotFound();
        }
        _;
    }

    modifier ensureActiveDuel(uint256 id) {
        if (duelsById[id].status != DuelStatus.PENDING) {
            revert DuelNotActive();
        }
        _;
    }

    modifier updateAndEnsureManaCost(uint256 spellStrikerId) {
        if (DUEL_MANA_COST > this.getSpellStrikerRecord(spellStrikerId).mana) {
            revert NotEnoughMana();
        }
        _;
    }

    modifier ensureIsDuelHost(uint256 id) {
        if (duelsById[id].host != msg.sender) {
            revert Unauthorized();
        }
        _;
    }

    constructor(
        SpellStrikers _spellStrikers,
        SelectSpellVerifier _selectSpellVerifier,
        CastSpellVerifier _castSpellVerifier
    ) {
        selectSpellVerifier = _selectSpellVerifier;
        castSpellVerifier = _castSpellVerifier;

        // how could we check if this is really a SpellStrikers contract?
        spellStrikers = _spellStrikers;

        effectsBySpell[Spells.ATTACK_FRENZY].power = 4;
        effectsBySpell[Spells.ATTACK_FRENZY].resistance = 0;

        effectsBySpell[Spells.PROTECTIVE_AURA].power = 0;
        effectsBySpell[Spells.PROTECTIVE_AURA].resistance = 4;

        effectsBySpell[Spells.WARRIOR_MIGHT].power = 2;
        effectsBySpell[Spells.WARRIOR_MIGHT].resistance = 2;
    }

    /**
     * @notice  creates a duel with a spellstriker and a spell proof
     * @param   spellStrikerId  the id of the chosen spell striker
     * @param   a proof point a
     * @param   b  proof point b
     * @param   c  proof point c
     * @param   input  spell hash
     * @return  uint256  duel id
     */
    function create(
        uint256 spellStrikerId,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) external ensureOwnerOf(spellStrikerId) returns (uint256) {
        if (!selectSpellVerifier.verifyProof(a, b, c, input)) {
            revert InvalidProof();
        }
        return _create(spellStrikerId, input[0]);
    }

    /**
     * @notice  creates a duel with a spellstriker and a spell. throws if msg.sender is not owner of the spellstriker
     * @param   spellStrikerId  the id of the chosen spell striker
     * @param   spellHash hash of the chosen spell
     * @return  uint256  duel id
     */
    function _create(uint256 spellStrikerId, uint256 spellHash)
        internal
        updateAndEnsureManaCost(spellStrikerId)
        returns (uint256)
    {
        uint256 id = uint256(
            keccak256(
                abi.encodePacked(spellStrikerId, block.timestamp, spellHash)
            )
        );

        duelsById[id] = Duel({
            host: msg.sender,
            id: id,
            hostSpellStrikerId: spellStrikerId,
            guestSpellStrikerId: 0,
            hostSpellHash: spellHash,
            hostSpell: Spells(0),
            guestSpell: Spells(0),
            status: DuelStatus.PENDING,
            winner: 0
        });

        return id;
    }

    /**
     * @notice  joins duel with a spellstriker and a spell proof. throws if msg.sender is not owner of the spellstriker
     * @param   duelId  the id of the duel to join
     * @param   spellStrikerId  the id of the chosen spell striker
     * @param   a  .
     * @param   b  .
     * @param   c  .
     * @param   input  .
     * @return  uint256  duel id
     */
    function join(
        uint256 duelId,
        uint256 spellStrikerId,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory input
    )
        external
        ensureValidDuelId(duelId)
        ensureActiveDuel(duelId)
        ensureOwnerOf(spellStrikerId)
        returns (uint256)
    {
        if (!castSpellVerifier.verifyProof(a, b, c, input)) {
            revert InvalidProof();
        }

        _join(duelId, spellStrikerId, Spells(input[1]));
        return duelId;
    }

    /**
     * @notice  joins duel with a spellstriker and a spell. starts the duel. throws if msg.sender is not owner of the spellstriker
     * @param   duelId  the id of the duel to join
     * @param   spellStrikerId  the id of the chosen spell striker
     * @param   spell  the chosen spell
     * @return  uint256  duel id
     */
    function _join(
        uint256 duelId,
        uint256 spellStrikerId,
        Spells spell
    )
        internal
        updateAndEnsureManaCost(spellStrikerId)
        updateAndEnsureManaCost(duelsById[duelId].hostSpellStrikerId)
        returns (uint256)
    {
        duelsById[duelId].guestSpellStrikerId = spellStrikerId;
        duelsById[duelId].guestSpell = spell;
        duelsById[duelId].status = DuelStatus.WAITING_HOST_PROOF;

        return duelId;
    }

    /**
     * @notice  starts a duel that is in WAITING_HOST_PROOF state
     * @param   duelId  .
     * @param   a  .
     * @param   b  .
     * @param   c  .
     * @param   input  .
     */
    function start(
        uint256 duelId,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory input
    ) external ensureValidDuelId(duelId) ensureIsDuelHost(duelId) {
        if (duelsById[duelId].status != DuelStatus.WAITING_HOST_PROOF) {
            revert InvalidDuelState();
        }

        if (!castSpellVerifier.verifyProof(a, b, c, input)) {
            revert InvalidProof();
        }

        uint256 spellHash = input[0];

        if (spellHash != duelsById[duelId].hostSpellHash) {
            revert InvalidProof();
        }

        duelsById[duelId].hostSpell = Spells(input[1]);
        _applyDuelLogic(duelsById[duelId]);
    }

    /**
     * @notice  gets duel details by its id
     * @param   id  the duel id
     * @return  Duel duel details
     */
    function get(uint256 id)
        external
        view
        ensureValidDuelId(id)
        returns (Duel memory)
    {
        return duelsById[id];
    }

    /**
     * @notice  gets a spell striker record which includes its wins, losses and draws. calculates potential mana gains
     * @param   spellStrikerId  the id of the spell striker
     * @return  Record spell striker records
     */
    function getSpellStrikerRecord(uint256 spellStrikerId)
        public
        ensureSpellStrikerExists(spellStrikerId)
        returns (Record memory)
    {
        _updateSpellStrikerMana(spellStrikerId);
        return _getSpellStrikerRecord(spellStrikerId);
    }

    /**
     * @notice  applies complex mathematics to calculate who's the winner or if it's a draw. updates spell striker records accordingly. marks duel as resolved
     * @param   duel  the duel to resolve
     */
    function _applyDuelLogic(Duel storage duel) internal {
        SpellStrikers.SpellStriker memory host = spellStrikers.get(
            duel.hostSpellStrikerId
        );
        SpellStrikers.SpellStriker memory guest = spellStrikers.get(
            duel.guestSpellStrikerId
        );

        // apply spell effects
        SpellEffects memory hostEffects = effectsBySpell[duel.hostSpell];
        SpellEffects memory guestEffects = effectsBySpell[duel.guestSpell];
        uint256 hostPower = host.power + hostEffects.power;
        uint256 hostResistance = host.resistance + hostEffects.resistance;
        uint256 guestPower = guest.power + guestEffects.power;
        uint256 guestResistance = guest.resistance + guestEffects.resistance;

        // reduce mana
        _getSpellStrikerRecord(host.id).mana -= DUEL_MANA_COST;
        _getSpellStrikerRecord(guest.id).mana -= DUEL_MANA_COST;

        // calculate who's alive
        bool hostAlive = guestPower < hostResistance;
        bool guestAlive = hostPower < guestResistance;

        // if both alive or both dead, draw
        if ((hostAlive && guestAlive) || (!hostAlive && !guestAlive)) {
            // update duel results
            _getSpellStrikerRecord(host.id).draws++;
            _getSpellStrikerRecord(guest.id).draws++;
            duel.status = DuelStatus.RESOLVED;
            return;
        }

        // find out who's winner
        SpellStrikers.SpellStriker memory winner;
        SpellStrikers.SpellStriker memory loser;
        winner = hostAlive ? host : guest;
        loser = hostAlive ? guest : host;

        // update duel results
        _getSpellStrikerRecord(winner.id).wins++;
        _getSpellStrikerRecord(loser.id).losses++;

        duel.winner = winner.id;
        duel.status = DuelStatus.RESOLVED;
    }

    function _updateSpellStrikerMana(uint256 spellStrikerId)
        internal
        returns (uint16)
    {
        Record storage spellStriker = _getSpellStrikerRecord(spellStrikerId);

        // is first time dueling. set initial mana value
        if (spellStriker.lastManaRefresh == 0) {
            // TODO: calculate mana using token creation time
            spellStriker.mana = INITIAL_MANA;
            spellStriker.lastManaRefresh = block.timestamp;
            return spellStriker.mana;
        }

        uint256 timeSinceLastRefresh = block.timestamp -
            spellStriker.lastManaRefresh;

        // no regen available yet. not enough time has passed
        if (timeSinceLastRefresh < MANA_REGEN_INTERVAL) {
            return spellStriker.mana;
        }

        // calculate how many times regen has passed
        uint256 refreshes = timeSinceLastRefresh / MANA_REGEN_INTERVAL;
        spellStriker.mana += uint16(refreshes);
        spellStriker.lastManaRefresh = block.timestamp;

        return spellStriker.mana;
    }

    /**
     * @notice  gets a spell striker record **from storage** which includes its wins, losses and draws.
     * @param   spellStrikerId  the id of the spell striker
     * @return  Record spell striker records
     */
    function _getSpellStrikerRecord(uint256 spellStrikerId)
        internal
        view
        returns (Record storage)
    {
        return recordsBySpellStrikerId[spellStrikerId];
    }
}