#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from __future__ import absolute_import, division, print_function
import os, sys
from github import Github


TOKEN = os.environ['GH_TOKEN']
ORG = os.environ.get('ORG', 'corpusops')


def activate_workflows(repo):
    for wf in repo.get_workflows():
        wf.create_dispatch(repo.default_branch)


def main():
    g = Github(TOKEN)
    org = g.get_organization(ORG)
    for repo in g.search_repositories('org:corpusops topic:docker-images'):
        activate_workflows(repo)

if __name__ == '__main__':
    main()

# vim:set et sts=4 ts=4 tw=120:
