require 'google_drive'
require 'httparty'
require 'rexml/document'

class CurrenciesController < ApplicationController
  def index
    date = params[:date] #call the BNR endpoint to get the currencies for the date specified in the params
    response = HTTParty.get("https://www.bnr.ro/nbrfxrates.xml?date=#{date}")
    xml_data = response.body #get the response body
    document = REXML::Document.new(xml_data) #parse the response body as XML
    cube_element = document.elements['DataSet/Body/Cube'] #get the Cube element from the XML

    currencies = {} #create a hash to store the currencies and their rates
    cube_element.elements.each('Rate') do |rate| #iterate through the Rate elements
      currency = rate.attribute('currency').value #get the currency attribute from the Rate element
      rate_value = rate.text #get the rate value from the Rate element
      currencies[currency] = rate_value #add the currency and rate to the currencies hash
    end

    enabled_currencies = CurrencyConfiguration.where(enabled: true).pluck(:currency_name)
    save_to_google_drive(currencies, enabled_currencies)

    render json: currencies #return the currencies as JSON

  end

  def configure
    currency = params[:currency] #get the currency from the params
    enable = params[:enable] == 'true' #get the enable value from the params, enabled by default
    config = CurrencyConfiguration.find_or_initialize_by(currency_name: currency) #find or initialize the currency config from the db
    config.update(enabled: enable) #update the currency config in case it exists or create it if it doesn't
    if config.save
      render json: { message: "Currency config updated: #{currency} = #{enable}" } #return a success message
    else
      render json: { error: "Failed to update currency config" }, status: :unprocessable_entity #return an error message
    end
  end

  private

  def save_to_google_drive(currencies, enabled_currencies) #define the save_to_google_drive method
    ENV['google_drive_key'] = 'D:\Ruby31-x64\bnr-endpoint-config.json' #set the Google Drive API key
    session = GoogleDrive::Session.from_service_account_key(ENV['google_drive_key']) #create a session with the Google Drive API
    spreadsheet = session.create_spreadsheet("Currencies Parity") #create a spreadsheet named Currencies Parity
    worksheet = spreadsheet.worksheets[0] #get the first worksheet from the spreadsheet

    #write headers
    worksheet[1, 1] = 'Currency'
    worksheet[1, 2] = 'Rate'

    #write currency data
    currencies.each_with_index do |(currency, rate), index|
      if enabled_currencies.include?(currency) #check if the currency is enabled in the db
        row = index + 2
        worksheet[row, 1] = currency
        worksheet[row, 2] = rate #write the currency and rate to the worksheet
        end
    end
    worksheet.save #save the worksheet

    # Add the file to the specified folder
    folder = session.collection_by_url('https://drive.google.com/drive/folders/190oUoprjSrfJmi3rSr1fJDtzLzu0uZaV?usp=share_link') #get the folder by URL
    folder.add(spreadsheet) #add the spreadsheet to the folder in the google drive

  end

end



