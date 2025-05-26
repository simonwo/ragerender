# E.g. 20th Nov 2024, 2:35 PM
SUFFIXES = {1 => 'st', 2 => 'nd', 3 => 'rd'}
def comicfury_date time
  fmt = "%-d#{SUFFIXES.fetch(time.day, 'th')} %b %Y, %-I:%M %p"
  time.strftime(fmt)
end
