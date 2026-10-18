-- Explicitly classify an already reviewed database. No rows are modified.
DECLARE @environment nvarchar(20)='$(Environment)';
IF @environment NOT IN('dev','test','internal') THROW 50701,'Invalid environment',1;
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name='SanBongEnvironment' AND CONVERT(nvarchar(20),value)<>@environment)
 THROW 50702,'Database already has a different classification; review before retagging',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name='SanBongEnvironment')
 EXEC sys.sp_addextendedproperty @name=N'SanBongEnvironment',@value=@environment;
