require 'nokogiri'
require 'open-uri'

class EtherscanScraper
  ES_ADDRESS = 'https://etherscan.io/address/'
  ES_TX = 'https://etherscan.io/tx/'

  def call(contract_address)
    # load collection page
    collection_url = "#{ES_ADDRESS}#{contract_address}"
    collection_page = URI.open(collection_url)

    # get recieve address
    receipt_address = get_receipt_address(collection_page)

    receipt_url = "#{ES_TX}#{receipt_address}"
    receipt_page = URI.open(receipt_url)

    get_block_height(receipt_page)
  end

  private

  def get_receipt_address(collection_page)
    doc = Nokogiri::HTML(collection_page)

    doc.search('//*[@id="ContentPlaceHolder1_trContract"]/div/div[2]/span/a')&.first&.text
  end

  def get_block_height(receipt_page)
    doc = Nokogiri::HTML(receipt_page)

    doc.search('//*[@id="ContentPlaceHolder1_maintable"]/div[3]/div[2]/a')&.first&.text
  end

end