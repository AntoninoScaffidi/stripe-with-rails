Product.find_or_create_by!(name: "Sample experience") do |product|
  product.price = 12.00
  product.purchasable = true
end
