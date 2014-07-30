# -*- coding: utf-8 -*-

require 'csv'
require 'nkf'
require 'optparse'

require "csvql/csvql"
require "csvql/version"

module Csvql
  class << self
    def option_parse(argv)
      opt = OptionParser.new("Usage: csvql [csvfile] [options]")
      option = {}

      # default
      # option[:header] = true

      opt.on("--console",         "After all commands are run, open sqlite3 console with this data") {|v| option[:console] = v }
      opt.on("--[no-]header",     "Treat file as having the first row as a header row") {|v| option[:header] = v }
      opt.on('--output-dlm="|"',  "Output delimiter (|)")                               {|v| option[:output_dlm] = v }
      opt.on("--save-to=FILE",    "If set, sqlite3 db is left on disk at this path")    {|v| option[:save_to] = v }
      opt.on("--append",          "Append mode (not dropping any tables)")              {|v| option[:append] = v }
      opt.on("--skip-comment",    "Skip comment lines start with '#'")                  {|v| option[:skip_comment] = v }
      opt.on("--source=FILE",     "Source file to load, or defaults to stdin")          {|v| option[:source] = v }
      opt.on("--sql=SQL",         "SQL Command(s) to run on the data")                  {|v| option[:sql] = v }
      opt.on("--select=COLUMN",   "Select column (*)")                                  {|v| option[:select] = v }
      opt.on("--schema=FILE or STRING", "Specify a table schema")                       {|v| option[:schema] = v }
      opt.on("--strip",           "strip every column data")                            {|v| option[:strip] = v }
      opt.on("--where=COND",      "Where clause")                                       {|v| option[:where] = v }
      opt.on("--table-name=NAME", "Override the default table name (tbl)")              {|v| option[:table_name] = v }
      opt.on("--verbose",         "Enable verbose logging")                             {|v| option[:verbose] = v }
      opt.parse!(argv)

      option[:source] ||= argv[0]
      # option[:where] ||= argv[1]
      option[:table_name] ||= "tbl"
      if option[:output_dlm] == 'tab'
        option[:output_dlm] = "\t"
      end
      option[:output_dlm] ||= "|"

      if option[:completion]
        puts opt.compsys('csvql')
        exit 0
      end
      option
    end

    def run(argv)
      option = option_parse(argv)
      if option[:console] && option[:source] == nil
        puts "Can not open console with pipe input, read a file instead"
        exit 1
      end
      if option[:sql] && (option[:select] || option[:where])
        puts "Can not use --sql option and --select|--where option at the same time."
        exit 1
      end

      csvfile = option[:source] ? File.open(option[:source]) : $stdin
      first_line = csvfile.readline

      schema = option[:schema]
      if schema
        file = File.expand_path(schema)
        if File.exist?(file)
          schema = File.open(file).read
        end
      else
        cols = first_line.parse_csv
        col_name = if option[:header]
                     cols
                   else
                     cols.size.times.map {|i| "c#{i}" }
                   end
        schema = col_name.map {|c| "#{c} NONE" }.join(",")
      end
      csvfile.rewind unless option[:header]

      tbl = TableHandler.new(option[:save_to], option[:console])
      tbl.drop_table(option[:table_name]) unless option[:append]
      tbl.create_table(schema, option[:table_name])
      tbl.exec("PRAGMA synchronous=OFF")
      tbl.exec("BEGIN TRANSACTION")
      csvfile.each.with_index(1) do |line,i|
        line = NKF.nkf('-w', line).strip
        next if line.size == 0
        next if option[:skip_comment] && line.start_with?("#")
        row = line.parse_csv
        row.map!(&:strip) if option[:strip]
        tbl.insert(row, i)
      end
      tbl.exec("COMMIT TRANSACTION")

      if option[:sql]
        sql = option[:sql]
      elsif option[:select] || option[:where]
        option[:select] ||= "*"
        sql = "select #{option[:select]} from #{option[:table_name]}"
        if option[:where]
          sql += " where (#{option[:where]})"
        end
      end

      tbl.exec(sql).each {|row| puts row.join(option[:output_dlm]) } if sql
      tbl.open_console if option[:console]
    end
  end
end
