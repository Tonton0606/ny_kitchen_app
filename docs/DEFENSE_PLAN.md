# Defense plan — October 22, 2026

Target date is inferred from the owner's Thursday defense statement. Updated October 20.

Use the ten-minute sequence in [SECURITY_IMPLEMENTATION_PLAN.md](SECURITY_IMPLEMENTATION_PLAN.md): architecture and assets, framework-linked risk, authorized sale and denied action, lockout/audit, offline sale, reproduced vulnerability before/after, validated recovery, then rubric coverage and remaining risks.

Demonstrate Windows first. Include Android, cloud or face recognition only with evidence for that actual setup. A Linux VM or Docker installation is not required. ZAP is an optional supporting API report.

Prepare a synthetic demo database, separate test accounts, a known build, a validated backup and labeled recordings from the same build. Present the 20 rubric criteria with evidence references and actual results. Leave scores unassigned until reviewed. Do not claim that a clean scanner report means the entire application is secure.

Expected questions: Why SQLite? How are direct repository calls protected? What can an OS administrator still change? How are credentials and backups protected? What happens when internet/cloud fails? How was recovery measured? Which framework controls were actually verified?
