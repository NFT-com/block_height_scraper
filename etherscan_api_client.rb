require "net/http"
require "openssl"
require "json"

class EtherscanApiClient

  # DOCS: https://docs.etherscan.io/

  API_ENDPOINT = 'https://api.etherscan.io'
  API_KEY      = '93THR4TIXG7UFNPFB2NEAMAE1NKRMMXX69'

  attr_accessor :http_clients

  def initialize(paralellism:)
    api_uri       = URI.parse(API_ENDPOINT)
    @http_clients = []

    paralellism.times do |i|
      http_client         = Net::HTTP.new(api_uri.host, api_uri.port)
      http_client.use_ssl = true
      @http_clients << http_client
    end
  end

  def get_genesis_block(address, index, debug: false)
    address_path = "#{authenticated_path}&module=account&action=txlist&address=#{address}&page=1&offset=1&startblock=0&endblock=99999999&sort=asc"

    puts "#{API_ENDPOINT}#{address_path}" if debug

    request = Net::HTTP::Get.new address_path

    begin
      response = http_clients[index].request(request)
    rescue StandardError => e
      puts "Couldn't make API Call for #{address}: #{e.message}"
      return nil
    end

    result = JSON.parse(response.body)

    if result['status'] == '1'
      block_number = result.dig('result', 0, 'blockNumber')
    else
      puts "Couldn't find genesis block for #{address}"
      block_number = nil
    end

    block_number
  end

  private

  def authenticated_path
    "/api?apikey=#{API_KEY}"
  end
end