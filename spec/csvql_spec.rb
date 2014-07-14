require 'spec_helper'

csvfile = File.join(File.expand_path(File.dirname("__FILE__")), "spec/sample.csv")

describe Csvql do
  it 'has a version number' do
    expect(Csvql::VERSION).not_to be nil
  end

  it 'select name' do
    expect(capture {
             Csvql.run([csvfile, "--select", "name"])
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
             Csvql.run([csvfile, "--where", "age > 40"])
           }).to eq(<<EOL)
3|Charry|48
5|Edward|52
EOL
  end

  it 'sql option' do
    expect(capture {
             Csvql.run([csvfile, "--sql", "select name,age from tbl where age between 20 and 40"])
           }).to eq(<<EOL)
Anne|33
Bob|25
EOL
  end

  it 'change output delimiter' do
    expect(capture {
             Csvql.run([csvfile, "--where", "id = 3", "--output-dlm", ","])
           }).to eq(<<EOL)
3,Charry,48
EOL
  end

  it 'change table name' do
    expect(capture {
             Csvql.run([csvfile, "--sql", "select id,name from user_info where id >= 4", "--table-name", "user_info"])
           }).to eq(<<EOL)
4|Daniel
5|Edward
EOL
  end
end
