# Exercise 05 - Add test data for the mocked external service

At the end of this exercise you'll have some test data that will be served for your external service, when you run the CAP server with mocking turned on.

## Add CSV data

You'll have noticed by now in the log output to `cds run` and `cds watch` that at the persistence layer, CSV data is loaded automatically, as long as the location and filenames are as the CAP server expects (remember, convention over configuration is key with CAP). The filenames are made up from the namespace and and entity names - see the link in the [Further reading](#further-reading) section below on providing initial data.

Relevant log output lines for entities in the context of the local (incidents) service look like this:

```text
 > init from db/data/acme.incmgt-Appointments.csv
 > init from db/data/acme.incmgt-Incidents.conversation.csv
 > init from db/data/acme.incmgt-Incidents.csv
 > init from db/data/acme.incmgt-Incidents_status.csv
 > init from db/data/acme.incmgt-Incidents_urgency.csv
 > init from db/data/acme.incmgt-Incidents_urgency.texts.csv
 > init from db/data/acme.incmgt-ServiceWorkers.csv
 > init from db/data/acme.incmgt-TeamCalendar.csv
```

Test data in the form of CSV records can be supplied for mocked external services too. Let's add a CSV file to have some actual data served for our mocked `API_BUSINESS_PARTNER` external service.

👉 Create a new `data/` directory within the `srv/external/` directory, and within that, create a file called `API_BUSINESS_PARTNER-A_BusinessPartner.csv`. One way to do this is on the command line, in the `incidents/` directory:

```bash
mkdir srv/external/data/
touch srv/external/data/API_BUSINESS_PARTNER-A_BusinessPartner.csv
```

At this point you should have a new file ready to add CSV records too. 

👉 Do that now; add these records (including the CSV header record) to the file:

```csv
BusinessPartner;BusinessPartnerFullName
Z100001;Harry Potter
Z100002;Sherlock Holmes
Z100003;Sunny Sunshine
```

## Restart the server

👉 At this point, start or restart the CAP server with `cds watch`:

```bash
cds watch
```

You should now see an additional "init from" line in the log output showing that data has been loaded for the mocked external service, specifically for the `A_BusinessPartner` entity in  the `API_BUSINESS_PARTNER` namespace:

```text
 > init from srv/external/data/API_BUSINESS_PARTNER-A_BusinessPartner.CSV
```

👉 Head back to the browser, open <http://localhost:4004> and select the `A_BusinessPartner` endpoint at <http://localhost:4004/api-business-partner/A_BusinessPartner>. This represents the entity set from the original imported OData service, and is now returned not empty, as before, but with data.

👉 To confirm that there are indeed just three records (from the CSV file), add the OData system query option `$count=true` as a query string parameter to the URL you just used, and you should see output like this:

```json
{
  "@odata.context": "$metadata#A_BusinessPartner",
  "@odata.count": 3,
  "value": [
    {
      "BusinessPartner": "Z100001",
      "Customer": null,
      "Supplier": null,
      "AcademicTitle": null,
      "AuthorizationGroup": null,
      "BusinessPartnerCategory": null,
      "BusinessPartnerFullName": "Harry Potter",
      "TradingPartner": null
    },
    {
      "BusinessPartner": "Z100002",
      "Customer": null,
      "Supplier": null,
      "AcademicTitle": null,
      "AuthorizationGroup": null,
      "BusinessPartnerCategory": null,
      "BusinessPartnerFullName": "Sherlock Holmes",
      "TradingPartner": null
    },
    {
      "BusinessPartner": "Z100003",
      "Customer": null,
      "Supplier": null,
      "AcademicTitle": null,
      "AuthorizationGroup": null,
      "BusinessPartnerCategory": null,
      "BusinessPartnerFullName": "Sunny Sunshine",
      "TradingPartner": null
    }
  ]
}
```

> Many of the properties in the `A_BusinessPartner` entity type have been omitted here for brevity. But this is a good time to point out that any properties which haven't been supplied with data via CSV are still presented, with `null` as their values. 


## Summary

At this point the external service that you imported is now not only mocked, but has data too.

## Further reading

* [Providing initial data](https://cap.cloud.sap/docs/guides/databases#providing-initial-data)
* [$count as a system query option in OData V4](https://github.com/qmacro/odata-v4-and-cap/blob/main/slides.md#odata-v4)

---

## Questions

If you finish earlier than your fellow participants, you might like to ponder these questions. There isn't always a single correct answer and there are no prizes - they're just to give you something else to think about.

1. Is CSV data supplied for the entire external service, or just a single entity within that? What about at the property level within the entity?

---

[Next exercise](../06-mock-separate-process/)
