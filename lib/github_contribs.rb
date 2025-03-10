require "fileutils"
require "json"
require "date"

class GithubContribs
  VERSION = "2.0.0"

  def graphql(*args)
    IO.popen(["gh", "api", "graphql", *args]) { |io| JSON.parse(io.read) }
  end

  QUERY = <<~EOQ.strip
    query($userName: String!, $from: DateTime!) {
      user(login: $userName) {
        contributionsCollection(from: $from) {
          contributionCalendar {
            totalContributions
            weeks {
              contributionDays {
                contributionCount
                date
              }
            }
          }
        }
      }
    }
  EOQ

  def get name, year
    path = ".#{name}.#{year}.json"

    unless File.exist? path then
      warn "#{name} #{year}" if $v

      data = graphql("--paginate", "--slurp",
                     "-F", "userName=#{name}",
                     "-F", "from=#{year}-01-01T00:00:00",
                     "-f", "query=%s" % [QUERY])
        .dig(0,
             "data",
             "user", # JFC
             "contributionsCollection",
             "contributionCalendar",
             "weeks")
        .map { |h| h["contributionDays"] }
        .map { |a| a.to_h { |h| [h["date"], h["contributionCount"]] } }
        .reduce(&:merge).sort.to_h
        .select { |k,v| k.start_with? "#{year}" } # edges of calendar
        .select { |k,v| v > 0 }

      File.write path, JSON.pretty_generate(data)
    end

    JSON.parse File.read path
  end

  YEARS_QUERY = <<~EOQ.strip
    query($userName: String!) {
      user(login: $userName) {
        contributionsCollection {
          contributionYears
        }
      }
    }
  EOQ

  def years name
    graphql("-F", "userName=#{name}", "-f", "query=%s" % [YEARS_QUERY])
      .dig("data", "user", "contributionsCollection", "contributionYears")
  end

  def load_all name, years
    years.map { |year| get name, year }.reduce(&:merge)
  end

  def generate name, last, io = $stdout, testing = false
    last ||= years(name).min
    last = last.to_i # string from cmdline

    unless testing then
      FileUtils.rm_f ".#{name}.#{Time.now.year}.json" # always fetch this fresh
    end

    steps = 16

    # HACK: make it know the years automatically
    contribs = load_all name, last..Time.now.year

    d0, dN = Date.new(last), Date.today

    min, max = contribs.values.minmax

    max1 = Math.log(max+1)

    scale = ->(n) { [n, (steps * Math.log(n) / max1).floor] }

    total_contributions = contribs.values.sum

    range = (min..max) # used for legend below
      .group_by { |n| scale[n].last }
      .transform_values { |ary|
        m, n = ary.minmax
        m == n ? m : Range.new(m, n)
      }

    contribs.transform_values!(&scale)

    years = (d0.year..dN.year).to_a.reverse.to_h { |year|
      d0 = Date.new year
      d1 = Date.new year+1

      d0 -= d0.wday # back it up to sunday to square everything off
      d1 += (7-d1.wday) # unless d1.wday == 0

      days = (d0...d1).map { |d| d.year == year ? [d.to_s, contribs[d.to_s]] : [] }

      by_week = days.each_slice(7).to_a.transpose

      [ year, by_week ]
    }

    def io.td day, code, count
      if code && count then
        print '<td class="entry day green-color-%d tooltip">' % [code]
        print '<div class="right">%s = %s</div>' % [day, count]
        puts '</td>'
      else
        puts '<td class="entry day nocolor"></td>'
      end
    end

    io.puts "<html>"
    io.puts "<head>"
    io.puts "<title>%s's contribution calendar</title>" % [name]
    io.puts <<~CSS
      <style>
        body { background-color: #ffffff; font-family: system-ui; }

        .entry {
            font-size: 0.8rem;
            display: inline-block;
            margin: 1px;
            width:  12px;
            height: 12px;
            border-radius: 2px;
            outline: 1px solid rgba(0, 0, 0, 10%);
            outline-offset: -1px;
        }

        .entry.day:hover { outline: 2px solid rgba(0, 0, 0, 10%); }

        .non-day { outline: none; } /* cancel out entry's outline for non-days */

        .tooltip {
            display: inline-block;
            position: relative;
        }

        .tooltip .right {
            font-family: monospace;
            font-size: 1.2rem;
            min-width: 11em; # "yyyy-mm-dd = xyz" = 16 chars? but em calculation is wack
            top: 50%;
            left: 100%;
            margin-left: 20px;
            transform: translate(0, -);
            padding: 5px 5px;
            color: #444;
            background-color: #ccc;
            border-radius: 8px;
            position: absolute;
            z-index: 99999999;
            box-sizing: border-box;
            border: 1px solid #fff;
            display: none;
        }

        .tooltip:hover .right { display: block; }

        .nocolor { background-color: hsl(120, 10%, 99%); }

        .green-color-0  { background-color: hsl(120 70% 95%); }
        .green-color-1  { background-color: hsl(120 70% 90%); }
        .green-color-2  { background-color: hsl(120 70% 85%); }
        .green-color-3  { background-color: hsl(120 70% 80%); }
        .green-color-4  { background-color: hsl(120 70% 75%); }
        .green-color-5  { background-color: hsl(120 70% 70%); }
        .green-color-6  { background-color: hsl(120 70% 65%); }
        .green-color-7  { background-color: hsl(120 70% 60%); }
        .green-color-8  { background-color: hsl(120 70% 55%); }
        .green-color-9  { background-color: hsl(120 70% 50%); }
        .green-color-10 { background-color: hsl(120 70% 45%); }
        .green-color-11 { background-color: hsl(120 70% 40%); }
        .green-color-12 { background-color: hsl(120 70% 35%); }
        .green-color-13 { background-color: hsl(120 70% 30%); }
        .green-color-14 { background-color: hsl(120 70% 25%); }
        .green-color-15 { background-color: hsl(120 70% 20%); }
      </style>
    CSS
    io.puts "</head>"

    io.puts "<body>"

    io.puts "<h1>#{name}'s complete github contributions</h1>"
    io.puts "<p><small>Total contributions = %d</small>" % [total_contributions]

    io.puts "<div><small>Legend: </small>"
    io.puts "<table>"
    io.puts "<tr>"
    io.puts '<td class="entry day nocolor"></td>'
    steps.times.each do |code|
      io.td "level #{code}", code, range[code]
    end
    io.puts "</tr>"
    io.puts "</table>"
    io.puts "</div>"

    years.each do |year, by_week|
      total = contribs
        .select { |date, (count, code)| date.start_with?(year.to_s) && count }
        .values
        .map(&:first)
        .sum

      io.puts "<h2>%d</h2>" % [year]

      io.puts '<table class="heatmap calendar">'

      by_week.each_with_index do |weekdays, idx|
        io.puts "<!-- #{year} #{Date::ABBR_DAYNAMES[idx]} -->"
        io.puts "<tr>"

        io.puts '<td class="entry non-day">%s</td>' % [[1, 3, 5].include?(idx) ? Date::ABBR_DAYNAMES[idx][0] : nil]

        weekdays.each_with_index do |(day, (count, code)), wday|
          if day then
            io.td day, code, count
          else
            io.puts '<td class="entry non-day"></td>'
          end
        end

        io.puts "</tr>"
      end

      io.puts "</table>"
      io.puts "<small>%d contributions</small>" % [total]
    end # years

    io.puts "</body>"
    io.puts "</html>"
  end
end
