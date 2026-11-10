---
title: Budget model
summary: "How tokenplan turns weekly usage into today's budget, pace, stretch and carry, with the exact formulas"
kind: engineering
status: active
updated: 2026-11-10
---

# Budget model

All quantities are percentages of the weekly limit. The model's goal is to finish the week at
`100 - reserve` used, spending evenly across the hours the user actually works.

## Work hours

`general.day_start` and `general.day_end` define a work day. When `day_end` is earlier than
`day_start` the day crosses midnight (the default is 08:00 to 01:00). Only time inside work hours
counts; sleeping hours neither earn nor consume budget.

A **work day** runs from one `day_start` to its `day_end`. Outside work hours, "today" means the
next work day.

## Definitions

Let `W(a, b)` be the number of work hours between `a` and `b`, `used` the weekly percentage used,
`reset` the weekly reset, and `week_start = reset - 7 days`.

| Quantity | Formula | Meaning |
|---|---|---|
| remaining | `max(0, 100 - reserve - used)` | Spendable until reset |
| rate | `remaining / W(now, reset)` | Even spend per work hour from now on |
| left today | `rate × W(now, end of today ∧ reset)` | Budget still available today |
| spent today | `used - used at start of today` | From the history snapshot at or before `day_start` |
| today budget | `spent today + left today` | |
| expected now | `(100 - reserve) × W(week_start, now) / W(week_start, reset)` | Where an even pace would be |
| pace (bank) | `expected now - used` | Positive = ahead, negative = behind |
| stretch | `remaining - share × rate × W(end of today, reset)` | Most that can be spent today while later work hours keep `share` of the even rate |
| tomorrow on plan | `rate × W(tomorrow)` | |
| tomorrow if stop now | `remaining / W(end of today, reset) × W(tomorrow)` | |

`share` is `general.min_future_day_share` (default 0.5).

If the weekly reset falls before the next work day, the report says to use everything today and
omits stretch and carry.

## Carry-over

Nothing is stored as "carried". Because `rate` is recomputed from `remaining` on every run, any
budget not spent today is automatically spread across the remaining work hours, and overspending
lowers every later day equally.

## 5h window

For an active window the report suggests a weekly spend inside it of
`min(left today, rate × W(now, window reset) + max(bank, 0))`.

tokenplan also learns how much weekly usage one full 5h window costs. It sums `Δweekly` and
`Δwindow` over consecutive snapshot pairs that sit in the same weekly and 5h window, and shows
`Δweekly / Δwindow` once the summed window movement reaches 20 points.

## Traffic light (`tokenplan line`)

| Light | Condition |
|---|---|
| 🟢 | spent today ≤ 80% of today's budget, or spent today unknown |
| 🟡 | 80% < spent ≤ 100% |
| 🔴 | spent today > today's budget |

The pace arrow is ▲ (green) when `bank ≥ 0`, ▼ (red) otherwise. The window percentage is green
below 70, yellow from 70, red from 90.

## Limits of the model

- **Spent today needs history.** Without a snapshot at or before `day_start`, spent today is
  unknown and only "left today" is shown.
- **Even pacing is the only strategy.** It does not model weekday versus weekend or heavier days.
