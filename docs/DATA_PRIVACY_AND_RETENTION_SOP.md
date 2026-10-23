# Standard Operating Procedure: Data Privacy, Protection, and Retention Policy (SOP-SEC-01)

**Organization:** N.Y Kitchen Order & Sales Management System  
**Document Code:** SOP-SEC-01  
**Version:** 1.0  
**Effective Date:** October 23, 2026  
**Governing Standard:** Republic Act No. 10173 (Data Privacy Act of 2012), National Privacy Commission (NPC) Regulations, and ISO/IEC 25010  
**Applicability:** All System Administrators, Cashiers, and Operational Terminals  
**Rubric Reference:** R17 (Privacy, Governance, & Resilience), SEC-01 through SEC-10  

---

## 1. Objective and Policy Statement

The purpose of this Standard Operating Procedure (SOP) is to formalize data privacy, credential protection, and lifecycle retention policies for the N.Y Kitchen Point of Sale (POS) application. 

N.Y Kitchen is committed to upholding the privacy rights of all employees and customers in strict compliance with the **Philippine Data Privacy Act of 2012 (RA 10173)**, adhering to the core privacy principles of **Transparency, Legitimate Purpose, and Proportionality**.

---

## 2. Scope and Data Classifications

This SOP applies to all data processed, stored, or exported by the N.Y Kitchen application across local SQLite databases, offline backups, exported reports, and remote synchronization channels.

### Data Inventory & Sensitivity Matrix

| Data Category | Specific Data Elements | Classification | Processing Purpose |
|:---|:---|:---:|:---|
| **Employee Identity** | Full name, username, assigned role (Admin/Cashier), account status | **Confidential** | Role-based authorization, accountability, and session management |
| **Authentication Secrets** | Password hashes, cryptographic salts, PBKDF2 iteration metadata | **Restricted / Critical** | Identity verification; **never accessible in plaintext** |
| **Biometric Encodings** | Facial feature vectors / embeddings (if enrolled) | **Sensitive Personal Info (SPI)** | Optional multi-factor terminal authentication |
| **Sales & Transactions** | Receipt number, order items, quantities, subtotal, payment type, cashier ID, timestamp | **Internal Business Data** | Point-of-sale operations, accounting, and inventory tracking |
| **Financial Audit Data** | Refund reason, void reason, authorized refund actor, cashier shift totals | **Confidential** | Loss prevention, internal financial control, and tax compliance |
| **Security Audit Logs** | Timestamps, acting user, module, action, status, client device metadata | **Confidential / Forensic** | Non-repudiation, incident detection, and forensic audit trails |

---

## 3. Principles of Lawful Processing & Data Minimization

### 3.1 Principle of Proportionality & Data Minimization
1. **Zero Customer PII at Checkout:** The POS system does not collect or store unnecessary customer personal data (e.g., customer names, phone numbers, home addresses, or credit card numbers) during in-person counter checkout. Transactions are identified strictly by receipt serial numbers.
2. **Employee Data Minimization:** Only employee data strictly necessary for workforce scheduling, role authorization, and transaction attribution is stored.

### 3.2 Legitimate Purpose & Transparency
1. Employee accounts are created solely for legitimate operational oversight, cash drawer accountability, and system security.
2. Employees are informed upon hiring of the system's role-based audit trail (`activity_logs`), which records terminal logins, refunds, voids, and catalog changes to prevent fraud.

---

## 4. Cryptographic Security & Credential Protection

In accordance with Section 20 of RA 10173 (Security of Personal Information):

1. **Password Hashing Standard (Task B1):**
   - Plaintext passwords must never be stored on disk or transmitted over the wire.
   - All passwords are encrypted using **PBKDF2 with HMAC-SHA256**, utilizing a minimum work factor of **600,000 iterations** and a unique 16-byte cryptographically secure random salt generated via `Random.secure()`.
   - Hashes are formatted as `pbkdf2:sha256:600000$<salt>$<hash>`.
   - Legacy hashes are transparently upgraded to 600,000 iterations upon successful login.
