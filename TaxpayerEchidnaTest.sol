pragma solidity ^0.8.22;

import "Taxpayer.sol";

/// @notice Echidna harness for Part 1.
/// We deploy a small fixed population of Taxpayer instances and expose
/// wrapper functions that Echidna calls with fuzzed indices/arguments.
/// Echidna re-checks every echidna_* boolean function after each
/// transaction in the sequence; a violation is reported with the
/// shortest call sequence that triggers it.
contract TaxpayerEchidnaTest {

    uint constant N = 3; // small population: enough combinations, small state space
    Taxpayer[N] taxpayers;

    constructor() {
        for (uint i = 0; i < N; i++) {
            taxpayers[i] = new Taxpayer(address(0), address(0));
        }
    }

    // ---------------------------------------------------------------
    // Wrapper functions: Echidna fuzzes the arguments (including out
    // of range indices, which we fold into range with modulo so every
    // call is always valid and "interesting" rather than reverting on
    // an out-of-bounds array access).
    // ---------------------------------------------------------------

    function marry(uint i, uint j) public {
        Taxpayer(taxpayers[i % N]).marry(address(taxpayers[j % N]));
    }

    function divorce(uint i) public {
        taxpayers[i % N].divorce();
    }

    function haveBirthday(uint i) public {
        taxpayers[i % N].haveBirthday();
    }

    function transferAllowance(uint i, uint change) public {
        taxpayers[i % N].transferAllowance(change);
    }

    // ---------------------------------------------------------------
    // Invariants (Part 1)
    // ---------------------------------------------------------------

    /// Core required property: if x is married to y, y must be married
    /// to x. Checked after every single transaction Echidna executes.
    function echidna_marriage_is_symmetric() public view returns (bool) {
        for (uint i = 0; i < N; i++) {
            address spouseAddr = taxpayers[i].getSpouse();
            if (spouseAddr == address(0)) continue; // not married: nothing to check

            bool foundInPopulation = false;
            for (uint j = 0; j < N; j++) {
                if (address(taxpayers[j]) == spouseAddr) {
                    foundInPopulation = true;
                    if (taxpayers[j].getSpouse() != address(taxpayers[i])) return false;
                    if (!taxpayers[j].getIsMarried()) return false;
                }
            }
            // In this harness every spouse address must belong to our
            // own population (we never marry outside taxpayers[]).
            if (!foundInPopulation) return false;
        }
        return true;
    }

    /// Sensible extra property: the isMarried flag must always agree
    /// with spouse != address(0). Guards against a fix that updates
    /// one field but forgets the other.
    function echidna_married_flag_consistent_with_spouse() public view returns (bool) {
        for (uint i = 0; i < N; i++) {
            bool married = taxpayers[i].getIsMarried();
            address spouseAddr = taxpayers[i].getSpouse();
            if (married && spouseAddr == address(0)) return false;
            if (!married && spouseAddr != address(0)) return false;
        }
        return true;
    }

    /// Sensible extra property: nobody can be married to themselves.
    function echidna_no_self_marriage() public view returns (bool) {
        for (uint i = 0; i < N; i++) {
            if (taxpayers[i].getSpouse() == address(taxpayers[i])) return false;
        }
        return true;
    }
}
