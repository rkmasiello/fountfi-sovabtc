# Session 15: Fix Failing Tests & Prepare for Production

## Context
The FountFi Multi-Collateral BTC Vault is deployed to Base Sepolia testnet and all major development is complete. We've updated the vault shares token name from 'mcBTC' to 'stSOVABTC' (staked sovaBTC) across the entire codebase.

## Current Status
- ✅ All compilation errors fixed
- ✅ Token naming updated from mcBTC to stSOVABTC 
- ⚠️ 2 failing tests identified that need fixing
- 509 tests passing successfully

## Failing Tests
```
1. script/test/LoadTest.s.sol:LoadTest
   [FAIL: EvmError: Revert] testUsers(uint256) 
   Counterexample: args=[571186]

2. script/test/TestMultiUser.s.sol:TestMultiUser  
   [FAIL: EvmError: Revert] testUsers(uint256)
   Counterexample: args=[571186]
```

Both tests are failing with the same counterexample value (571186), suggesting they may have the same root cause.

## Tasks for This Session

### 1. Fix Failing Tests (Priority)
- Investigate why `testUsers(uint256)` is reverting with value 571186
- These appear to be fuzz tests - check if there's an overflow or boundary condition
- Consider if we should:
  - Fix the underlying issue
  - Add bounds checking to the test
  - Skip these tests if they're testing unrealistic scenarios

### 2. Run Forge Coverage
Once tests are passing:
```bash
forge coverage
```
- Ensure we have adequate test coverage
- Identify any critical paths that lack testing

### 3. Final Cleanup
- Remove any redundant or outdated test files
- Ensure all test names are descriptive
- Clean up any commented-out code in tests

### 4. Optional: Add Missing Interface Functions
The PostDeploymentChecks.s.sol script has many commented-out checks because interface functions are missing:
- Consider adding missing getters to interfaces if needed
- Or document why certain functions are internal-only

## Important Notes
- DO NOT add excessive tests - we want forge coverage to run successfully
- Focus on fixing existing tests rather than adding new ones
- If a test is testing an unrealistic scenario (like 571,186 users), consider adding reasonable bounds

## Success Criteria
- All tests passing (or explicitly skipped with good reason)
- `forge coverage` runs successfully
- Test suite is clean and maintainable

## Files to Focus On
- script/test/LoadTest.s.sol
- script/test/TestMultiUser.s.sol
- Any test files with excessive or redundant tests

## Commands to Run
```bash
# Run specific failing test with verbosity
forge test --match-test testUsers -vvv

# After fixes, run full test suite
forge test

# Finally run coverage
forge coverage
```