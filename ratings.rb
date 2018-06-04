require 'httparty'
require 'json'
require 'awesome_print'

contents = (File.exists?('ratings.json') ? File.read('ratings.json') : '{}')
existing = JSON.load(contents)
ratings = {}

require 'thread'
mutex = Mutex.new
work_q = Queue.new
Dir.foreach('/Volumes/media/Movies') {|x| work_q.push x }

begin

  workers = (0...10).map do
    Thread.new do

      while q = work_q.pop

        next if q == '.' or q == '..' or q == '._.DS_Store' or q == '.DS_Store'
        if mutex.synchronize { existing.keys.include?(q) }
          ratings[q] = existing[q]
        end

        matches = q.match(/(.*) \((\d{4})\)/)
        if matches.nil?
          puts "#{q} doesn't match"
          next
        end

        name = matches[1]
        year = matches[2]

        if name.end_with?(', A')
          name = 'A ' + name.sub!(/, A$/, '')
        end
        if name.end_with?(', The')
          name = 'The ' + name.sub!(/, The$/, '')
        end

        res = HTTParty.get("http://www.omdbapi.com/", query: {apikey: '2957f7b', t: name, type: :movie, y: year}).parsed_response

        mutex.synchronize do
          ratings[q] = res["imdbRating"].to_f
        end

        puts "#{name} (#{year}) => #{ratings[q]}"

      end
    end
  end
  workers.map(&:join)

ensure
  File.write('ratings.json', JSON.pretty_generate(ratings))

  ratings.keys.sort_by{|n| -ratings[n]}.each {|n| puts "#{ratings[n]} => #{n}"}
end
