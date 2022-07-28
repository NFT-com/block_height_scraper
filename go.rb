require_relative 'etherscan_api_client'
require_relative 'etherscan_scraper'
require 'securerandom'
require 'csv'

SQL_GEN_MODE          = true
TEST_MODE             = false
TEST_CONTRACT_ADDRESS = '0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d' # BAYC
VERIFY_MODE           = false
VERIFY_SAMPLE_SIZE    = 50

ETHERSCAN_API_CALL_BATCH_SIZE = 5
ETHERSCAN_API_RATE_LIMIT      = 1

SAMPLE_SIZE = 20000

etherscan_client = EtherscanApiClient.new(paralellism: ETHERSCAN_API_CALL_BATCH_SIZE)

def sql_escaped(str)
  str.gsub(/'/, "''")
end

STANDARDS = { 'ERC721'  => 'f7d4c503-3a75-49c8-b72b-e18b30e14d6a',
              'ERC1155' => '4c2574d1-bd73-446b-94bb-1362f03700c0',
              'UNKNOWN' => 'f7d4c503-3a75-49c8-b72b-e18b30e14d6a',
              nil       => 'f7d4c503-3a75-49c8-b72b-e18b30e14d6a',
              'OpenSea' => '3f868d69-b947-4116-8104-4d984ff59756' }

EXCLUDE = %w[
  0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d
  0x34d85c9CDeB23FA97cb08333b511ac86E1C4E258
  0x87E738a3d5E5345d6212D8982205A564289e6324
  0x306b1ea3ecdf94aB739F1910bbda052Ed4A9f949
  0xbcd4f1ecff4318e7a0c791c7728f3830db506c71
]

if SQL_GEN_MODE

  sql_collection_inserts = []

  _columns = %w[network_id contract_address start_height name description symbol slug website image_url]

  all_collections       = CSV.read('data/output/block_heights.csv', headers: true, :encoding => 'ISO-8859-1', liberal_parsing: true).map { |row| row.to_hash }
  must_have_contracts   = CSV.read('data/input/must_haves.csv', headers: true, :encoding => 'ISO-8859-1', liberal_parsing: true).map { |row| row[1] }
  must_haves            = all_collections.select { |coll| must_have_contracts.include? coll['contract_address'] }
  remaining_collections = all_collections.reject { |coll| (EXCLUDE + must_have_contracts).include? coll['contract_address'] }.sample(SAMPLE_SIZE - must_haves.size)

  collection_sample = must_haves + remaining_collections

  collection_sample.each do |dirty_line|

    next if dirty_line['block_height'].nil?
    symbol = sql_escaped(dirty_line['contract_name'].gsub(/[^0-9a-zA-Z]/i, '').upcase[0..9])

    clean_line = [
      SecureRandom.uuid,
      '94c754fe-e06c-4d2b-bb76-2faa240b5bb8',
      dirty_line['contract_address'],
      dirty_line['block_height'],
      sql_escaped(dirty_line['contract_name']),
      sql_escaped(dirty_line['contract_name']),
      symbol,
      symbol.downcase,
      nil,
      nil
    ]

    standard = STANDARDS[dirty_line['standard']]
    next if standard.nil?

    sql_collection_inserts << "INSERT INTO collections (id, network_id, contract_address, start_height, name, description, symbol, slug, website, image_url) VALUES ('#{clean_line[0]}','#{clean_line[1]}','#{clean_line[2]}',#{clean_line[3]},'#{clean_line[4]}','#{clean_line[5]}','#{clean_line[6]}','#{clean_line[7]}','#{clean_line[8]}','#{clean_line[8]}');"
    sql_collection_inserts << "INSERT INTO collections_standards (collection_id, standard_id) VALUES ('#{clean_line[0]}','#{standard}');"
  end

  sql_inserts = sql_collection_inserts

  File.write("data/output/collections_import.sql", sql_inserts.join("\n"))

elsif TEST_MODE

  puts "Running a test:\t (BAYC)"
  genesis_block = etherscan_client&.get_genesis_block(TEST_CONTRACT_ADDRESS, 0, debug: true)
  puts "Genesis Block:\t #{genesis_block}"

elsif VERIFY_MODE

  etherscan_scraper = EtherscanScraper.new
  existing          = CSV.read('block_heights.csv', headers: true, :encoding => 'ISO-8859-1', liberal_parsing: true).to_a

  existing.sample(VERIFY_SAMPLE_SIZE).each do |row|
    api_found_block_height     = row[2]
    scraper_found_block_height = etherscan_scraper.call(row[1])
    block_height_correct       = api_found_block_height == scraper_found_block_height

    puts "Block height correct?: #{block_height_correct}: Scraped: #{scraper_found_block_height} | API: #{api_found_block_height}\t | #{row[0]}\t"
  end

else
  # SCRAPE MODE

  # Grab existing records from block_heights.csv
  existing           = CSV.read('data/output/block_heights.csv', headers: true, :encoding => 'ISO-8859-1', liberal_parsing: true)
  existing_addresses = existing.map { |row| row['contract_address'] }

  CSV.open('data/output/block_heights.csv', 'w') do |csv|
    csv << %w[contract_name contract_address block_height standard]

    existing.each do |row|
      csv << row
    end

    CSV.read('data/input/prod_collections_and_standards.csv', headers: true, :encoding => 'ISO-8859-1', liberal_parsing: true).reject { |record| existing_addresses.include?(record[0]) }.each_slice(5) do |batch|

      threads = []
      # Execute in batches of 5
      batch.each_with_index do |row, index|
        threads << Thread.new do
          contract_address = row[0]
          contract_name    = row[1]
          standard         = row[2]

          puts "Scraping #{contract_name}..."

          block_height = etherscan_client.get_genesis_block(contract_address, index)
          csv << [contract_name, contract_address, block_height, standard]
        end
      end

      threads.map(&:join)

      # Wait 5 seconds between batches
      sleep ETHERSCAN_API_RATE_LIMIT
    end
  end

end


