Rails.application.config.after_initialize do
  BLOOM_FILTER = BloomFilter.new(expected_size: 100_000, fp_prob: 0.001)
end