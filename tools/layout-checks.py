#!/usr/bin/env python

# Copyright 2014 OpenStack Foundation
# Copyright 2014 SUSE Linux Products GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import copy
import os
import re
import sys

import yaml

layout = yaml.load(open('zuul/layout.yaml'))


def check_merge_template():
    """Check that each job has a merge-check template."""

    errors = False
    print("\nChecking for usage of merge template")
    print("====================================")
    for project in layout['projects']:
        if project['name'] == 'z/tempest':
            continue
        try:
            correct = False
            for template in project['template']:
                if template['name'] == 'merge-check':
                    correct = True
            if not correct:
                raise
        except:
            print("Project %s has no merge-check template" % project['name'])
            errors = True
    return errors


def normalize(s):
    "Normalize string for comparison."
    return s.lower().replace("_", "-")


def check_projects_sorted():
    """Check that the projects are in alphabetical order per section."""

    print("Checking project list for alphabetical order")
    print("============================================")
    # Note that the file has different sections and we need to sort
    # entries within these sections.
    errors = False
    # Skip all entries before the project list
    firstEntry = True
    last = ""
    for line in open('zuul/layout.yaml', 'r'):
        if line.startswith('projects:'):
            last = ""
            firstEntry = False
        if line.startswith('  - name: ') and not firstEntry:
            current = line[10:].strip()
            if (normalize(last) > normalize(current)):
                print("  Wrong alphabetical order: %(last)s, %(current)s" %
                      {"last": last, "current": current})
                errors = True
            last = current
    return errors

def check_formatting():
    errors = False
    count = 1

    print("Checking indents")
    print("================")

    for line in open('zuul/layout.yaml', 'r'):
        if (len(line) - len(line.lstrip(' '))) % 2 != 0:
            print("Line %(count)s not indented by multiple of 2:\n\t%(line)s" %
                  {"count": count, "line": line})
            errors = True
        count = count + 1

    return errors

def grep(source, pattern):
    """Run regex PATTERN over each line in SOURCE and return
    True if any match found"""
    found = False
    p = re.compile(pattern)
    for line in source:
        if p.match(line):
            found = True
            break
    return found


def check_jobs():
    """Check that jobs have matches"""
    errors = False

    print("Checking job section regex expressions")
    print("======================================")

    # The job-list.txt file is created by tools/run-layout.sh and
    # thus should exist if this is run from tox. If this is manually invoked
    # the file might not exist, in that case pass the test.
    job_list_file = ".test/job-list.txt"
    if not os.path.isfile(job_list_file):
        print("Job list file %s does not exist, not checking jobs section"
              % job_list_file)
        return False

    with open(job_list_file, 'r') as f:
        job_list = [line.rstrip() for line in f]

    for jobs in layout['jobs']:
        found = grep(job_list, jobs['name'])
        if not found:
            print ("Regex %s has no matches in job list" % jobs['name'])
            errors = True

    return errors


def collect_pipeline_jobs(project, pipeline):
    jobs = []
    if pipeline in project:
        # We need to copy the object here to prevent the loop
        # below from modifying the project object.
        jobs = copy.deepcopy(project[pipeline])

    if 'template' in project:
        for template in project['template']:
            # The template dict has a key for each pipeline and a key for the
            # name. We want to filter on the name to make sure it matches the
            # one listed in the project's template list, then collect the
            # specific pipeline we are currently looking at.
            t_jobs = [ _template[pipeline]
                        for _template in layout['project-templates']
                        if _template['name'] == template['name']
                        and pipeline in _template ]
            if t_jobs:
                jobs.append(t_jobs)

    return jobs


def check_empty_check():
    '''Check that each project has at least one check job'''

    print("\nChecking for projects with no check jobs")
    print("====================================")

    for project in layout['projects']:
        # z/tempest is a fake project with no check queue
        if project['name'] == 'z/tempest':
            continue
        check_jobs = collect_pipeline_jobs(project, 'check')
        if not check_jobs:
            print("Project %s has no check jobs" % project['name'])
            return True

    return False


def check_empty_gate():
    '''Check that each project has at least one gate job'''

    print("\nChecking for projects with no gate jobs")
    print("====================================")

    for project in layout['projects']:
        gate_jobs = collect_pipeline_jobs(project, 'gate')
        if not gate_jobs:
            print("Project %s has no gate jobs" % project['name'])
            return True

    return False


def check_mixed_noops():
    '''Check that no project is mixing both noop and non-noop jobs'''

    print("\nChecking for mixed noop and non-noop jobs")
    print("====================================")

    for project in layout['projects']:
        for pipeline in ['gate', 'check']:
            jobs = collect_pipeline_jobs(project, pipeline)
            if 'noop' in jobs and len(jobs) > 1:
                print("Project %s has both noop and non-noop jobs "
                      "in '%s' pipeline" % (project['name'], pipeline))
                return True

    return False


def check_all():
    errors = check_projects_sorted()
    errors = check_merge_template() or errors
    errors = check_formatting() or errors
    errors = check_empty_check() or errors
    errors = check_empty_gate() or errors
    errors = check_mixed_noops() or errors
    errors = check_jobs() or errors

    if errors:
        print("\nFound errors in layout.yaml!")
    else:
        print("\nNo errors found in layout.yaml!")
    return errors

if __name__ == "__main__":
    sys.exit(check_all())
