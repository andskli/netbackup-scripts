#!/usr/bin/env python
#
# Just a tiny script that tries to solve the problem of automatically
# symlinking client catalogs in the NBU PD minicatalog, which is a needed
# step when renaming policies/clients from/to upper/lower-case.
#

import os

CATALOGDIR = "/disk/databases/catalog/2"

clients = []

for dir in os.listdir(CATALOGDIR):
    if 'NBU_' in dir:
        pass
    elif '#' in dir:
        pass
    else:
        clients.append(dir)


print clients
