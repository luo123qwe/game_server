## The MIT License (MIT)
##
## Copyright (c) 2014-2024
## Savin Max <mafei.198@gmail.com>
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in all
## copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.

desc "Generate Erlang Records from Rails models"
task :generate_record => :environment do
  header = ""
  header << "%%%===================================================================\n"
  header << "%%% Generated by generate_record.rake \n"
  header << "%%%===================================================================\n\n"

  record_content = ""
  record_content << header
  record_content << %Q{-include("../app/include/config_data_records.hrl").\n}

  type_content = ""
  type_content << header
  type_content << "-module(schema_type).\n"
  type_content << "-export([field_types/1]).\n"

  Rails.application.eager_load!
  models = ActiveRecord::Base.descendants
  models_size = models.size
  models.each_with_index do |model, model_index|
    table_name = model.table_name

    # record
    record_content << "-record(#{table_name}, {\n"
    size = model.attribute_names.size
    model.attribute_names.each_with_index do |field, index|
      record_content << "        #{field}"
      record_content << ",\n" if index < size - 1
    end
    record_content << "}).\n\n"

    # schema_type
    kvs = model.columns.map do |column|
      "{#{column.name}, #{column.type}}"
    end
    if model_index + 1 == models_size
      symbol = "."
    else
      symbol = ";"
    end
    type_content << "field_types(#{table_name}) ->\n"
    type_content << "    [#{kvs.join(",\n     ")}]#{symbol}\n"
  end

  header_content = ""
  header_content << header
  table_names = models.map{|model| model.table_name}
  header_content << "-define(DB_TABLE_NAMES, [\n"
  header_content << %Q{    #{table_names.join(",\n    ")}}
  header_content << "])."
  check_to_write("#{FRAMEWORK_ROOT_DIR}/game_server/include/db_table_names.hrl", header_content)

  check_to_write("#{FRAMEWORK_ROOT_DIR}/game_server/include/db_schema.hrl", record_content)

  check_to_write("#{FRAMEWORK_ROOT_DIR}/app/generates/schema_type.erl", type_content)
end