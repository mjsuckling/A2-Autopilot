# A2 Autopilot OOBE Bootstrap

Registers a new Windows device with the HG Group / Attach2 Windows Autopilot tenant directly from Windows OOBE.

## Current configuration

- Tenant ID: `ed373f7d-2faf-41ff-a881-d3388923e455`
- Group Tag: none
- Deployment profile: existing common Autopilot profile
- Registration authentication: interactive Microsoft Entra sign-in
- Initial admin account: `mjs.admin@hggroupltd.com`

No passwords, app secrets, tokens, or other credentials are stored in this repository.

## OOBE test procedure

1. Power on a new Windows 11 PC.
2. Complete only enough OOBE to connect the PC to the internet.
3. At the OOBE screen press `Shift + F10` (or `Fn + Shift + F10` on devices where required).
4. In the Command Prompt window run:

```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm 'https://raw.githubusercontent.com/mjsuckling/A2-Autopilot/main/bootstrap.ps1' | iex"
```

5. When Microsoft authentication opens, sign in with `mjs.admin@hggroupltd.com`.
6. Approve any Microsoft Graph / Intune consent prompt if required.
7. Leave the device running. The script should:
   - retrieve the device serial number and hardware hash;
   - upload it to Windows Autopilot;
   - wait for the import to complete;
   - wait for the existing Autopilot profile to be assigned;
   - reboot automatically.
8. After reboot, continue OOBE. The device should now receive the normal Attach2/HG Group Autopilot experience.

## Expected behaviour

This uses Microsoft's `Get-WindowsAutopilotInfo` script in online mode with `-Assign -Reboot`.

A full wipe should normally not be necessary when registration is performed during OOBE. If the Autopilot profile is not picked up after restart, a reset may still be required as a fallback.

## Security

This repository is intentionally safe to expose publicly for bootstrap testing because it contains no credentials or secrets. Authentication still occurs interactively against Microsoft Entra / Intune.

Do not add:
- passwords;
- app secrets;
- access tokens;
- certificates/private keys;
- Graph bearer tokens.

## Troubleshooting

### Cannot open Shift+F10
Try `Fn + Shift + F10`.

### No internet
Return to OOBE, connect to Wi-Fi or Ethernet, then retry.

### PowerShell Gallery / NuGet failure
Confirm the device has unrestricted HTTPS access to PowerShell Gallery and Microsoft endpoints.

### Authentication succeeds in the wrong tenant
Cancel the run and authenticate with the HG Group admin account. The intended tenant ID is:

```text
ed373f7d-2faf-41ff-a881-d3388923e455
```

### Import completes but profile is not assigned
Check the existing Autopilot deployment profile assignment in Intune. The bootstrap intentionally applies no Group Tag, so the device must match the same assignment rules as your current manually imported devices.

## Future production hosting

Once the workflow is proven:

1. Keep this GitHub repository as the source of truth.
2. Deploy the bootstrap through Azure Static Web Apps or another simple HTTPS endpoint.
3. Add a short custom URL such as `https://a2.nz/ap`.
4. Technician command becomes approximately:

```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm 'https://a2.nz/ap' | iex"
```

For a later zero/semi-zero-touch version, replace interactive admin authentication with a controlled backend or other secure authentication flow. Never place an application secret in the public bootstrap.
