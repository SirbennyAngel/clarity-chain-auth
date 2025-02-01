# ChainAuth

A blockchain-based identity verification system built on Stacks using Clarity.

## Features
- User identity registration
- Tiered identity verification system
- Authorization checks for verified identities
- Identity metadata management
- Verifier tier levels and authorization

## Verification Tiers
The system supports multiple verification tiers (0-3):
- Tier 0: Unverified
- Tier 1: Basic verification
- Tier 2: Enhanced verification
- Tier 3: Premium verification

## Usage
Users can register their identity by providing required information. Verifiers are assigned specific tier levels and can only verify identities up to their authorized tier. Applications can check both identity verification status and tier level before granting access.

### For Users
- Register identity with metadata
- Receive verification from authorized verifiers
- Track verification status and tier level

### For Verifiers
- Receive tier-based verification authority
- Verify user identities up to authorized tier level
- Cannot exceed their assigned verification tier

### For Applications
- Check identity verification status
- Verify user tier levels
- Implement tier-based access control
