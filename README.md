# EquiCare Energy

EquiCare Energy is a Flutter-based energy monitoring and resilience prototype for shared residences and critical-service facilities.

## Current capabilities

- Battery, load and solar monitoring through a simulator or an ESP32-compatible HTTP status endpoint.
- Battery runtime estimates with configurable reserve and system efficiency.
- Solar forecast retrieval from Open-Meteo, with a locally persisted forecast cache for offline viewing.
- Shared Energy allocation demonstration with adjustable room weights and an illustrative fairness indicator.
- Critical Services autonomy scenario comparing current demand with a proposed flexible-load reduction.
- Alerts, history, model diagnostics and simulator controls.
- Local persistence for readings, forecast cache and model weights.

## Important data and safety limitations

- Simulator readings and room-use examples are illustrative, not measurements.
- A central meter cannot determine individual room consumption. Per-room attribution requires a separate meter or smart plug for each room.
- Solar generation values are estimates based on forecast irradiance and simplified panel assumptions.
- Autonomy estimates assume constant load, configured capacity, reserve and efficiency. Battery age, temperature, inverter limits and changing demand affect actual runtime.
- Flexible-load reductions are advisory scenarios only. The app must not automatically disconnect critical medical equipment.
- ESP32 mode currently reads a status endpoint. Do not connect switching hardware or rely on remote control until the hardware is independently commissioned and safety-reviewed.

## Configure

1. Install Flutter and Android SDK.
2. From the project root run:

   ```powershell
   flutter pub get
   flutter test
   flutter run
   ```

3. Complete onboarding.
4. Open Settings to configure battery capacity, protected reserve, and the forecast site's latitude/longitude.
5. Keep the data source set to Simulator unless a compatible ESP32 status endpoint is configured.

## Forecast

The app requests hourly shortwave radiation from Open-Meteo. The site coordinates are stored locally. A successful forecast is cached on-device and retained when a later refresh fails.

## Development status

This repository is an evolving prototype. It does not yet include the complete production backend, multi-user authentication, persistent server-side sites/rooms/residents, real meter provisioning, production-grade role permissions, or a validated external ML training pipeline. Do not represent those capabilities as complete.

## Android build

Build only after tests pass:

```powershell
flutter build apk --release
```

The generated APK is normally located at `build/app/outputs/flutter-apk/app-release.apk`.
