---

layout: post
title:  "Podfast: a Podcast Discovery App"
date:   2019-05-02 21:03:36 +0530
categories: Product Design Swift iOS

---

I remember my mother's dissapointment when she first realised that she can't listen to the radio through her new iPhone. It made sense to me. There was a built-in app called [Podcasts](https://apps.apple.com/us/app/apple-podcasts/id525463029) that you could listen to podcasts through it. Generation Z's complete lack of interest for the radio has had already signaled the start of a new era. Podcasting, once an obscure method of spreading audio information, had become a recognized **medium** for distributing audio content.

When old mediums get replaced by new ones, some features of the old medium are dropped or do not serve a purpose in the new medium. Podfast was inspired by the process of discovering new radio stations by **scanning** through the FM/AM frequencies. A process so joyous and adventurous - at least to some people -  that there's even a hobby for it, called [DXing](https://en.wikipedia.org/wiki/DXing). My idea was that the value of radio discovery could be far greater than just inducing nostalgic feelings to users (creating a typewriter app for example). Since ideas transcend mediums, its **essence** could be brought into the Podcast era and even be expanded on.

The three main characteristics that define the radio discovery process are:

1. **Chance:** In case you are not tuning in on time for your favourite program, there is always chance involved in what program you will tune in and also of its elapsed time.
2. **Audio Cues**: instead of visual cues. Even though you can see which frequency corresponds to that specific position of the knob, only the audio provides you with information about whether you are going to like what you are hearing or not.
3. **Locality**: When you move to another country or region, you can tune in to different stations.

## Implementation

To get started, at the top level, I described what I was trying to build as a simple **user story**:

> As a listener I want to discover podcasts by scrolling while listening to them

This is pretty much it. This single user story had since sprawled many more stories, tasks, sub-tasks etc. These substories revolved around the three main characteristics described above. The process was: (a) think of a scenario (b) write code that implements it (c) evaluate the value it adds for the user (d) integrate it into the app. That's how I quickly made an iOS app **prototype** implementing this user story with local podcast audio files and just a [UISlider](https://developer.apple.com/documentation/uikit/uislider).

<video controls width="320" height="576">
  <source src="/assets/images/2019-14-20-podfast.assets/podfast_early_prototype.mp4">
Your browser does not support the video tag.
</video>

The next step was to use some real **data sources**. I turned to [iTunes RSS Feed Generator](https://rss.itunes.apple.com/en-us), a publicly acessible API which returns a [JSON file](https://rss.itunes.apple.com/api/v1/gr/podcasts/top-podcasts/all/100/explicit.json) with the Top 100 Podcasts in different regions, updating almost every week. After collecting this data I had to jump through some hoops - I will not bore you with the details - to get the metadata for each podcast (XML RSS feed parsing anyone? 😁) but thankfully, the podcast RSS feed tags are well standardized in order to get parsed by iTunes, Spotify etc.

At this point, I realised that the less the app's core logic knows about the **specifics** of the various data sources, the better. To achieve this separation I spent some weeks researching the most common app architecture patterns and ended up re-writing my hacky/scripty view controller logic using something very similar to [Viper](https://www.objc.io/issues/13-architecture/viper/) and [Uncle Bob's clean architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) but not exactly it. For those of you who are interested have a look at the folder called [Use Cases](https://github.com/orjpap/podfast/tree/master/PodFast/Use%20Cases/Discovery) and let me know what you think (I believe I might have commited over-abstraction crimes). Anyway, there was a clear goal behind it: to be able to **switch data sources** on a whim, without having to re-write half of my app. That have proved to be very valuable when a remote configuration feeding podcast data was added.

I also noticed that podcasts can be organised **by category** and that was pretty neat, since such a minimal visual cue is not enough to distract the user from **listening**. Finally, I replaced the slider with a [UICollectionView](https://developer.apple.com/documentation/uikit/uicollectionview) to display the category names and wrote some simple collision logic:

<video controls width="320" height="576">
  <source src="/assets/images/2019-14-20-podfast.assets/podfast_early_prototype2.mp4">
Your browser does not support the video tag.
</video>

That was the **prototype** I showed to visual artist/writer Vasia Bakogianni, also known as [@kroutsef](https://www.kroutsef.com) and asked her to work as a **graphic designer** for the app. She accepted and we got straight to work. After a few interesting talks, brainstorming sessions and design iterations she came up with the **logo**:

<img src="/assets/images/2019-14-20-podfast.assets/podfast_logo.PNG" alt="podfast_logo" style="zoom:50%;" class ="center"/>

Vasia not only worked as a designer for the project, but since she is also an avid podcast listener she provided valuable feedback on the user experience, as well as hours of interesting conversation topics. After a **short break**, working on different projects, we got back and decided to push towards a release with a strict release date. Since we have done a lot of groundwork and the concept was already solidified, we finalised the **design** shortly after:

![design_screenshot](/assets/images/2019-14-20-podfast.assets/design_screenshot.png)

From the software's perspective we agreed on a **subset** of features that will be included in the release. A short of minimum viable product (**MVP**) approach, where before making a significant time and effort investement we set out to release the product to the users and then feed their input back into the process of development.

On to the big release, I realised that since there is **streaming** involved and loading times can range from seemingly instant to a "slower than death from natural causes" experience we needed a way to indicate the **buffering state**. We decided to go with something different than the estabilished spinner/loader pattern and use **radio static sounds**. The current, simplistic implementation plays a static sound sample when [AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer) is [having a rough time](https://github.com/orjpap/podfast/blob/120ef148529dfffed1151919402ca0022014a85d/PodFast/Use%20Cases/Discovery/AudioPlayer.swift#L118-L188) with buffering. There is definitely room for improvement by introducing **procedural sound design** to this concept. Spinners are the ultimate playground for graphic designers, let's also give sound designers the opportunity to indicate **loading states**.

<video controls width="320" height="576">
  <source src="/assets/images/2019-14-20-podfast.assets/streaming_static.mp4">
Your browser does not support the video tag.
</video>

Over the period of one week, and a few micro features later, some of which are:

1. Categories are sorted by most listened
2. A listen is defined as 1 minute of listening
3. Podcast details appear after 30 seconds of listening to a podcast, in order to encourage the listener to pay attention to the audio.
4. The episde seek time is relative to the app's start time.
5. Curated podcast sources can by dynamically added to the data set. Thanks to [Firebase Remote Configuration](https://firebase.google.com/docs/remote-config)

We finally had our **1.0 release**!

![podfast_gif](/assets/images/podfast_portfolio_halfsize_15.gif)

## Where to next?

You can download the app for free on the App Store and give it a try.

[<img src="/assets/images/download_on_the_app_store.svg" class="appstoreDownload">](https://apps.apple.com/us/app/podfast/id1507685149?ls=1)

Our users have done a great job of sharing their feedback so far. We will shortly release an update including improvements informed by their suggestions. We would really love to hear your **feedback** on the app. [Send us an email](mailto:orjpap@gmail.com) or get in touch on Twitter [@orjpap](https://twitter.com/OrestisPapadop8), [@kroutsef](https://twitter.com/vasiabakogianni). Also, feel free to share with us your favourite podcasts and what category they belong to so that we can add them to our collection.

There is a lot to learn and improve upon, there will be further optimisation to the **streaming logic**, **sound design** and **visuals** of the app. We will also introduce the notion of **locality**. Instead of just using the US Top 100 and our curated podcasts, you will be able to get podcasts that are famous in your country.

An **Android app** is in the making by [Petros Koutsokeras](https://github.com/Pkoutsokeras)

The **source code** is freely available and can be found on [Github](https://github.com/orjpap/podfast), I'm open to discussions about implementation/architecture of the app and points that can be improved.

To finish, I will quote Vasia's carefully crafted words:

> Podfast is, after all, not a digital radio simulation that aspires to send you on a nostalgia trip. It is a tool that re-establishes the trust in a carefully selected bunch of cultural products picked by the users themselves without strain.
