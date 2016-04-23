# encoding: utf-8
#
require "date"
require "sinatra"
require File.dirname(__FILE__) + '/timecard.rb'


post "/attend" do
  timecard = today_timecard
  if timecard.new_record?
    timecard.attend = get_now
    timecard.save
  end
  "attend at " + timecard.attend.strftime("%H:%M:%S")
end

post "/leave" do
  timecard = today_timecard
  timecard.leaving = get_now
  timecard.save
  "leaving at " + timecard.leaving.strftime("%H:%M:%S")
end

post "/workedat" do
  work_place = WorkPlace.new
  work_place.latitude = params["latitude"]
  work_place.longitude = params["longitude"]
  work_place.save
  "saved at #{work_place.latitude}, #{work_place.longitude}"
end

get "/tsv/:yyyymm" do |yyyymm|
  unless /^20\d\d[01]\d$/ =~ yyyymm
    raise ValidationError, "plz pass yyyymm"
  end
  content_type "application/octet-stream"
  attachment yyyymm + ".tsv"
  response.write get_tsv_of(yyyymm).join("\n")
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
  pin = Time.new(today.year, today.month, today.day, 8, 30, 0, "+09:00")
  kiri = Time.new(today.year, today.month, today.day, 9, 15, 0, "+09:00")
  morning = pin..kiri
  if morning.cover?(today)
    kiri
  else
    min = floor_by_15min(today.min)
    Time.new(today.year, today.mon, today.day, today.hour, min, 0, "+09:00")
  end
end

def floor_by_15min min
  case min
  when 0..14
    0
  when 15..29
    15
  when 30..44
    30
  when 45..59
    45
  else
    raise "not in range of 0..60: " + min
  end
end

require "pp"
def get_tsv_of yyyymm
  timecards = Timecards.where("yyyymmdd LIKE ?", yyyymm + "%").order("yyyymmdd").to_a
  timecard = timecards.shift
  get_date_of_month(yyyymm).map do |d|
    line = [d]
    if timecard && timecard.yyyymmdd === d.gsub("-", "")
      if timecard.attend
        line << timecard.attend.strftime("%H:%M:%S")
      else
        line << ""
      end
      if timecard.leaving
        line << timecard.leaving.strftime("%H:%M:%S")
      else
        line << ""
      end
      timecard = timecards.shift
    end
    line.join("\t")
  end
end

def get_date_of_month yyyymm
  year = yyyymm[0...4].to_i
  month = yyyymm[4..6].to_i
  first = Date.new(year, month, 1)
  last = Date.new(year, month, -1)
  (first..last).map do |d|
    d.strftime("%Y-%m-%d")
  end
end
