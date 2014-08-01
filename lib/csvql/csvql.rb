#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'tempfile'
require 'sqlite3'

module Csvql
  class TableHandler
    def initialize(path, console)
      @db_file = if path && path.strip.size > 0
                   path
                 elsif console
                   @tmp_file = Tempfile.new("csvql").path
                 else
                   ":memory:"
                 end
      @db = SQLite3::Database.new(@db_file)
    end

    def create_table(schema, table_name="tbl")
      @col_name = schema.split(",").map {|c| c.split.first.strip }
      @col_size = @col_name.size
      @table_name = table_name
      exec "CREATE TABLE IF NOT EXISTS #{@table_name} (#{schema})"
    end

    def create_alias(table, view="tbl")
      return if table == view
      exec "DROP VIEW IF EXISTS #{view}"
      exec "CREATE VIEW #{view} AS SELECT * FROM #{table}"
    end

    def drop_table(table_name="tbl")
      exec "DROP TABLE IF EXISTS #{table_name}"
    end

    def prepare(cols)
      sql = "INSERT INTO #{@table_name} (#{@col_name.join(",")}) VALUES (#{cols.map{"?"}.join(",")});"
      @pre = @db.prepare(sql)
    end

    def insert(cols, line)
      if cols.size != @col_size
        puts "line #{line}: wrong number of fields in line (skipping)"
        return
      end
      @pre ||= prepare(cols)
      @pre.execute(cols)
    end

    def exec(sql)
      @db.execute(sql)
    end

    def open_console
      system("sqlite3", @db_file)
      File.delete(@tmp_file) if @tmp_file
    end
  end
end
