# -*- coding:utf-8 -*-

"""Формирование файла host из файла *.tfstate"""

import pathlib
import os
import json
import yaml
from functools import reduce
import re
__path__ = pathlib.Path(__file__)

tfstate = []
p = pathlib.Path('.')
for f in p.rglob('*.tfstate'):
    # костыль: купирует файлы из .history
    if re.match(r'^\.*', str(f)).group(0):
        continue
    tfstate.append(f.absolute())

hosts = {}

for path in tfstate:
    with open(path, "r") as json_file:
        js_ob = json.load(json_file)
        for k, v in js_ob.get('outputs').items():
            if isinstance(v.get('value')[0], list):
                # При создании однотипных серверв с использованием count генерируется список списков
                hosts.update({k: reduce(lambda x, y: x + y, v.get('value'))})
            else:
                hosts.update({k: v.get('value')})
ls = []
for k, v in hosts.items():
    # фильтрация local ip, убирает IPv6 и не принадлежащие 10.х.х.х
    l = [ip for ip in v if '10.' in ip]
    ls.append("[{}]\n{}\n".format(k, '\n'.join(l)))

with open('terraform_inventory', 'w') as f:
    f.write('\n'.join(ls))
