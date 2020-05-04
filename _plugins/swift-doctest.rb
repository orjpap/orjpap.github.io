Jekyll::Hooks.register :posts, :pre_render do |post|
	if post.data['doctest'] == true
		value = %x( echo;echo 'swift-doctest for #{post.path}';swift-doctest #{post.path}; echo;)
		puts value
	end
end