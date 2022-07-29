# NFT.com Block Height Scraper Utility

This utility generates an SQL script to import collections and genesis blocks for the indexer database

It accepts a csv file (formatted as per `data/input/prod_collections_and_standards.csv`), and fetches the genesis blocks for each of those collections from Etherscan


### Instructions

- Install ruby
  `brew install ruby` or use runtime manager e.g. `asdf`

- Clone repo, in project root, install package manager:
  `gem install bundle`
  
- Install dependencies 
  `bundle install`
  
- Run:
  `ruby go.rb`

### Configuration

There are some config flags at the start of `go.rb`
- `SQL_GEN_MODE` - this is the default run mode and outputs the SQL to the file `data/output/collections_import.sql`
- other modes are for debug

You can add a new latest production data as per `data/input/prod_collections_and_standards.csv`
...and add any 'must have' collections to `data/input/must_haves.csv`

The regular sql generation mode will output sql in `data/output depending on your config`

### Notes

This is using a free etherscan API account - so it only allows 5 requests per second. This script is throttled to run 5 requests concurrently per second, so it will take a while to go through all 15000 collections - please be patient 
