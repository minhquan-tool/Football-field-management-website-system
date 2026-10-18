param([Parameter(Mandatory=$true)][ValidatePattern('^QuanLySanBong_Fixtures_[A-Za-z0-9_]+$')][string]$Database)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Data.SqlClient
$qaCs="Data Source=tcp:localhost,1433;Initial Catalog=$Database;Integrated Security=True;Encrypt=True;TrustServerCertificate=True"
$qaA=[System.Data.SqlClient.SqlConnection]::new($qaCs);$qaB=[System.Data.SqlClient.SqlConnection]::new($qaCs)
try{
 $qaA.Open();$qaB.Open()
 $qaCheck=$qaA.CreateCommand();$qaCheck.CommandText="IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name='SanBongFixtureDatabase' AND TRY_CONVERT(int,value)=1) THROW 51080,'Disposable fixture required',1; SELECT TOP(1) MaSan FROM San WHERE MoTa=N'Isolated synthetic transaction demonstration' ORDER BY MaSan"
 $qaPitch=$qaCheck.ExecuteScalar();if(-not $qaPitch){throw 'Run rubric-transactions.sql first'}
 $qaTx=$qaA.BeginTransaction()
 $qaLock=$qaA.CreateCommand();$qaLock.Transaction=$qaTx;$qaLock.CommandText='SELECT MaSan FROM San WITH(UPDLOCK,HOLDLOCK) WHERE MaSan=@pitch';$null=$qaLock.Parameters.AddWithValue('@pitch',$qaPitch);$null=$qaLock.ExecuteScalar()
 $qaWait=$qaB.CreateCommand();$qaWait.CommandText='SET LOCK_TIMEOUT 1000; BEGIN TRY BEGIN TRANSACTION; SELECT MaSan FROM San WITH(UPDLOCK,HOLDLOCK) WHERE MaSan=@pitch; COMMIT; END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK; THROW; END CATCH;';$null=$qaWait.Parameters.AddWithValue('@pitch',$qaPitch)
 $qaBlocked=$false
 # Consume the entire batch: ExecuteScalar can return before a later CATCH/THROW result.
 try{$null=$qaWait.ExecuteNonQuery()}catch [System.Data.SqlClient.SqlException]{if($_.Exception.Number -ne 1222){throw};$qaBlocked=$true}
 if(-not $qaBlocked){throw 'Second session unexpectedly acquired the held lock'}
 $qaTx.Rollback();$qaTx=$null
 if($qaWait.ExecuteScalar() -ne $qaPitch){throw 'Second session did not recover after first rollback'}
 [pscustomobject]@{database=$Database;sessionBBlockedError=1222;sessionBAfterRollback='PASS';dataWrites=0;lockOrder='San before DatSan';checkedAt=[DateTimeOffset]::Now.ToString('o')} | ConvertTo-Json
}finally{if($qaTx){$qaTx.Rollback()};$qaA.Dispose();$qaB.Dispose()}
