Rails.application.routes.draw do
  devise_for :users, controllers: {
    passwords:     'users/passwords',
    registrations: 'users/registrations',
    sessions:      'users/sessions',
  }

  resources :articles, except:[:index]
  
  root 'articles#home'

end
