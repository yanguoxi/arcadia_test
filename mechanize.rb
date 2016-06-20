require 'mechanize'
require 'csv'
require 'rspec'
class Arcadia
	
	# First create agent and login as User kdw813
	def login
		@agent = Mechanize.new
		@agent.get("https://mydom.dom.com/siteminderagent/forms/login.fcc?TYPE=33554433&REALMOID=06-1e48bddc-7dd3-4ca8-8133-49c6916c615f&GUID=&SMAUTHREASON=0&METHOD=GET&SM@AGENTNAME=-SM-ZD0ZmygcKDp1D83QUxDaa%2bQnwIXmw5j9CWjg5H6SwdF%2bmIPInLrwwSfo%2f81D%2fMdD&TARGET=-SM-https%3a%2f%2fmya%2edom%2ecom%2f")
		@agent.page.forms
		login_form = @agent.page.forms.first

		login_form.USER = 'kdw813'
		login_form.PASSWORD = 'spl1nter'
		@agent.submit(login_form, login_form.buttons.first)
		@agent.page.links
		@agent.page.links.first.text
		@agent.page.link_with(:text => "Billing").click
		@agent.page.link_with(:text => "Billing History & more").click
		# pp @agent.page
		return @agent.page
	end

	# Submit the filter form get the billing table
	def filter_form(num)
		billing_filter_form = @agent.page.forms.first
		billing_filter_form.SelectedStatementType = num
		@agent.submit(billing_filter_form, billing_filter_form.buttons.first)
		return @agent.page
	end

	# parse table & extract headers and in the HTML
	def get_table_headers(doc)
		headers = []
		doc.xpath('//table/tbody/tr/th').each do |th|
		  headers << th.text
		end
		headers
	end

	# parse Read Date, Amount, Due Date based on headers
	def parse_billing(doc, headers)
		id = 0
		rows = []
		doc.xpath('//table/tbody/tr').each do |row, i| 
		  if !row.xpath('td')[2].nil? && !row.xpath('td')[2].text.strip.empty?
		  	rows[id] = {}
			  row.xpath('td').each_with_index do |td, j|
			  	if j.between?(0,2)
				    rows[id][headers[j]] = td.text.strip
				  end
			  end
			  id = id +1
			end
		end
		rows
	end
	# parse usage 
	def parse_usage(usage, headers)
		is = [0,4]
		id = 0
		usagerows = []
		usage.xpath('//table/tbody/tr').each_with_index do |row, i| 
		  if row != usage.xpath('//table/tbody/tr').first && row != usage.xpath('//table/tbody/tr').last
		  	usagerows[id] = {}
			  row.xpath('td').each_with_index do |td, j|
			  	if is.include?(j)
				    usagerows[id][headers[j]] = td.text.strip
				  end
			  end
			  id = id + 1
			end
		end
		usagerows
	end

	# combine the billing and usage table we parsed
	def combine_rows(rows1, rows2)
		comb_rows= [rows1, rows2].transpose.map { |g,h| g.merge(h) }
		comb_rows
	end

	def last_billing(rows1, rows2)
		comb_rows= [rows1, rows2].transpose.map { |g,h| g.merge(h) }
		puts "The latest billing for 'KYLE WILSON' is"
		puts comb_rows.first
	end

end

# create a object and longin
a = Arcadia.new
a.login

# extract the billing information include: Read Date, Amount, Due Date based on headers
billing_doc = a.filter_form(2)
billing_headers = a.get_table_headers(billing_doc)
billing_rows = a.parse_billing(billing_doc, billing_headers)
# extract the usage information
usage_doc = a.filter_form(4)
usage_headers = a.get_table_headers(usage_doc)
usage_rows = a.parse_usage(usage_doc, usage_headers)
# combine the two tables and output the results
collected_billings = a.combine_rows(billing_rows,usage_rows)
puts "The All billing from 06/15/2015 to 06/14/2016 for 'KYLE WILSON' is:"
puts collected_billings
puts "The latest billing for 'KYLE WILSON' is:"
puts collected_billings.first

# Using Rspec to test code
describe "Arcadia" do
	let(:a) { Arcadia.new.login }
	let(:billing_doc) { a.filter_form(2) }
  let(:billing_headers) { a.get_table_headers(billing_doc) }
  let(:billing_rows) { a.parse_billing(billing_doc, billing_headers) }
  let(:usage_doc) { a.filter_form(4) }
  let(:usage_headers) { a.get_table_headers(usage_doc) }
  let(:usage_rows) { a.parse_usage(usage_doc, usage_headers) }
  let(:collected_billings) { a.combine_rows(billing_rows,usage_rows) }
	describe '.login' do
    it 'should successfully login' do
      expect(a).not_to be_nil
    end
  end
  describe '.get_billing_doc' do
    it 'should include Meter Read Date, Due Date and Amount Bill' do
      expect(a.filter_form(2).xpath('//table/tbody/tr/th').text).to include("Meter Read Date", "Due Date", "Bill Amount")
    end
  end
  describe '.get_usage_doc' do
    it 'should include Usage' do
      expect(a.filter_form(4).xpath('//table/tbody/tr/th').text).to include("Usage")
    end
  end
  describe '.billing_rows' do  	
    it 'should not be nil' do
      expect(billing_rows.first).not_to be_nil
    end
  end

  describe '.usage_rows' do
    it 'should not be nil' do
      expect(usage_rows.first).not_to be_nil
    end
  end

  describe '.combine_rows' do
    it 'should be the latest billing' do
      expect(collected_billings.first["Meter Read Date"]).to include("06/14/2016")
    end
  end

end