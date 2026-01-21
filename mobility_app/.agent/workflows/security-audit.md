---
description: Comprehensive security check for codebase vulnerabilities
---

# Security Audit Workflow

Goal: Audit codebase for security vulnerabilities

## Phase 1: Secrets Detection
// turbo
1. Scan codebase for hardcoded secrets:
   ```bash
   grep -rE "(api_key|password|secret|token|private_key)" --include="*.dart" lib/
   ```
2. Verify `.gitignore` includes sensitive files (.env, *.keystore, *.jks)
3. Check all secrets use environment variables

## Phase 2: Dependency Audit
// turbo
1. Check for outdated packages:
   ```bash
   flutter pub outdated
   ```
2. Review CHANGELOG for security advisories
3. Update vulnerable dependencies

## Phase 3: Code Analysis
1. Check for SQL injection risks (raw queries without parameterization)
2. Verify input validation on all user inputs
3. Check for insecure storage (SharedPreferences for sensitive data)
4. Verify encryption for sensitive local data
5. Check auth.uid() present in all RLS policies

## Phase 4: RLS Verification
1. List all Supabase tables
2. Verify RLS enabled on each table
3. Test unauthorized access scenarios:
   - Unauthenticated user accessing protected resources
   - User A accessing User B's data
4. Document any tables without RLS (must be intentional)

## Phase 5: Network Security
1. Verify all API calls use HTTPS
2. Check certificate pinning (if applicable)
3. Verify JWT handling (no logging, secure storage)
4. Test API authentication requirements

## Phase 6: Report Generation
Generate `security-audit-{date}.md` with:
- **Critical**: Immediate action required
- **High**: Fix before next release
- **Medium**: Plan for remediation
- **Low**: Best practice recommendations

## Artifacts
- [ ] Secrets scan results
- [ ] Dependency audit report
- [ ] RLS verification matrix
- [ ] Security audit summary
