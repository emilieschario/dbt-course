## Lab 7: Environments, Deployment, and the SDLC

### 1. Set up a new deployment environment

You don't have a deployment environment set up in dbt Cloud for your project yet.

Set up a new deployment environment, using dbt 0.18.1 and have the models build into a schema called production_[first initial + last name]. (This is so your production models don't conflict with each other.)

It's hard to test this without a 'job', so...

<details>
  <summary>👉 Section 1</summary>

  (1) Go to the Home section of dbt Cloud (look in the burger menu at the top left corner.)

  (2) Make sure you're operating in your project. This will be visible in the top navigation bar. If you're not, change the project.

  (3) You should see a prompt in the middle of the page that says "Your account doesn't have any environments yet. You can create a new one now." Click on the button.

  (4) Fill out all the values in the form. The `name` can be whatever you want. The `type` should be deployment. You'll need to fill out your Snowflake credentials at the bottom. The `schema` should be called production_[first initial + last name]. (This is so your production models don't conflict with each other.)

  (5) Click Save in the top right corner.

</details>

### 2. Set up a production job

Set up a job that runs every day at 6am (in your timezone) that does the following:
* Checks your sources aren't stale.
* Tests all your source data
* Uploads seed data
* Runs all your models
* Tests all your models, but not sources

Once you've got the job set up, kick it off manually to make sure everything runs/passes. If it doesn't, push the necessary changes.

<details>
  <summary>👉 Section 2</summary>

  (1) After the prior step, you'll likely have be brough the the homepage for your environment. Click 'New Job' to the right of the screen. If you don't see that buttom, you can go to Jobs in the top left corner menu and create it from there.

  (2) Fill out the page with the necessary information. Your job can be called whatever you would like. Choose the environment you created in the prior step. The `target name` should be `prod`. Add all of the following commands in sequence: `dbt source snapshot-freshness`, `dbt test -m source:*`, `dbt seed`, `dbt run`, and `dbt test --exclude source:*`.

  (3) Change the schedule at the bottom to run at exactly 6am in your timezone. Note that the input is in UTC.

  (4) Save your job and, from the next screen, click 'Run Now' to ensure it's working correctly.
</details>

## Links and Walkthrough Guides

The following links will be useful for these exercises:

* [dbt Docs: dbt Cloud Quickstart](https://docs.getdbt.com/docs/dbt-cloud/cloud-quickstart)
* [Slides from presentation](https://docs.google.com/presentation/d/193oCed_28EstNRv6uClvz40xXeoGTDb8Ixh49Q5eaMI/edit?usp=drive_web&ouid=102844745808883823541)
