# encoding: utf-8
#
require "date"
require "sinatra"
require File.dirname(__FILE__) + '/timecard.rb'


get "/hello" do
  "hello"
end

post "/attend" do
  timecard = today_timecard
  if timecard.new_record?
    timecard.attend = get_now
    timecard.save
    # TODO output message not to update
  end
  "attend at " + timecard.attend.strftime("%H:%M:%S")
end

post "/leave" do
  timecard = today_timecard
  timecard.leaving = get_now
  timecard.save
  "leaving at " + timecard.leaving.strftime("%H:%M:%S")
end

get "/tsv/:yyyymm" do |yyyymm|
  unless /^20\d\d[01]\d$/ =~ yyyymm
    raise ValidationError, "plz pass yyyymm"
  end
  content_type "application/octet-stream"
  attachment yyyymm + ".tsv"
  response.write get_tsv_of(yyyymm)
end

error ValidationError do
  "error: " + env['sinatra.error'].message
end


def today_timecard
  yyyymmdd = Date.today.strftime("%Y%m%d")
  timecard = Timecards.find_by(yyyymmdd: yyyymmdd)
  timecard ||= Timecards.new
  timecard.yyyymmdd = yyyymmdd
  timecard
end

def get_now
  today = DateTime.now
  min = floor_by_15min(today.min)
  Time.new(today.year, today.mon, today.day, today.hour, min, 0, "+09:00")
end

def floor_by_15min min
  case min
  when 0..14
    0
  when 15..29
    15
  when 30..44
    30
  when 45..60 # 60 means leap second
    45
  else
    raise "not in range of 0..60: " + min
  end
end

def get_tsv_of yyyymm
  timecards = Timecards.where("yyyymmdd LIKE ?", yyyymm + "%").order("yyyymmdd").to_a
  timecard = timecards.shift
  list = ["date\tattend\tleaving"]
  get_date_of_month(yyyymm).each do |d|
    line = [d]
    if timecard && timecard.yyyymmdd === d.gsub("-", "")
      line << timecard.attend ? timecard.attend.strftime("%H:%M:%S") : ""
      line << timecard.leaving ? timecard.leaving.strftime("%H:%M:%S") : ""
      timecard = timecards.shift
    end
    list << line.join("\t")
  end
  list.join("\n")
end

def get_date_of_month yyyymm
  year = yyyymm[0...4].to_i
  month = yyyymm[4..6].to_i
  first = Date.new(year, month, 1)
  last = Date.new(year, month, -1)
  list = []
  (first..last).each do |d|
    list << d.strftime("%Y-%m-%d")
  end
  list
end
