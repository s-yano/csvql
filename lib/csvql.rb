# -*- coding: utf-8 -*-

require 'csv'
require 'nkf'
require 'optparse'
require 'ostruct'

require "csvql/csvql"
require "csvql/version"

module Csvql
  class << self
    def option_parse(argv)
      opt_parser = OptionParser.new("Usage: csvql [csvfile] [options]")
      opt = OpenStruct.new

      # default
      # option[:header] = true

      opt_parser.on("--console",         "After all commands are run, open sqlite3 console with this data") {|v| opt.console = v }
      opt_parser.on("--header",          "Treat file as having the first row as a header row") {|v| opt.header = v }
      opt_parser.on('--ifs=","',         "Input field separator (,)")                          {|v| opt.ifs = v }
      opt_parser.on('--ofs="|"',         "Output field separator (|)")                         {|v| opt.ofs = v }
      opt_parser.on("--save-to=FILE",    "If set, sqlite3 db is left on disk at this path")    {|v| opt.save_to = v }
      opt_parser.on("--append",          "Append mode (not dropping any tables)")              {|v| opt.append = v }
      opt_parser.on("--skip-comment",    "Skip comment lines start with '#'")                  {|v| opt.skip_comment = v }
      opt_parser.on("--source=FILE",     "Source file to load, or defaults to stdin")          {|v| opt.source = v }
      opt_parser.on("--sql=SQL",         "SQL Command(s) to run on the data")                  {|v| opt.sql = v }
      opt_parser.on("--select=COLUMN",   "Select column (*)")                                  {|v| opt.select = v }
      opt_parser.on("--schema=FILE or STRING", "Specify a table schema")                       {|v| opt.schema = v }
      opt_parser.on("--strip",           "Strip spaces around columns")                        {|v| opt.strip = v }
      opt_parser.on("--where=COND",      "Where clause")                                       {|v| opt.where = v }
      opt_parser.on("--table-name=NAME", "Override the default table name (tbl)")              {|v| opt.table_name = v }
      opt_parser.on("--primary-key=ID",  "Create primary key (id)")                            {|v| opt.primary_key = v }
      opt_parser.on("--verbose",         "Enable verbose logging")                             {|v| opt.verbose = v }
      opt_parser.parse!(argv)

      opt.source ||= argv[0]
      # opt.where] ||= argv[1]
      opt.table_name ||= if opt.save_to && opt.source != nil
                                File.basename(opt.source.downcase, ".csv").gsub(/\./, "_")
                              else
                                "tbl"
                              end
      if opt.ifs == 'tab'
        opt.ifs = "\t"
      end

      if opt.ofs == 'tab'
        opt.ofs = "\t"
      end
      opt.ofs ||= "|"

      if opt.completion
        puts opt.compsys('csvql')
        exit 0
      end
      opt
    end

    def run(argv)
      opt = option_parse(argv)
      if opt.console && opt.source == nil
        puts "Can not open console with pipe input, read a file instead"
        exit 1
      end
      if opt.sql && (opt.select || opt.where)
        puts "Can not use --sql option and --select|--where option at the same time."
        exit 1
      end

      csvfile = opt.source ? File.open(opt.source) : $stdin
      first_line = csvfile.readline

      schema = opt.schema
      if schema
        file = File.expand_path(schema)
        if File.exist?(file)
          schema = File.open(file).read
        end
      else
        cols = first_line.parse_csv(col_sep: opt.ifs)
        col_name = if opt.header
                     cols
                   else
                     cols.size.times.map {|i| "c#{i}" }
                   end
        schema = col_name.map {|c| "[#{c}] NONE" }.join(",")
        schema = "[id] INTEGER PRIMARY KEY," + schema unless opt.primary_key.nil?
      end
      csvfile.rewind unless opt.header


      tbl = TableHandler.new(opt.save_to, opt.console)
      tbl.drop_table(opt.table_name) unless opt.append
      tbl.create_table(schema, opt.table_name)
      tbl.create_alias(opt.table_name) if opt.save_to
      tbl.exec("PRAGMA synchronous=OFF")
      tbl.exec("BEGIN TRANSACTION")
      csvfile.each.with_index(1) do |line,i|
        line = NKF.nkf('-w', line).strip
        next if line.size == 0
        next if opt.skip_comment && line.start_with?("#")
        row = line.parse_csv(col_sep: opt.ifs)
        row.map!(&:strip) if opt.strip
        tbl.insert(row, i)
      end
      tbl.exec("COMMIT TRANSACTION")

      if opt.sql
        sql = opt.sql
      elsif opt.select || opt.where
        opt.select ||= "*"
        sql = "select #{opt.select} from #{opt.table_name}"
        if opt.where
          sql += " where (#{opt.where})"
        end
      end

      tbl.exec(sql).each {|row| puts row.join(opt.ofs) } if sql
      tbl.open_console if opt.console
    end
  end
end
