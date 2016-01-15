SELECT l.name, l.denylogin, l.isntname, l.isntgroup, l.isntuser
  FROM master.dbo.syslogins l
WHERE l.sysadmin = 1 OR l.securityadmin = 1



