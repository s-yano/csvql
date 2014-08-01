require 'spec_helper'

csvfile = File.join(File.expand_path(File.dirname("__FILE__")), "spec/sample.csv")

describe Csvql do
  it 'has a version number' do
    expect(Csvql::VERSION).not_to be nil
  end

  it 'select name' do
    expect(capture {
             Csvql.run([csvfile, "--header", "--select", "name"])
           }).to eq(<<EOL)
Anne
Bob
Charry
Daniel
Edward
EOL
  end

  it 'where age > 40' do
    expect(capture {
             Csvql.run([csvfile, "--header", "--where", "age > 40"])
           }).to eq(<<EOL)
3|Charry|48
5|Edward|52
EOL
  end

  it 'sql option' do
    expect(capture {
             Csvql.run([csvfile, "--header", "--sql", "select name,age from tbl where age between 20 and 40"])
           }).to eq(<<EOL)
Anne|33
Bob|25
EOL
  end

  it 'change output delimiter' do
    expect(capture {
             Csvql.run([csvfile, "--header", "--where", "id = 3", "--output-dlm", ","])
           }).to eq(<<EOL)
3,Charry,48
EOL
  end

  it 'change table name' do
    expect(capture {
             Csvql.run([csvfile, "--header", "--sql", "select id,name from users where id >= 4", "--table-name", "users"])
           }).to eq(<<EOL)
4|Daniel
5|Edward
EOL
  end

  it 'save-to db file' do
    dbfile = "csvql_test.db"
    Csvql.run([csvfile, "--header", "--save-to", dbfile])
    expect(`sqlite3 #{dbfile} "select * from tbl"`).to eq(<<EOL)
1|Anne|33
2|Bob|25
3|Charry|48
4|Daniel|16
5|Edward|52
EOL
    File.delete dbfile
  end

  it 'no header' do
    expect(capture {
             Csvql.run([csvfile, "--where", "typeof(c0)!='integer'"])
           }).to eq(<<EOL)
id|name|age
EOL
  end

  it 'source option' do
    expect(capture {
             Csvql.run(["--source", csvfile, "--header", "--select", "count(*)"])
           }).to eq(<<EOL)
5
EOL
  end
end
