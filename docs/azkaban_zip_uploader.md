# Azkaban Zip Uploader

Uploads Azkaban project files from an S3 location, into Azkaban. So that project config is IaaC.

## Cron scheduling
The zip uploader has the ability to schedule individual flows of an Azkaban project via Cron.
Create a `.json` file with the project name. ie If the Clive Azkaban Project name is `clive`, call your schedule file `clive.json`.

Within your schedule file, you can configure an individual flows CRON and also configure it per environment. CRON must be in Quartz Cron format, for reference [see here](http://www.quartz-scheduler.org/documentation/quartz-2.3.0/tutorials/crontrigger.html) 
The first key of the JSON is the flow name, it's value must be a dictionary, where the key / value are environment and cron.

An example schedule:
```json
{
    "clive": 
        {
        "development": "0 0/5 * * * ? *",
        "qa": "0 0/5 * * * ? *",
        "integration": "0 0/5 * * * ? *",
        "preprod": "0 2 * 3 * ? *",
        "prod": "0 2 * 3 * ? *"
        }
}
```
