Rails.application.routes.draw do
  post '/currencies/configure', to: 'currencies#configure'
  get '/currencies/:date', to: 'currencies#index'
  get '/currencies', to: 'currencies#index'
end
