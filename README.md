# Portable NodeJS

## Windows

### Installation using PowerShell

- Install or update latest lts version on `$Home\.nodejs`:

```powershell
irm https://raw.githubusercontent.com/yotlich/win-nodejs/main/scripts/install.ps1 | iex
```

- Or specify all parameters, default values:
  - `-BinDir $Home\.nodejs` — destination path to install
  - `-Version lts` — version (`latest`, `krypton`, `24`, `24.14.0`) to install
  - `-Update` — overwrite the destination folder if it already exists
  - `-NoAddToPath` — add destination path to UserPath

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/yotlich/win-nodejs/main/scripts/install.ps1') } -BinDir .\node -Version latest -Update -NoAddToPath"
```

### Uninstall using PowerShell

- Delete NodeJS and clean all configuration files:

```powershell
irm https://raw.githubusercontent.com/yotlich/win-nodejs/main/scripts/uninstall.ps1 | iex
```

- Or specify all parameters, default values:
  - `-BinDir $(Get-Command node | Split-Path -Parent)` — installation path

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/yotlich/win-nodejs/main/scripts/uninstall.ps1') } -BinDir .\node"
```