2. **Biometric Data Protection (Task B2):**
   - Biometric encodings are encrypted with **AES-256-GCM** using keys stored in the platform's isolated secure hardware store (`flutter_secure_storage` / Windows DPAPI / Android Keystore).
   - Raw facial images are discarded after feature extraction; only mathematical feature vectors are retained.
3. **Export and Report Sanitization (ExportService):**
   - All PDF and Excel export routines strictly enforce an automated sanitization gate (`_sensitiveKeys`).
   - Fields containing `password_hash`, `face_encoding`, `password`, `secret`, `service_key`, or `token` are permanently purged from all exported spreadsheets and documents prior to rendering.

---

## 5. Official Data Retention Schedule

In accordance with Philippine Bureau of Internal Revenue (BIR) regulations and NPC data retention guidelines, data must not be kept longer than necessary for the fulfillment of its declared purpose:

| Record Type | Retention Period | Storage Location | Permitted Disposal Method |
|:---|:---:|:---:|:---|
| **Completed Sales Transactions** | **5 Years** | Local SQLite & Cloud Sync | Archival / End-of-life database purge |
| **Voided & Refunded Records** | **5 Years** | Local SQLite & Cloud Sync | Permanent status marker; never hard-deleted |
| **Security Activity Logs (`activity_logs`)** | **2 Years** | Local SQLite & Cloud Sync | Read-only; cannot be cleared through the UI |
| **Failed Login Attempts (`login_attempts`)** | **90 Days** | Local SQLite | Rolling purge by System Administrator |
| **Inactive Employee Accounts** | **Duration of Employment + 1 Year** | Local SQLite | Soft-delete only (`status = 'inactive'`) to preserve audit trail |
| **Offline Database Backups (`.sql` / `.db`)** | **30 Days (Daily) / 1 Year (Monthly)** | Secure Offline / Encrypted Drive | Secure file shredding / overwrite |

---

## 6. Data Destruction and Terminal Decommissioning

When a POS terminal (Windows Desktop or Android tablet) is decommissioned, repaired, or transferred:

1. **Cryptographic Erasure:** The local database file (`ny_kitchen.db`) must be securely deleted using file shredding tools that overwrite data blocks with zeroes/random bits rather than a standard OS recycle bin deletion.
2. **Secure Storage Cleansing:** Device hardware storage key stores (`FlutterSecureStorage.deleteAll()`) must be wiped to invalidate all stored tokens and biometric decryption keys.
3. **Physical Media Disposal:** Defective hard drives containing POS data must undergo physical degaussing or destruction before disposal.

---

## 7. Data Subject Rights & Incident Management

### 7.1 Employee Rights Under RA 10173
Employees possess the following rights regarding their processed data:
- **Right to be Informed:** Employees are provided notice that their system actions and logins are logged for business accountability.
- **Right to Access & Rectification:** Employees may request verification of their profile data (full name, username) and request correction through the System Administrator.
- **Right to Non-Discrimination:** Exercising privacy rights does not jeopardize employment status.

### 7.2 Security Incident & Breach Notification Protocol
In the event of physical theft of a POS terminal or unauthorized access to the database:
1. **Immediate Lockdown:** The System Administrator immediately revokes remote sync credentials and invalidates active session tokens.
2. **Investigation & Assessment:** Within 24 hours, the extent of compromised data is evaluated (confirming that password hashes remain uncrackable due to PBKDF2-600k salting).
3. **Regulatory Escalation:** If sensitive employee biometric or credential data is confirmed exfiltrated, notification to the **National Privacy Commission (NPC)** and affected individuals shall be executed within **72 hours** in accordance with NPC Circular 16-03.

---

## 8. Compliance & Document Control

- **Prepared By:** MJ Daz (Lead Security & Operations Collaborator)
- **Approved By:** Capstone Project Committee / System Management
- **Audit Cadence:** Semi-Annual Review or upon any architectural modification to storage layers.
