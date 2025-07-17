require 'bitarray'
require 'digest'
require 'redis'

class BloomFilter
  REDIS_KEY = "bloom_filter_data".freeze
  def initialize(expected_size: 10_000, fp_prob: 0.001)
    @expected_size = expected_size
    @fp_prob = fp_prob
    @size = calculate_bit_size
    @hash_count = calculate_hash_count
    @redis = Redis.new(url: ENV['REDIS_URL'])
    @bit_array = BitArray.new(@size)
    preload_existing_usernames if @bit_array.count(true).zero? # Only load if empty
  end

  def add(item)
    hash_values(item).each { |i| @bit_array[i] = 1 }
    save_to_redis
  end

  def include?(item)
    hash_values(item).all? { |i| @bit_array[i] == 1 }
  end

  private

  def load_or_initialize_bitarray
    if (data = @redis.get(REDIS_KEY))
      Marshal.load(data)
    else
      BitArray.new(@size)
    end
  end

  def preload_existing_usernames
    User.pluck(:username).each do |username|
      hash_values(username.downcase).each { |i| @bit_array[i] = 1 }
    end
    save_to_redis
    puts "Preloaded #{User.count} usernames into Bloom filter" # Debug output
  end

  def save_to_redis
    @redis.set(REDIS_KEY, Marshal.dump(@bit_array))
  end

  def clear
    @bit_array = BitArray.new(@size)
  end

  private

  def hash_values(item)
    hashes = []
    (0...@hash_count).each do |i|
      hash = Digest::SHA256.hexdigest("#{item}-#{i}").to_i(16)
      hashes << hash % @size
    end
    hashes
  end

  def calculate_bit_size
    (-(@expected_size * Math.log(@fp_prob)) / (Math.log(2) ** 2)).ceil
  end

  def calculate_hash_count
    ((@size / @expected_size.to_f) * Math.log(2)).ceil
  end

  def count(true_values = true)
    @bit_array.count(true_values)
  end
end