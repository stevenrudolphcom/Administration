# Script to retrieve the Windows Product Key

function Get-WindowsProductKey {
    try {
        $backupKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
        $backupKey = $null

        if (Test-Path -Path $backupKeyPath) {
            $backupKey = (Get-ItemProperty -Path $backupKeyPath -Name "BackupProductKeyDefault" -ErrorAction SilentlyContinue).BackupProductKeyDefault
        }

        function Show-BoxedMessage {
            param (
                [string]$Text,
                [ConsoleColor]$ForegroundColor = 'Green',
                [ConsoleColor]$BorderColor = 'Yellow'
            )

            $lines = $Text -split "`n"
            $width = ($lines | Measure-Object -Property Length -Maximum).Maximum
            $border = '+' + ('-' * ($width + 2)) + '+'
            Write-Host $border -ForegroundColor $BorderColor
            foreach ($line in $lines) {
                $padded = $line.PadRight($width)
                Write-Host "| $padded |" -ForegroundColor $ForegroundColor
            }
            Write-Host $border -ForegroundColor $BorderColor
        }

        if ($backupKey) {
            Show-BoxedMessage -Text "Windows Product Key (from BackupProductKeyDefault): $backupKey" -ForegroundColor Cyan -BorderColor Magenta
            return
        }

        # Fallback: decode DigitalProductId from CurrentVersion (legacy method)
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        $digitalProductId = (Get-ItemProperty -Path $regPath -Name "DigitalProductId").DigitalProductId

        $productKey = ""
        $isWin8OrLater = [int]($digitalProductId[66] / 6) -band 1
        $digitalProductId[66] = ($digitalProductId[66] -band 0xF7) -bor (($isWin8OrLater -band 2) * 4)

        $chars = "BCDFGHJKMPQRTVWXY2346789"
        
        for ($i = 24; $i -ge 0; $i--) {
            $r = 0
            for ($j = 14; $j -ge 0; $j--) {
                $r = ($r * 256) -bxor $digitalProductId[$j]
                $digitalProductId[$j] = [math]::Floor($r / 24)
                $r = $r % 24
            }
            $productKey = $chars[$r] + $productKey
            if (($i % 5) -eq 0 -and $i -ne 0) {
                $productKey = "-" + $productKey
            }
        }
        
        Show-BoxedMessage -Text "Windows Product Key: $productKey" -ForegroundColor Green -BorderColor Blue
    } catch {
        Show-BoxedMessage -Text "Failed to retrieve product key: $_" -ForegroundColor Red -BorderColor DarkRed
    }
}

# Call the function
Get-WindowsProductKey