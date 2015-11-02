# -*- coding: utf-8 -*-

require 'minitest/autorun'
require 'tempfile'
require 'sqlite3'
require 'pry'

begin
  load '../lib/csvql.rb'
  load '../lib/csvql/csvql.rb'
  load '../lib/csvql/version.rb'
rescue LoadError
  abort("please change directory to test/; QUITTING")
end

class TestTableCreation < MiniTest::Test
  def setup
  end

  #you should not have to update this method to add new test columns to header_test.csv
  def test_parse_headers
    tmpdbfile = Tempfile.new('tmp.db')
    args = ["--header", 
            "--source", "header_test.csv", 
            "--save-to", tmpdbfile.path, 
            "--ifs=" ",",
            "--table-name","header_test"]
    Csvql.run(args)

    db = SQLite3::Database.new tmpdbfile.path
    headers_from_db = db.execute2('select * from header_test;')[0]
    headers_from_file = File.open('header_test.csv').each_line.first.gsub(/\n/,'').split(',')

    #binding.pry
    assert_equal headers_from_db, headers_from_file
  end

  #same as above, you should not have to update this method to add new test columns to header_test.csv
  def test_primary_key_creation
    tmpdbfile = Tempfile.new('tmp.db')
    args = ["--header", 
            "--source", "header_test.csv", 
            "--save-to", tmpdbfile.path, 
            "--ifs=" ",",
            "--table-name","pk_test",
            "--primary-key","id"]
    Csvql.run(args)

    db = SQLite3::Database.new tmpdbfile.path
    headers_from_db = db.execute2('select * from pk_test;')[0]
    headers_from_file = ['id',File.open('header_test.csv').each_line.first.gsub(/\n/,'').split(',')].flatten

    #binding.pry
    assert_equal headers_from_db, headers_from_file
  end

  #if the primary key overlaps with a header in the file, do not create the DB
  def test_fail_on_pk_overlap_with_header
  end

  #test proper creation of table names with hyphens
  def test_tablenames_with_hyphens
  end
end
