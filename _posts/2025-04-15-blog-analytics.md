---
layout: post
title: "How I Track My Blog’s Analytics with Val Town"
date: 2025-04-15 12:03:36 +0530
categories: Valtown HTTP Analytics Blog Jekyll
doctest: false

---

Random morning thoughts: how many people actually visit this blog? Where do they come from? What if I could just spend a little time to build my own **analytics**?

I used [Plausible](https://plausible.io) Analytics for a while, it's a great Firebase alternative and worth checking out. It has a smooth interface and is easy to set up. However, I realized I don’t need all the features it offers, and the traffic I get is (probably — last time I checked) not huge. So my needs for **analytics** are really simple:

I want to know:

- How many people visit my blog (in the last week, month, year)
- Where they come from (which social media, search engine, etc.)
- Which posts are the most visited

It shouldn't be that hard, right?

## Server Setup

I decided to use [Val Town’s](https://www.val.town/dashboard) free tier to set up an HTTP server backed by a simple SQLite database. **Val Town** is a website where you can write serverless JavaScript functions, with an emphasis on collaboration.

The server basically has two endpoints:

- A **POST** endpoint that registers **events** by writing to a **SQLite** database.
- A **GET** endpoint that returns all the **events** found in the database.

It also serves a [JS script](https://orjpap-bloganalyticsserver.web.val.run/analytics.js). This script gets injected into the **\<head\>** of every page of my blog (you just got injected too) and sends events to the **POST** endpoint.

In order to protect the server from unauthorized access, the only **allowed origin** is my website. Both endpoints are protected by a secret API key. The script is **obfuscated** to make it harder to extract the API key. Finally, serving the script directly from the server allows for easier key **rotation** and updates.


## Events

An event looks like this:

```json
{
    "url": "https://orjpap.github.io/",
    "referrer": "https://www.google.com/",
    "timestamp": "2025-04-15T10:19:48.580Z",
    "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15"
}
```

You can store up to **10MB** in SQLite on the free plan. GPT estimates each row to be around *290–300 bytes*, which means I can probably store about **35k events**. In the very pleasant event of reaching the max limit, I can download my data as JSON, store it somewhere, and then delete and continue tracking or upgrade to a paid tier.

## Viewing the Data

I can directly manage the sqlite database using a very handy val called [sqlite_explorer](https://www.val.town/v/nbbaier/sqlite_explorer). It allows me to run SQL queries and offers a basic UI that gets the job done.

![sqlite-explorer](/assets/images/2025-04-15-blog-analytics.assets/sqlite-explorer.png)

I also made a Swift [script](https://github.com/orjpap/orjpap.github.io/blob/8bbc591d0df3430e839d1c8e801532179b9ec40d/scripts/analytics.swift) to read my analytics through the terminal. It's quite primitive, but it's all I need to check every once in a while.

![1](/assets/images/2025-04-15-blog-analytics.assets/analytics-swift-terminal.png)

## Sharing

That’s pretty much it! I’m really impressed that I pulled this together in less than a day. I’m glad it’s already running and even more glad I’ve already managed to collect some data from real users.

Feel free to fork my Val Town server if you're interested in rolling your own analytics.

<iframe width="100%" height="400px" src="https://www.val.town/embed/orjpap/simpleAnalytics" title="Val Town" frameborder="0" allow="web-share" allowfullscreen></iframe>
