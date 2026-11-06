# Buduje seed ISO (etykieta cidata) dla każdej VM do C:\VMs\seed-<vm>.iso
$ErrorActionPreference = "Stop"
$outDir = "C:\VMs"

Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
public static class IsoWriter {
  public static void Write(string path, object comStream, int blockSize, int totalBlocks) {
    IStream src = (IStream)comStream;
    using (FileStream fs = new FileStream(path, FileMode.Create, FileAccess.Write)) {
      byte[] buf = new byte[blockSize];
      IntPtr pRead = Marshal.AllocHGlobal(sizeof(int));
      try {
        for (int i = 0; i < totalBlocks; i++) {
          src.Read(buf, blockSize, pRead);
          int n = Marshal.ReadInt32(pRead);
          fs.Write(buf, 0, n);
        }
      } finally { Marshal.FreeHGlobal(pRead); }
    }
  }
}
"@

foreach ($vm in "mon-01", "web-01", "web-02") {
  $src = Join-Path $PSScriptRoot $vm
  $iso = Join-Path $outDir "seed-$vm.iso"
  $fsi = New-Object -ComObject IMAPI2FS.MsftFileSystemImage
  $fsi.VolumeName = "cidata"
  $fsi.FileSystemsToCreate = 3   # ISO9660 + Joliet
  $fsi.Root.AddTree($src, $false)
  $res = $fsi.CreateResultImage()
  [IsoWriter]::Write($iso, $res.ImageStream, $res.BlockSize, $res.TotalBlocks)
  Write-Host "OK: $iso"
}
