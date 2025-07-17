class UserGenerator
  BATCH_SIZE = 1000
  MAX_RETRIES = 3 # For individual username generation

  def self.generate(total_users)
    new.generate(total_users)
  end

  def generate(total_users)
    inserted_count = 0
    bloom_filter = BloomFilter.new(expected_size: total_users * 2, fp_prob: 0.0001) # Lower false positive rate

    puts "Starting generation of #{total_users} users..."

    (total_users.to_f / BATCH_SIZE).ceil.times do |batch|
      users = []
      retries = 0
      
      begin
        BATCH_SIZE.times do
          username = generate_unique_username(bloom_filter)
          users << { username: username, created_at: Time.current, updated_at: Time.current }
          inserted_count += 1
          print_progress(inserted_count, total_users) if inserted_count % 1000 == 0
        end

        User.insert_all(users)
      rescue => e
        retries += 1
        puts "\nBatch #{batch} failed (#{e.message}), retry #{retries}/3"
        sleep 1
        retry if retries < 3
        raise "Failed to insert batch #{batch} after 3 attempts"
      end
    end

    puts "\nSuccessfully generated #{inserted_count} users!"
  end

  private

  def generate_unique_username(bloom_filter)
    retries = 0
    
    loop do
      # More varied username generation
      username = [
        Faker::Internet.username(specifier: 8..20), # Not using unique here
        SecureRandom.hex(3).downcase,
        Time.now.to_f.to_s.gsub('.','')[-4..-1]
      ].join('_').gsub(/[^a-z0-9_]/, '')[0..24] # Ensure valid format

      unless bloom_filter.include?(username)
        bloom_filter.add(username)
        return username
      end

      retries += 1
      if retries > MAX_RETRIES
        # Fallback to completely random if too many retries
        username = "user_#{SecureRandom.hex(10)}"
        bloom_filter.add(username)
        return username
      end
    end
  end

  def print_progress(current, total)
    percent = (current.to_f / total * 100).round(1)
    print "\rProgress: #{current}/#{total} (#{percent}%)"
    STDOUT.flush
  end
end