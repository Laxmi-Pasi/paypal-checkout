class OrdersController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :paypal_init #, :except => [:index]
  def index
    if Order.any?
      request = PayPalCheckoutSdk::Orders::OrdersGetRequest::new(Order.last.token)
      @response = @client.execute(request) 
    end
  end 
  def create_order
    # binding.pry
    # PAYPAL CREATE ORDER
    price = '499.00'
    request = PayPalCheckoutSdk::Orders::OrdersCreateRequest::new
    request.request_body({
      :intent => 'CAPTURE',
      :purchase_units => [
        {
          :amount => {
            :currency_code => 'USD',
            :value => price
          }
        }
      ]
    })
    # binding.pry
    begin
      response = @client.execute request
      order = Order.new
      order.price = price.to_i
      order.token = response.result.id
      if order.save 
        return render :json => {:token => response.result.id}, :status => :ok
      end
    rescue PayPalHttp::HttpError => ioe
      # HANDLE THE ERROR
    end
  end
  def capture_order
    # PAYPAL CAPTURE ORDER
    request = PayPalCheckoutSdk::Orders::OrdersCaptureRequest::new params[:order_id]
    # binding.pry
    begin
      response = @client.execute request
      order = Order.find_by :token => params[:order_id]
      order.paid = response.result.status == 'COMPLETED'
      if order.save
        return render :json => {:status => response.result.status}, :status => :ok
      end
    rescue PayPalHttp::HttpError => ioe
      # HANDLE THE ERROR
    end
  end

  private
  # @client available in our create_order and capture_order methods.
  def paypal_init
    client_id = 'AfLOwpfasi3e8fgpbsH2piZILP5t4-cV_1baCz6-g7Si97exDwPxVLofLQsNnAbVMeEpZmEqLmwLvwgS'
    client_secret = 'EMNBt5aJF-eURZOg6ZKGwNEqk7fDc9njHfTgfxW7nP_SNJYihIOetSPtH0KqJuVHj9d1kN_SumTUqKp5'
    environment = PayPal::SandboxEnvironment.new client_id, client_secret
    @client = PayPal::PayPalHttpClient.new environment
  end
end
