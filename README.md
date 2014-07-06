# Csvql

Csvql is inspired by [TextQL](https://github.com/dinedal/textql).

## Installation

Add this line to your application's Gemfile:

    gem 'csvql'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install csvql

## Usage

Usage by examples:

    $ cat sample.csv
    id,name,age
    1,Anne,33
    2,Bob,25
    3,Charry,48
    4,Daniel,16
    5,Edward,52

Simple query:

    $ csvql --source sample.csv --sql "select count(*) from tbl"
    6
    $ csvql --source sample.csv --header -sql "select count(*) from tbl"
    5
    $ csvql --source sample.csv --header -sql "select * from tbl where age > 40"
    3|Charry|48
    5|Edward|52

Open console:

    $ csvql --source sample.csv --header --console
    SQLite version 3.7.7 2011-06-25 16:35:41
    Enter ".help" for instructions
    Enter SQL statements terminated with a ";"
    sqlite> select * from tbl order by age desc;
    5|Edward|52
    3|Charry|48
    1|Anne|33
    2|Bob|25
    4|Daniel|16

From stdin:

    $ cat sample.csv | csvql --header --sql "select max(age) from tbl"
    52

Save to db-file:

    $ csvql --source sample.csv --header --save-to test.db
    $ sqlite3 test.db
    SQLite version 3.7.7 2011-06-25 16:35:41
    Enter ".help" for instructions
    Enter SQL statements terminated with a ";"
    sqlite> select avg(age) from tbl;
    34.8

Options:

    $ svql --help
    Usage: csvql [options]
        --console                    After all commands are run, open sqlite3 console with this data
        --header                     Treat file as having the first row as a header row
        --save-to=FILE               If set, sqlite3 db is left on disk at this path
        --skip-comment               Skip comment lines start with '#'
        --source=FILE                Source file to load, or defaults to stdin
        --sql=SQL                    SQL Command(s) to run on the data
        --table-name=NAME            Override the default table name (tbl)
        --verbose                    Enable verbose logging

## Contributing

1. Fork it ( https://github.com/[my-github-username]/csvql/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
