#!/usr/bin/env python3

import time
import os
import sys
from subprocess import Popen


def float_str(value):
    rc = str(value).replace('.', ',')
    if ',' in rc:
        if rc[:-1].endswith('000'):
            if '0' * (3 + int(rc[-1])) + rc[-1]:
                rc = rc[:-4]
        while rc[-1] == '0':
            rc = rc[:-1]
        buf = rc.split(',')
        buf[0] += ','
        for i in range(len(buf[1])):
            buf[0] += buf[1][i]
            if i % 3 == 2:
                buf[0] += ' '
        rc = buf[0]
        if rc.endswith(' '):
            rc = rc[:-1]
    if rc.endswith(','):
        rc = rc[:-1]
    buf = rc.split(',')
    buf[0] = list(reversed(buf[0]))
    rc = ''
    for i in range(len(buf[0])):
        rc += buf[0][i]
        if i % 3 == 2:
            rc += ' '
    if rc.endswith(' '):
        rc = rc[:-1]
    buf[0] = list(reversed(rc))
    rc = ''
    for c in buf[0]:
        rc += c
    buf[0] = rc
    rc = ','.join(buf)
    return rc.replace('- ', '-').replace('-', '−')

try:
    while True:
        line = input()
        try:
            cmd = line.lower().split(' ')[0]
            line = line[len(cmd) + 1:].replace(',', '.').replace(':', '.').replace('−', '-')
            if (cmd == '!am') or (cmd == '!pm'):
                line = line.upper().replace('-', '.')
                while '  ' in line:          line = line.replace('  ', ' ')
                while line.startswith(' '):  line = line[1:]
                while line.endswith(' '):    line = line[:-1]
                (_time, _date) = (line.split(' ') + [None])[:2]
                (hour, minute, second) = (_time + '.x.x').split('.')[:3]
                havesec = True
                if minute == 'x':  minute = '0'
                if second == 'x':  (second, havesec) = ('0', False)
                hour = (int(hour) % 12) + (0 if cmd == '!am' else 12)
                havedate = True
                os.environ['TZ'] = 'US/Pacific'
                time.tzset()
                if _date is None:
                    havedate = False
                    _date = time.localtime()
                    year, month, day = _date.tm_year, _date.tm_mon, _date.tm_mday
                else:
                    (month, day, year) = _date.split('.') ## Yepp, this is how Jupiter Broadcasting writes dates numerically
                year, _day = int(year), day
                if year < 1000:
                    year += 2000
                (month, day, minute, second) = [int(x) for x in (month, day, minute, second)]
                _time = time.mktime((year, month, day, hour, minute, second, 0, 0, -1))
                _time = time.gmtime(_time)
                year, month, day = _time.tm_year, _time.tm_mon, _time.tm_mday
                hour, minute, second = _time.tm_hour, _time.tm_min, _time.tm_sec
                havesec = havesec or (second != 0)
                if havedate:
                    months = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Set', 'Oct', 'Nov', 'Dec')
                    print('%02d:%02d%s %04d-(%02d)%s-%02d UTC' % (hour, minute, (':%02d' % second) if havesec else '', year, month, months[month - 1], day))
                else:
                    if (hour == 0) and (minute == 0) and (second == 0) and (day == 2):
                        (hour, day) = (24, 1)
                    print('%02d:%02d%s %sUTC' % (hour, minute, (':%02d' % second) if havesec else '', '' if day == _day else 'next day '))
            elif cmd == '!wtf':
                # this requires the package wtf
                Popen(['wtf'] + line.split(' '), stderr = sys.stdout)
            else:
                line = line.replace(' ', '')
                if   cmd == '!oz':    print('%s US fl. oz = %s ml (ml = cm³ = cc)' % (line, float_str(float(line) * 29.57)))
                elif cmd == '!lb':    print('%s lb = %s kg' % (line, float_str(float(line) * 0.4536)))
                elif cmd == '!lbs':   print('%s lbs = %s kg' % (line, float_str(float(line) * 0.4536)))
                elif cmd == '!inch':  print('%s" = %s cm' % (line, float_str(float(line) * 2.54)))
                elif cmd == '!ft':    print('%s\' = %s dm' % (line, float_str(float(line) * 3.048)))
                elif cmd == '!yard':  print('%s yard = %s m'  % (line, float_str(float(line) * 0.9144)))
                elif cmd == '!mile':  print('%s mile = %s km' % (line, float_str(float(line) * 1.609)))
                elif cmd == '!length':
                    line = line.replace('\'\'', '"').replace('\'', '\' ')
                    if line.endswith(' '):
                        line = line[:-1]
                    cm = 0
                    for part in line.split(' '):
                        if part.endswith('\''):
                            cm += float(part[:-1]) * 30.48
                        elif part.endswith('"'):
                            cm += float(part[:-1]) * 2.54
                        else:
                            cm = None
                            break
                    if cm is None:
                        continue
                    print('%s = %s cm' % (' '.join(line), float_str(cm)))
                elif cmd == '!°f':
                    delta, base = float(line) * 0.56, -17.78
                    print('Temperature: %s °F = %s °C  |  Heat: %s °F = %s °C' % (line, float_str(base + delta), line, float_str(delta)))
        except:
            pass
except:
    pass

