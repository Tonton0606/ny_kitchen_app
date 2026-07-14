# docs/ERROR_HANDLING.md
# N.Y Kitchen — Error Handling

> Source of Truth: PROJECT_BLUEPRINT.md Section 17

---

## Purpose
Define how the application handles different types of errors gracefully.

---

## Principles
- Never crash on invalid input.
- Never expose technical error details to end users.
- Log errors appropriately for administrative review.
- Preserve user data on unexpected errors.
- Display user-friendly error messages.

## Error Types

### Validation Errors
- Trigger: Empty required fields, invalid prices, invalid quantities.
- Display: Inline field error message. Example: "Please enter a valid price."
- Log: Not required unless indicative of security concern.

### Authentication Errors
- Trigger: Wrong username, wrong password, locked account, expired session.
- Display: "Invalid username or password." (always — never reveal username existence)
- Log: Always log to login_attempts and Activity Logs.

### Database Errors
- Trigger: Failed save, failed update, failed backup, corrupted data.
- Display: "An error occurred. Please try again."
- Log: Technical details logged to Activity Logs or crash log.

### Printer Errors
- Trigger: Printer unavailable, paper out, disconnected.
- Display: Friendly printer error message with option to reprint later.
- Log: Log the print failure event.

### Backup Errors
- Trigger: Backup failed, restore failed, corrupted backup file.
- Display: "Backup operation failed. Your data is safe."
- Log: Log the backup error event.

### Unexpected Errors
- Trigger: Unhandled exceptions, null pointer errors, state corruption.
- Display: "An unexpected error occurred. Please restart the application."
- Log: Log diagnostic information.
- Action: Preserve user data. Do not crash silently.

---

## Rules
- Error messages must NEVER expose: stack traces, file paths, SQL errors, internal keys.
- Error handling must be consistent across all modules.
- All error boundaries must be tested.

---

## TODO
- [ ] Implement global error handler before Phase 2
- [ ] Define error codes for consistent message mapping
