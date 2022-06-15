require 'nokogiri'
require 'open-uri'

class Scraper
  attr_accessor :contract_address

  ES_ADDRESS = 'https://etherscan.io/address/'
  ES_TX = 'https://etherscan.io/tx/'

  def initialize(contract_address)
    @contract_address = contract_address
  end

  def call
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

  def testing

    sample_contract = '0x495f947276749Ce646f68AC8c248420045cb7b5e'
    sample_tx = '0x7d0512fa5e19d2d775bb55efe9b5e9960cc59f9c67c627b1f5eb22a5749162f2'
    sample_block = 11374506

    # scraper = Scraper.new(sample_contract)
    # puts scraper.call

    puts '11374506' == scraper.call

  end
end