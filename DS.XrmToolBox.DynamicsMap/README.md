# DS.XrmToolBox.DynamicsMap

A minimal XrmToolBox plugin scaffold targeting .NET Framework 4.8 with a
basic WhoAmI test.

## Prereqs
- .NET Framework 4.8 Developer Pack
- Windows (XrmToolBox runs on Windows)
- XrmToolBox installed (portable ZIP is fine)

## Build
```powershell
# From this folder
dotnet restore; dotnet build -c Debug
```
Outputs to `bin/Debug/net48/`.

## Load in XrmToolBox
1. Start XrmToolBox.
2. Settings (gear) > Paths > Plugins search paths > Add.
3. Select this project output folder:
   `<repo>/DS.XrmToolBox.DynamicsMap/bin/Debug/net48`.
4. Restart XrmToolBox.
5. Use the search box to find "Dynamics Map" and open it.

## What’s included
- Package references:
  - `XrmToolBoxPackage` (brings XrmToolBox.Extensibility and dependencies)
  - `Microsoft.CrmSdk.CoreAssemblies`
  - `Microsoft.CrmSdk.XrmTooling.CoreAssembly`
- A plugin control with MEF metadata and a WhoAmI button.

## Next steps
- Rename metadata (Name/Description/colors) in `Plugin/DynamicsMapPlugin.cs`.
- Add images via ExportMetadata keys `SmallImageBase64`/`BigImageBase64` if
  desired.
- Implement your tool logic.
