require_relative 'etherscan_client'
require 'csv'

TEST_MODE             = false
TEST_CONTRACT_ADDRESS = '0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d' # BAYC

ETHERSCAN_API_CALL_BATCH_SIZE = 5
ETHERSCAN_API_RATE_LIMIT = 1

etherscan_client = EtherscanClient.new(paralellism: ETHERSCAN_API_CALL_BATCH_SIZE)

if TEST_MODE

  puts "Running a test:\t (BAYC)"
  genesis_block = etherscan_client&.get_genesis_block(TEST_CONTRACT_ADDRESS, 0, debug: true)
  puts "Genesis Block:\t #{genesis_block}"

else

  # Grab existing records from block_heights.csv
  existing = CSV.read('block_heights.csv', headers: true, :encoding => 'ISO-8859-1', liberal_parsing: true)
  existing_addresses = existing.map{ |row| row['contract_address'] }

  CSV.open('block_heights.csv', 'w') do |csv|
    csv << %w[contract_name contract_address block_height]

    existing.each do |row|
      csv << row
    end

    CSV.read('collections.csv', headers: true, :encoding => 'ISO-8859-1', liberal_parsing: true).reject { |record| existing_addresses.include?(record[4]) }.each_slice(5) do |batch|

      threads = []
      # Execute in batches of 5
      batch.each_with_index do |row, index|
        threads << Thread.new do
          contract_address = row[4]
          contract_name    = row[5]

          puts "Scraping #{contract_name}..."

          block_height = etherscan_client.get_genesis_block(contract_address, index)
          csv << [contract_name, contract_address, block_height]
        end
      end

      threads.map(&:join)

      # Wait 5 seconds between batches
      sleep ETHERSCAN_API_RATE_LIMIT
    end
  end

end

