#Thomas Devine, 3/11/2021;
#Description: this is a generic script for querying SQL from R
#see for more info on querying SQL from R: 
#       Best overview (RMySQL): https://www.slideshare.net/RsquaredIn/rmysql-tutorial-for-beginners
#       More focused on dbplyr/dplyr: https://dbplyr.tidyverse.org/reference/tbl.src_dbi.html, https://jagg19.github.io/2019/05/mysql-r/, https://www.r-bloggers.com/2011/05/accessing-mysql-through-r/
#       MySQL: https://beanumber.github.io/sds192/lab-sql.html
#       SQLLite: https://rdrr.io/cran/dbplyr/f/vignettes/new-backend.Rmd; this is 100% NOT comprehensive AT ALL
#       cran: https://cran.r-project.org/web/packages/dbplyr/index.html, https://cran.r-project.org/web/packages/RMySQL/index.html, https://cran.r-project.org/web/packages/tidyverse/index.html, https://cran.r-project.org/web/packages/lubridate/index.html
#~~~~~~~~~~~~~~~~~~~~~ BEGIN~~~~~~~~~~~~~~~~~~~~~ 
#Packages: (essentially all we'll likely need)
    # install.packages(c("tidyverse","RMySQL","lubridate","dbplyr") )
        library(tidyverse);library(lubridate)
        library(dbplyr); library(RMySQL) 

#More infrequent commands: (excluding dbFetch/dbSendQuery since it's best4 batching)
    #1.dbGetQuery: to extract rows from query: dbGetQuery(con,"select * from tab limit 5")
    #2.dbSendQuery: to send a command to sql, esp create a db: dbSendQuery(conn, "CREATE DATABASE Congress_v_Trump;")  
        #dbClearResult(); must clear the above
    #3.dbFetch; gets the n rows in a query, n=-1 rets all records; takes dbSendQuery object; always returns a data.frame obj
        #dbFetch(dbSendQuery(con, "SELECT * FROM mtcars WHERE cyl = 4"))
    #4.dbWriteTable: creates new/overwrite old/appends data to a tab
    #5.dbListTables(con); List tables in the db (eg tab, dept, emplys, clients)
    #6.dbListFields(con, "tab"); List fields (columns) in a particular table
    #7.dbDataType(con, "tab"); To test data type of an object in SQL (i.e., to see if we can match it in R): 
#0.Establish a connection to the MySQL database
    con <- DBI::dbConnect( 
        RMySQL::MySQL(),
        host = "11.22.333.444",
        user = "username",
        password = "password",
        dbname = "db1"
    )
#1.Read table (esp if table is small, otherwise col-specific dbGetQuery)
    #df1==df2 
    df1 = DBI::dbReadTable(con,"tab")
#1.Read table: dbplyr approach, followup with commands to filter/group/summarise/arrange, etc
    df2 = tbl(con,"tab") #%?% #(or df<-con %>% tbl("tab") %>%...)
    #to show query 
        df %>% show_query()
#2. write table (/overwrite command commented out)
    x = rnorm(10); y=1:10;
    tab2 = as.data.frame(x,y, stringsAsFactors=F )
    DBI::dbWriteTable(con,"tab2",tab2#, overwrite=T)
    )
#3. MUST DISCONNECT AT END
    DBI::dbDisconnect(con)
