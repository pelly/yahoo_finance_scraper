require 'yahoo_finance_scraper'

describe YahooFinance::Scraper do
  describe YahooFinance::Scraper::Company do
    MockResponse = Struct.new(:code, :body)

    context 'company details' do
      before do
        @getter = mock :getter
        @getter.stub(:get_response).with(kind_of(URI)) do
          MockResponse.new.tap do |response|
            response.code = '200'
            response.body = File.read('spec/fixtures/details.csv')
          end
        end
        @scraper = YahooFinance::Scraper::Company.new 'yhoo', getter: @getter
        @details = @scraper.details
      end

      describe '#details' do
        it 'should get details' do
          @details.keys.should == YahooFinance::Scraper::Company::COLUMNS.keys
          @details[:name].should == 'Yahoo! Inc.'
        end
      end

      describe '#details_url' do
        it 'should generate the correct url' do
          @scraper.send(:details_url).should match(/s=yhoo/)
        end
      end
    end

    context 'historical prices' do
      before do
        @getter = mock :getter
        @getter.stub(:get_response).with(kind_of(URI)) do
          MockResponse.new.tap do |response|
            response.code = '200'
            response.body = File.read('spec/fixtures/historical_daily.csv')
          end
        end
        @scraper = YahooFinance::Scraper::Company.new 'yhoo', getter: @getter
      end

      describe '#historical_prices' do
        it 'should get historical prices' do
          @scraper.historical_prices.should be_all do |h|
            h.keys.sort == [ :close, :date, :high, :low, :open, :volume ]
          end
        end
      end

      describe '#historical_prices_url' do
        it 'should generate the correct url' do
          @scraper.send(:historical_prices_url, Date.today, Date.today).should match(/s=yhoo/)
        end
      end
    end

    describe 'options chain' do
      before do
        @getter = mock :getter
        @getter.stub(:get_response).with(kind_of(URI)) do |url|
          MockResponse.new.tap do |response|
            response.code = '200'
            response.body =
              if url =~ /m=\d{4}-\d{2}$/
                File.read('spec/fixtures/options_chain_2.html')
              else
                File.read('spec/fixtures/options_chain_1.html')
              end
          end
        end
        @scraper = YahooFinance::Scraper::Company.new 'yhoo', getter: @getter
      end

      describe '#options_chain' do
        it 'should get options chain' do
          @scraper.options_chain.map(&:values).flatten.should be_all do |h|
            h.keys.sort == [ :ask, :bid, :change, :expires_at, :last, :open_int, :strike, :volume ]
          end
        end
      end

      describe '#options_chain_url' do
        it 'should generate the correct url' do
          @scraper.send(:options_chain_url).should match(/s=yhoo/)
        end
      end
    end
  end

  describe YahooFinance::Scraper::Actives do
    describe '#losers' do
      before do
        @getter = mock :getter
        @getter.stub(:get_response).with(kind_of(URI)) do |url|
          MockResponse.new.tap do |response|
            response.code = '200'
            response.body =
              case url
              when /e=us/
                File.read 'spec/fixtures/losers_1.html'
              when /e=o/
                File.read 'spec/fixtures/losers_2.html'
              when /e=aq/
                File.read 'spec/fixtures/losers_3.html'
              when /e=nq/
                File.read 'spec/fixtures/losers_4.html'
              end
          end
        end
        @scraper = YahooFinance::Scraper::Actives.new getter: @getter
      end

      it 'should get losers' do
        @scraper.losers.should be_all {|h| h.keys == [:symbol, :name] }
      end
    end
  end
end
