# nextgen-db-strip

## Summary
This will delete all but 10 patients from the system for each practice. It will remove anything that is not directly related to the patients. Run nextgen-db-strip.sql against the database to be stripped. Adjust the parameters to suit your needs @ Line 80, 82, and 84.

```sql
--CONFIGURE INDEX UPDATE (Y = update indexes afterwards, N = skip the index refresh)
DECLARE @index_update CHAR(1) = 'Y'
--CONFIGURE THE ANONYMIZE&STRIP (Y = do both, N = only anonymize)
DECLARE @anon_and_strip CHAR(1) = 'Y'
--CONFIGURE VERBOSE LOGGING
DECLARE @verbose INT = 1
/****************************************************************
How much needs to show up in the message output?
	0 = nothing
	1 = minimal headings
	2 = heading + step details
	3 = dynamic SQL generated for execution
****************************************************************/
```

## Supported NextGen versions
| Version | Status |
|:-------:|:------|
| 5.6.x | ![Passing](https://raw.githubusercontent.com/travis-ci/travis-api/master/public/images/result/passing.png) |
| 5.7.x | ![Unknown](https://raw.githubusercontent.com/travis-ci/travis-api/master/public/images/result/unknown.png) |
| 5.8.0 | ![Passing](https://raw.githubusercontent.com/travis-ci/travis-api/master/public/images/result/passing.png) |
| 5.8.1 | ![Passing](https://raw.githubusercontent.com/travis-ci/travis-api/master/public/images/result/passing.png) |
| 5.8.2 | ![Unknown](https://raw.githubusercontent.com/travis-ci/travis-api/master/public/images/result/unknown.png) |
| 5.8.3 | ![Passing](https://raw.githubusercontent.com/travis-ci/travis-api/master/public/images/result/passing.png) |
| 5.9.0 | ![Passing](https://raw.githubusercontent.com/travis-ci/travis-api/master/public/images/result/passing.png) |
| 5.9.1 | ![Unknown](https://raw.githubusercontent.com/travis-ci/travis-api/master/public/images/result/unknown.png) |