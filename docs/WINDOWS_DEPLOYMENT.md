# docs/WINDOWS_DEPLOYMENT.md
# N.Y Kitchen — Windows Deployment

---

## Purpose
Document the steps to build and deploy the application for Windows Desktop.

---

## Target
- Windows 10 or later (64-bit)

## Build Steps (To Be Detailed in Phase 11)
1. Ensure Visual Studio Community is installed with C++ build tools.
2. Run flutter build windows --release.
3. Package installer using Inno Setup or MSIX.
4. Test on Windows desktop.

## Security Requirements
- Debug mode disabled.
- No test credentials in release build.
- Database file stored in user application documents directory.

---

## TODO
- [ ] Define installer packaging tool (Inno Setup vs MSIX)
- [ ] Test on Windows 10 and Windows 11 before Phase 11 sign-off
