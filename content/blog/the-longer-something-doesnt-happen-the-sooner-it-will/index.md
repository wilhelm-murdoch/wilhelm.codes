---
title: The Longer <span>Something Doesn't Happen</span>, the Sooner it Will
highlight: orange
pack: duotone
icon: fire
featured: true
draft: false
date: 2024-01-27
category: Platform Engineering
comments: true
tags:
  - devops
  - sre
  - chaos-engineering
---
This is often referred to as the "[Mean Time Between Failures (MTBF)](https://en.wikipedia.org/wiki/Mean_time_between_failures)" in the context of Site Reliability Engineering. It's a somewhat counterintuitive concept that highlights the fact that failures or incidents tend to occur when you least expect them, especially if you haven't experienced one for a while. While it may sound paradoxical, there is some reasoning behind it.

<!--more-->

## Accumulation of Underlying Issues

Over time, systems and processes can accumulate small issues, technical debt, or unnoticed problems. These issues can build up, leading to a higher likelihood of a significant failure or incident occurring as time goes on.

## Complacency and Reduced Vigilance

When a system or service has been running smoothly for an extended period, teams may become complacent and less vigilant. They might not be as proactive in monitoring, testing, and maintaining the system, which can increase the risk of failure.

## Evolving Environments

As technology and business environments evolve — as they inevitably do in our space —, the context in which a system operates also changes. What was once a stable and reliable configuration may no longer be suitable, leading to unexpected issues or failures when the system is finally pushed to its limits.

## Regression to the Mean

[The law of large numbers](https://en.wikipedia.org/wiki/Law_of_large_numbers) suggests that over time, events tend to revert to their average or "mean" frequency. If you've experienced an unusually long period without incidents, statistics may suggest that you're due for one soon, just as a run of heads in a coin toss doesn't make tails any less likely on the next toss.

## Maintaining Awareness

{{< blockquote "The price of <s>freedom</s> stability is eternal vigilance." "Ancient Klingon Proverb ( probably )" >}}

### Mitigation Strategies

Recognize the importance of proactively addressing issues before they accumulate. This involves regular monitoring, capacity planning, load testing, and maintenance to reduce the likelihood of a sudden failure.

### Risk Management

Focus on identifying and managing risks, even during periods of relative stability. They plan for various failure scenarios and aim to minimize their impact through redundancy, graceful degradation, and fault-tolerant design.

### Continuous improvement

Promote a culture of continuous improvement, encouraging teams to learn from past incidents, conduct post-mortems, even live-fire exercises and apply those lessons to prevent similar issues in the future.

### Metrics & Monitoring

Use metrics and monitoring tools to maintain a vigilant eye on system health and performance. They set thresholds and alarms to detect anomalies early, regardless of how long it's been since the last incident.

At any given point your production workloads may be operating under any number of unknown failure modes. Things break; it's inevitable. Adjust your expectations accordingly and build around this fact.

## In Conclusion

The idea that the longer something doesn't happen, the sooner it will is a *reminder* of the importance of vigilance, proactive maintenance, and risk management not only in site reliability engineering, but software engineering as a whole.

This may not be a deterministic law as it highlights the tendency for issues to accumulate over time if not addressed, making it crucial to maintain a robust and resilient system.