---

layout: post
title:  "Automatic Swift Tests for Jekyll Websites"
date:   2020-05-04 21:03:36 +0530
categories: Jekyll Swift Testing
doctest: true

---

Reading through last week's [iOSDevWeekly](https://iosdevweekly.com) I came across [Doctest](https://github.com/SwiftDocOrg/DocTest?utm_campaign=iOS%2BDev%2BWeekly&utm_medium=web&utm_source=iOS%2BDev%2BWeekly%2BIssue%2B454), an exciting new project that aims to make Swift documentation **testable**.

The idea is, you can run `swift-doctest` giving it a bunch of .swift files and then it **evaluates** code blocks in your documentation, returning test results for the given conditions.

It turns out that you can run `swift-doctest` on **Markdown** files too. What if, we could inject a nice little `swift-doctest` every time jekyll renders our static website? That way we can **test codeblocks** in blog posts and even get it done **automatically on every build**.

## Install DocTest

Via Homebrew:

```bash
$ brew install swiftdocorg/formulae/swift-doctest
```

Or Manually:

```bash
$ git clone https://github.com/SwiftDocOrg/DocTest
$ cd DocTest
$ make install
```

## Jekyll Hook

*note: these are my first 6 lines of Ruby, please be gentle with me*

```ruby
# Put this in a file called swift-doctest.rb on a _plugins folder in your blog root foolder
Jekyll::Hooks.register :posts, :pre_render do |post|
	if post.data['doctest'] == true
		value = %x( echo;echo 'swift-doctest for #{post.path}';swift-doctest #{post.path}; echo;)
		puts value
	end
end
```

This [Jekyl Hook](https://jekyllrb.com/docs/plugins/hooks/) runs every time your site is built, **before** the .md files get rendered to .html files. I put it at this point so that I can do something more sophisticated in the future by probably injecting some html to show me the failed test results.

In order to enable swift-doctest for a post, add `doctest: true` to the post's front matter.

## Take it for a spin

Start a codeblock with **\`\`\`swift doctest** and then, add an annotation in the format `=> (Type) = (Value)`, to test the expected type and value of the expression:

```swift
struct User {
	let name: String
}

let user = User(name: "Foo")
let anotherUser = User(name: "Bar")
user.name == anotherUser.name // => Bool = true
```

Now if you run `bundle exec jekyll serve` to build and serve your site, the terminal will print a failed test in the [TAP format](https://testanything.org)

```bash
...

swift-doctest for <path_to_your_blog>/_posts/<blog_post_filename>.md
TAP version 13
1..2
not ok 1 - `user.name == anotherUser.name` produces `Bool = false`, expected `Bool = true`
  ---
  column: 37
  file: <path_to_your_blog>/_posts/<blog_post_filename>.md
  line: 6
  ...
  
...
```

Nice! If you just change the example to:

```swift doctest
struct User {
	let name: String
}

let user = User(name: "Foo")
let anotherUser = User(name: "Bar")
user.name == anotherUser.name // => Bool = false
```

And just save the file, you will see:

```bash
...

swift-doctest for <path_to_your_blog>/_posts/<blog_post_filename>.md
TAP version 13
1..1
ok 1 - `user.name == anotherUser.name` produces `Bool = false`
  ---
  column: 36
  file: <path_to_your_blog>/_posts/<blog_post_filename>.md
  line: 6
  ...
  
...

```

## Conclusion

That's all you need in order to enable testing for your Swift codeblocks in your Jekyll site!

Keep your eyes peeled for further updates to the very promising [Doctest](https://github.com/SwiftDocOrg/DocTest?utm_campaign=iOS%2BDev%2BWeekly&utm_medium=web&utm_source=iOS%2BDev%2BWeekly%2BIssue%2B454) since it's still on its early days.

Feel free to [contact me](mailto:orjpap@gmail.com) or tweet to me on [Twitter](https://twitter.com/OrestisPapadop8) if you have any additional tips or feedback.

Thanks!

