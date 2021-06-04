from unittest import TestCase

import utility
from utility import job_schedule_entry


class UtilitySpec(TestCase):

    def test_should_return_entry_if_match_found(self):
        job_definition_file = "parent/3.zip"
        schedule_entries = ["parent/1.json", "parent/2.json", "parent/3.json", "parent/4.json"]
        schedule_entry = job_schedule_entry(schedule_entries, job_definition_file)
        self.assertEqual(schedule_entry, "parent/3.json")

    def test_should_return_none_if_no_match_found(self):
        job_definition_file = "parent/5.zip"
        schedule_entries = ["parent/1.json", "parent/2.json", "parent/3.json", "parent/4.json"]
        schedule_entry = job_schedule_entry(schedule_entries, job_definition_file)
        self.assertIsNone(schedule_entry)

    def test_should_return_correct_job_name(self):
        key = "grandparent/parent/jobname.json"
        job_name = utility.job_name(key)
        self.assertEqual("jobname", job_name)
