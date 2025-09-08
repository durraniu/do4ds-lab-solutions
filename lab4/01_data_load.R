# Create a duckdb database and save penguins df as a table in it (alternative to 01_data_load.py)
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = "my-db.duckdb")
DBI::dbWriteTable(con, "penguins", palmerpenguins::penguins)
DBI::dbDisconnect(con)
