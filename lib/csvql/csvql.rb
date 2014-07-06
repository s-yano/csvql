#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'csv'
require 'nkf'
require 'tempfile'
require 'optparse'
require 'sqlite3'

module Csvql
  class TableHandler
    def initialize(path, console)
      @db_file = if path && path.size > 0
                   path
                 elsif console
                   @tmp_file = true
                   Tempfile.new("csvql").path + ".sqlite3"
                 else
                   ":memory:"
                 end
      @db = SQLite3::Database.new(@db_file)
    end

    def create_table(cols, header, table_name="tbl")
      @col_size = cols.size
      @table_name = table_name
      @col_name = if header
                    cols
                  else
                    @col_size.times.map {|i| "c#{i}" }
                  end
      col = @col_name.map {|c| "#{c} NONE" }
      sql = "CREATE TABLE #{@table_name} (#{col.join(",")})"
      @db.execute(sql)
    end

    def single_insert(cols, line)
      if cols.size != @col_size
        puts "line #{line}: wrong number of fields in line"
        return
      end
      col = cols.map {|c| "'#{c}'" }
      sql = "INSERT INTO #{@table_name} VALUES(#{col.join(",")});"
      @db.execute(sql)
    end

    def bulk_insert(bulk)
      rows = []
      bulk.each do |cols|
        col = cols.map {|c| "'#{c}'" }
        rows << "(#{col.join(',')})"
      end
      sql = "INSERT INTO #{@table_name} VALUES#{rows.join(",")};"
      # puts sql
      @db.execute(sql)
    end

    def prepare(cols)
      sql = "INSERT INTO #{@table_name} (#{@col_name.join(",")}) VALUES (#{cols.map{"?"}.join(",")});"
      @pre = @db.prepare(sql)
    end

    def insert(cols, line)
      if cols.size != @col_size
        puts "line #{line}: wrong number of fields in line"
        return
      end
      @pre ||= prepare(cols)
      @pre.execute(cols)
    end

    def exec(sql)
      @db.execute(sql) do |row|
        puts row.join("|")
      end
    end

    def open_console
      system("sqlite3", @db_file)
      File.delete(@db_file) if @tmp_file
    end
  end

  class << self
    def option_parse(argv)
      opt = OptionParser.new
      option = {}

      opt.on("--console",         "After all commands are run, open sqlite3 console with this data") {|v| option[:console] = v }
      opt.on("--header",          "Treat file as having the first row as a header row") {|v| option[:header] = v }
      opt.on("--save-to=FILE",    "If set, sqlite3 db is left on disk at this path")    {|v| option[:save_to] = v }
      opt.on("--skip-comment",    "Skip comment lines start with '#'")                  {|v| option[:skip_comment] = v }
      opt.on("--source=FILE",     "Source file to load, or defaults to stdin")          {|v| option[:source] = v }
      opt.on("--sql=SQL",         "SQL Command(s) to run on the data")                  {|v| option[:sql] = v }
      opt.on("--table-name=NAME", "Override the default table name (tbl)")              {|v| option[:table_name] = v }
      opt.on("--verbose",         "Enable verbose logging")                             {|v| option[:verbose] = v }
      opt.parse!(argv)

      option
    end

    def run(argv)
      option = option_parse(argv)
      if option[:console] && option[:source] == nil
        puts "Can not open console with pipe input, read a file instead"
        exit 1
      end

      csvfile = option[:source] ? File.open(option[:source]) : $stdin

      tbl = TableHandler.new(option[:save_to], option[:console])
      bulk = []
      tbl.exec("PRAGMA synchronous=OFF")
      tbl.exec("BEGIN TRANSACTION")
      csvfile.each.with_index(1) do |line,i|
        next if option[:skip_comment] && line.start_with?("#")
        row = NKF.nkf('-w', line).parse_csv
        if i == 1
          tbl.create_table(row, option[:header], option[:table_name]||"tbl")
          next if option[:header]
        end
        tbl.insert(row,i)
      end
      tbl.exec("COMMIT TRANSACTION")

      tbl.exec(option[:sql]) if option[:sql]
      tbl.open_console if option[:console]
    end
  end
end
