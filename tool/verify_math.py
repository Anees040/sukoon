#!/usr/bin/env python3
"""Independent verification of Sukoon's pure-Dart math.

Re-implements qaza_estimator.dart, plan_math.dart and qibla_math.dart in
Python. The printed numbers get baked into the Dart unit tests — if the two
independent implementations agree, the formulas are almost certainly right.
"""
import math
from datetime import date, timedelta

LUNAR = 354.367
MONTH = 30.44


def bulugh_offset(lunar_years: int) -> int:
    return round(lunar_years * LUNAR)


def estimate(bulugh, gap_end, female=False, hayd=7, births=0, nifas=40,
             pf=0.0, witr=True):
    gap = max((gap_end - bulugh).days, 0)
    h = gap / MONTH * hayd if female else 0.0
    n = float(births * min(nifas, 40)) if female else 0.0
    obligated = max(gap - h - n, 0.0)
    owed = math.ceil(obligated * (1 - pf))
    types = 6 if witr else 5
    return dict(gap=gap, hayd=round(h, 3), nifas=n, obligated=round(obligated, 3),
                owed=owed, total=owed * types)


print('--- bulugh offsets (days) ---')
print('deemed 15 lunar :', bulugh_offset(15))
print('cautious male 12:', bulugh_offset(12))
print('cautious fem 9  :', bulugh_offset(9))

print('\n--- S1 male, remembered bulugh 2010-01-01, regular 2020-01-01, pf 0 ---')
print(estimate(date(2010, 1, 1), date(2020, 1, 1)))

print('\n--- S2 female, same gap, hayd 7, births 2 (nifas 40) ---')
print(estimate(date(2010, 1, 1), date(2020, 1, 1), female=True, births=2))

print('\n--- S3 male, same gap, pf 0.75 ---')
print(estimate(date(2010, 1, 1), date(2020, 1, 1), pf=0.75))

print('\n--- S4 deemed, birth 2000-03-15, gap to 2026-08-11 ---')
b4 = date(2000, 3, 15) + timedelta(days=bulugh_offset(15))
print('bulugh:', b4)
print(estimate(b4, date(2026, 8, 11)))

print('\n--- S5 cautious female, birth 2000-03-15, pf 0.5, to 2026-08-11 ---')
b5 = date(2000, 3, 15) + timedelta(days=bulugh_offset(9))
print('bulugh:', b5)
print(estimate(b5, date(2026, 8, 11), female=True, pf=0.5))

print('\n--- S6 witr off, S1 inputs ---')
print(estimate(date(2010, 1, 1), date(2020, 1, 1), witr=False))

print('\n--- S7 never negative: bulugh after gap end ---')
print(estimate(date(2030, 1, 1), date(2020, 1, 1)))

print('\n--- S8 female huge deductions never negative: 30d gap, 3 births ---')
print(estimate(date(2020, 1, 1), date(2020, 1, 31), female=True, births=3))


def bearing(lat1, lng1, lat2, lng2):
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dl = math.radians(lng2 - lng1)
    y = math.sin(dl) * math.cos(p2)
    x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl)
    return (math.degrees(math.atan2(y, x)) + 360.0) % 360.0


KAABA = (21.422487, 39.826206)
print('\n--- qibla bearings ---')
for name, (la, lo) in {
    'Islamabad': (33.6844, 73.0479),
    'Karachi': (24.8607, 67.0011),
    'Lahore': (31.5204, 74.3587),
    'Peshawar': (34.0151, 71.5249),
}.items():
    print(f'{name}: {bearing(la, lo, *KAABA):.2f}')

print('\n--- plan math ---')
print('finish days 913 rem / 5 sets :', math.ceil(913 / 5))
print('finish days 913 rem / 10 sets:', math.ceil(913 / 10))
print('minutes 5 sets x 6 types x 5 :', 5 * 6 * 5)

print('\n--- angle delta expectations ---')
for frm, to in [(350, 10), (10, 350), (0, 180), (90, 270)]:
    d = (to - frm) % 360
    if d > 180:
        d -= 360
    print(f'delta {frm} -> {to}: {d}')
