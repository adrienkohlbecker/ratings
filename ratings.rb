require 'imdb'
require 'json'
require 'awesome_print'

contents = (File.exists?('ratings.json') ? File.read('ratings.json') : '{}')
ratings = JSON.load(contents)

require 'thread'
mutex = Mutex.new
work_q = Queue.new
Dir.foreach('/Volumes/media/Movies') {|x| work_q.push x }

begin

  workers = (0...10).map do
    Thread.new do

      while q = work_q.pop

        next if q == '.' or q == '..'
        next if mutex.synchronize do
          ratings.keys.include?(q)
        end

        res = Imdb::Search.new(q).movies.first.rating
        mutex.synchronize do
          ratings[q] = res
        end

        puts "#{q} => #{ratings[q]}"

      end
    end
  end
  workers.map(&:join)

ensure
  File.write('ratings.json', JSON.dump(ratings))

  ratings.keys.sort_by{|n| -ratings[n]}.each {|n| puts "#{ratings[n]} => #{n}"}
end
