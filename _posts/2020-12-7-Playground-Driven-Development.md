---
layout: post
title:  "Pragmatic Playground Driven Development (Part 1)"
date:   2020-12-07 10:03:36 +0530
categories: Swift Xcode Playgrounds Frameworks
doctest: true
hidden: true
---

Using Xcode Playgrounds speeds up your development cycle by reducing compile times. You can make changes to a view, hit compile and view the change in seconds. However, adding Playgrounds that instantiate controllers from your application can be frustrating.

Anything in an App Target is not visible to the playground because App Targets do not define a module. A module is defined bla bla.

That's where frameworks come to play

What you gain from modularising your application using frameworks:

* Dependencies become immediately apparent, pushing your to think about designing dependencies. It's important to <u>care</u> about dependencies. The better you separate your code from its dependencies the more testable, readable, maintainable it becomes.
* Shorter build times when you make changes to a module. Xcode needs to compile only that module.
* Code reuse in different projects and easier integration.
* Provide clearer interfaces and better encapsulation. The framework only exposes what's needed

All of this with minimum overhead.

What you gain from using Playgrounds:

* Your View Controllers will need to have managed dependencies for Playgrounds to make sense. To be able to load a View Controller in isolation means that it's well set up for <u>tests</u>.

from the fine gents over at [Point Free](https://www.pointfree.co/episodes/ep21-playground-driven-development). Their video introduces their way of using Playgrounds in their everyday development. This blog series provides some extra tips learnt the hard way in development

And even when it becomes clear, Playgrounds crash and will crash and unfortunately most of the times without any useful debugging information since Playgrounds run using the [Swift REPL](https://developer.apple.com/swift/blog/?id=18) (more on this on part 2).



