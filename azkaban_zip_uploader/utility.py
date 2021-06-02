import os


def job_schedule_entry(schedule_entries, job_definition_file: str) -> str:
    return next(filter(lambda x: x == job_definition_file.replace(".zip", ".json"), schedule_entries), None)


def job_name(schedule_file_key):
    return os.path.basename(schedule_file_key).replace(".json", "")
