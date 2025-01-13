---
title: Deleting <span>Massive S3 Buckets</span> the Easy Way
title_safe: Deleting Massive S3 Buckets the Easy Way
highlight: red
pack: duotone
icon: bucket
draft: false
date: 2021-12-04
category: Platform Engineering
tags:
  - aws
  - devops
  - cost-optimisation
---
I'm in the middle of decommissioning a service at the moment and I have to do the typical process of performing final snapshots and cleaning up extant resources. It's incredibly tedious, so let's walk through it.

<!--more-->

For this particular service, we have an  [ETL](https://en.wikipedia.org/wiki/Extract,_transform,_load)  process that stores raw data points for downstream ingestion by some other... thing. Anyway, the storage mechanism for this is a cross-region replicated S3 bucket containing just over 10 _million_ objects.

![](image-1.png)

All associated buckets and objects must be deleted. 😬

Have you ever had to delete a bucket with this many objects? Not exactly straight-forward. Even by AWS standards.
## What's the problem? 
As you may or may not know, you can't delete a bucket that still contains objects. For smaller buckets, this isn't much of an issue as you can saunter on over to the "empty bucket" screen. This will take you to a confirmation interstitial where you have to sit and wait until the deletion process finishes. Though, you had better not close that tab unless you want to start the process all over.  

![](image-2.png)

Not exactly a feasible solution for our use case. No, for larger buckets there really is only one pragmatic solution.
## Lifecycle Policies! 
You may have noticed the tone of this article as being somewhat snarky. Well, that's because what follows shouldn't be nearly as convoluted as it is. This process should be a single button with a confirmation step where the work is done asynchronously.

That being said, I know better than to question another team's design decisions. Who knows what weirdness they encountered during implementing this functionality. In all fairness, they do provide the mechanisms necessary drop millions, or even billions, of objects. The main concern is it's just not at all intuitive.

So, let's get to it! 🦾
### Expire those objects! 
Alright, we're going to have to perform the following steps for the first policy:
1. Expire all current objects.
2. Permanently delete all non-current versions of objects.
3. Delete expired object delete markers.  

First and foremost, give this policy and name and confirm your intent:

![](image-3.png)

Select the following actions. We will need to select the last option in the list, but due to conflicting settings you will have to add it in separate, secondary, lifecycle policy:  

![](image-4.png)

Set the following option to `1` day:

![](image-5.png)

Again, set this option to `1` day as well. Unfortunately, this is the lowest value you can select. You also have the option to specify how many versions of each object to keep. This is only really relevant if you have object versioning activated for this bucket, but you're going do nuke it all, so just go ahead and leave this blank:

![](image-6.png)

Look at you! All done except looking over your work and saving your new lifecycle policy: 

![](image-7.png)

### Delete those objects!
A secondary policy is necessary to _delete_ the objects you've just told AWS to expire. Begin the process by clicking the `Create lifecycle rule` button and performing the first step from the previous policy:

![](image-8.png)

Next, you'll select the last action in the list:

![](image-9.png)

Select the options to delete all expired objects. Optionally, you can also delete impartial uploads older than `1` day as well. 

![](image-10.png)

And that's it! Click `Save` and view the summary screen. It should look similar to this:

![](image-11.png)

## And now... we wait. 
It will probably take an additional day for all pre-existing objects to be marked as "expired". Next, AWS will trigger the lifecycle policies at 12am UTC. Depending on the size of your bucket, it could possibly take several days to empty. Just go on an extended ☕️ break.

*Something to keep in mind is that you will not be charged for storage that has been marked as expired while AWS empties the associated bucket.*
## And that's that! 
Look, this works. But, it isn't exactly intuitive. In my opinion, you shouldn't have to google "how to empty large S3 bucket" or even go out of your way to create these policies. Ideally, this would all be neatly abstracted away from you and handled with a single button click and a confirmation interstitial ( one that you can walk away from ). 

Anyway, it is what it is. I'll keep checking back over the next few days to chase up its progress.

Hope this helped! Happy hacking! 🤘
## Several days later... 
Ok, it's been a few days and we're finally seeing progress on one of the buckets in question: 

![](image-12.png)

All it takes is a little bit of patience.  