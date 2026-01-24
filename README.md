# Assignment1.sql

1) Restore JOB_PORTAL_DB.bak Database
   1) Launch SQL Server Management Studio (SSMS) and connect to your instance.
   2) Right-click on the Databases folder in the Object Explorer (left sidebar).
   3) Select Restore Database.
   4) In the "Source" section, select Device.
   5) Click the ellipsis button (...) on the right.
   6) In the "Select backup devices" window, click Add.
   7) Navigate to and select your JOB_PORTAL_DB.bak file, then click OK until you return to the main Restore window.
   8) SSMS should automatically fill the "Destination Database" field with JOB_PORTAL_DB. You can change this if you want a different name.
2) Run Assignment1.sql queries one by one to test it.

# Assignment2.sql

The file Assignment2.sql is self-contained and does not require a .bak file.

Note: You will need to manually insert rows (DML) to test the logic of the queries, as the script initializes an empty structure.
