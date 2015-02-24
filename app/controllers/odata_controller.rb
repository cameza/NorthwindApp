

class OdataController < ApplicationController
	# Standard HTTP Request
	require "net/http"
	require "uri"
	# Needed to use the json library
	require "rubygems" 
	require "json"


	def index
	end

	def supplier
		# Get the productID input by the user in the supplier form
		@productID = params[:productID]
		# Initialize the flag
		@received = false
		# Set the urls needed
		@productsURL = "Products?$format=json"
		@suppliersURL = "Suppliers?$format=json"
		# Create a display service document to parse a url and get the value array
		# of the products & Suppliers table
		productsDoc = DisplayServiceDocument.new
		productValues = productsDoc.parseURL(@productsURL)
		suppliersDoc = DisplayServiceDocument.new
		suppliersValues = suppliersDoc.parseURL(@suppliersURL)
		# Product ID part
		productName = productsDoc.getItem(productValues, "ProductID", @productID, "ProductName") 
		# Suppliers ID part
		supplierID = productsDoc.getItem(productValues, "ProductID", @productID, "SupplierID") 
		# Active/Discontinued part
		active = productsDoc.getItem(productValues, "ProductID", @productID, "Discontinued")
		if active 
			active = "Discontinued"
		else 
			active = "Active"
		end
		# Supplier name -- Use in this case the suppliers table
		companyName = suppliersDoc.getItem(suppliersValues, "SupplierID", supplierID, "CompanyName") 			
		@output = {"companyName" => companyName, "productName" => productName, 
					"supplierID" => supplierID, "active" => active, "companyName" => companyName }
		# Activate the flag when a product ID is received			
		if @productID != nil
			@received = true
		end
	end

	def orders
		#Get the productID input by the user in the supplier form
		productID = params[:productID]
		# Initialize the flag
		@received = false
		# Set the urls needed
		@productsURL = "Products?$format=json"
		@orderDetailsURL = "Order_Details?$format=json"

		# Create a display service document to parse a url and get the value array
		# of the products & orders table
		productsDoc = DisplayServiceDocument.new
		productValues = productsDoc.parseURL(@productsURL)
		orderDetailsDoc = DisplayServiceDocument.new
		orderDetailsValues = orderDetailsDoc.parseURL(@orderDetailsURL)
		# Product ID part
		productName = productsDoc.getItem(productValues, "ProductID", productID, "ProductName") 
		# Orders part
		count = 0
		@output = {"productID"=>productID}
		order = Hash.new
		orderDetailsValues.each do |item|
			if item["ProductID"].to_i == productID.to_i
				totalPrice = item["UnitPrice"].to_i*item["Quantity"].to_i*(1-item["Discount"].to_i)
				count += 1
				order = {item["OrderID"] => totalPrice} 
			end
		end
		@output["count"] = count
		@output["order"] = order
		# Activate the flag when a product ID is received			
		if productID != nil
			@received = true
		end
	end

	def contacts
		#Get the productID input by the user in the supplier form
		productID = params[:productID]
		# Initialize the flag
		@received = false
		# Set the urls needed
		@productsURL = "Products?$format=json"
		@orderDetailsURL = "Order_Details?$format=json"
		@ordersURL = "Orders?$format=json"
		@customersURL = "Customers?$format=json"

		# Create a display service document to parse a url and get the value array
		# of the tables required
		aDoc = DisplayServiceDocument.new
		productValues = aDoc.parseURL(@productsURL)
		orderDetailsValues = aDoc.parseURL(@orderDetailsURL)
		ordersValues = aDoc.parseURL(@ordersURL)
		customersValues = aDoc.parseURL(@customersURL)

		# Orders part
		# Count the number or orders for that product ID
		count = 0
		names = Array.new
		# Get the contact name info for each order
		orderDetailsValues.each do |item|
			if item["ProductID"].to_i == productID.to_i
				count += 1
				ordersValues.each do |order|
					if order["OrderID"].to_i == item["OrderID"].to_i
						customersValues.each do |customer|
							if customer["CustomerID"] == order["CustomerID"]
								if customer["ContactName"].empty? == false
									puts customer["ContactName"]
									names.push(customer["ContactName"])
								end
							end
						end
					end
				end
			end
		end
		@output = {"productID" => productID, "count" => count, "names" => names}
		puts @output
		# Activate the flag when a product ID is received			
		if productID != nil
			@received = true
		end
	end
end

class DisplayServiceDocument
	# Standard HTTP Request
	require "net/http"
	require "uri"
	# Needed to use the json library
	require "rubygems" 
	require "json"
	
	
	# Method to parse a url and return the value array
	def parseURL(table)
		northwind = "http://services.odata.org/northwind/northwind.svc/"
		# Parse the url address
		uri = URI.parse(northwind+table)

		# Will get response.body
		response = Net::HTTP.get(uri)
		# Parse the response
		parsedResponse = JSON.parse(response)
		# Get the value array from the JSON response
		values = parsedResponse["value"]
	end
	# Method to get a specific attribute
	def getItem(array, matchItem, matchValue, returnValue)
		#puts "matchItem " + matchItem
		#puts "matchValue" + matchValue
		#puts "returnValue" + returnValue
		name = ""
		array.each do |item|
			if item[matchItem].to_i == matchValue.to_i
				name = item[returnValue]
				#puts name
			end
		end
		#puts name
		return name.to_s
	end
end
