json.array!(@excel) do |excel|
  json.extract! excel, :id
  json.url admin_general_settings_url(excel, format: :json)
end