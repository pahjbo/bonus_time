Redmine::Plugin.register :bonus_time do
  name 'Bonus Time'
  author 'Austin Smith'
  description 'Enahncements for time-tracking and reporting'
  version '0.0.2'
  url 'https://github.com/pahjbo/bonus_time'
  author_url 'http://alleyinteractive.com'
  menu :top_menu, :bonus_time, { :controller => 'timesheet', :action => 'index' }, :caption => 'Timesheet', :before => :projects
end