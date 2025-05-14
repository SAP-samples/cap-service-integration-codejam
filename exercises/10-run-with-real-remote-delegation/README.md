# Exercise 10 - Run the service with real remote delegation

At the end of this exercise you'll have your main service integrated with a real remote system for the `API_BUSINESS_PARTNER` based customer data you've integrated via [the definitions in a previous exercise](../07-add-cds-definitions/README.md#consider-the-units-of-definition-and-their-relationships).

## Start the CAP server

Finally we're ready. Let's go!

👉 Start the service as you have done before, but with the global `--profile` option specifying the "sandbox" context:

```bash
cds watch --profile sandbox
```

👉 Observe the output - here's a section from the startup log output:

```text
[cds] - connect to API_BUSINESS_PARTNER > odata-v2 {
  url: 'https://sandbox.api.sap.com/s4hanacloud/sap/opu/odata/sap/API_BUSINESS_PARTNER',
  headers: { APIKey: '...' }
}
[cds] - using auth strategy { kind: 'mocked', impl: 'node_modules/@sap/cds/lib/auth/basic-auth' }

[cds] - serving IncidentsService { path: '/odata/v4/incidents', impl: 'srv/incidents-service.js' }
```

While it's nice to see that the CAP server is still serving the `IncidentsService` as we'd expect (in the last log line shown here), it's also heart warming to see the connection to the system that is serving the external service, shown in the first log line. What we're seeing in this line is similar to what we saw when we [tried out a remote call to the mocked service which was running in an external process, in exercise 08](../08-introduce-sap-cloud-sdk/README.md#try-it-out-again), which was this:

```text
[cds] - connect to API_BUSINESS_PARTNER > odata { url: 'http://localhost:5005/odata/v4/api-business-partner' }
```

This time it's different, in two ways:

* the type is `odata-v2` rather than `odata`
* the credentials now also include the APIKey header that will be added to each HTTP request

> Before you wonder, yes, the actual case of "APIKey" is not important. You could have `apikey` instead, for example - the sandbox server doesn't mind.

Note also that even though the `cds` command we used was `watch`, which implies `--with-mocks`, there's no need for the server to mock `API_BUSINESS_PARTNER` because there are details provided for it. There's an external binding! As a reminder, here's the help text for `--with-mocks` that we saw in a previous exercise, this time with the relevant condition highlighted in upper case:

```text
Use this in combination with the variants serving multiple services.
It starts in-process mock services for all required services configured
in package.json#cds.requires, WHICH DON'T HAVE EXTERNAL BINDINGS
in the current process environment.
Note that by default, this feature is disabled in production and must be
enabled with configuration 'features.mocked_bindings=true'.
```

That's also why we don't see any log lines that say something like `mocking API_BUSINESS_PARTNER { path: '/odata/v4/api-business-partner' }`.

👉 Also open up the contents of `~/.cds-services.json` by running `cat ~/.cds-services.json` on the command line in a separate terminal. This now of course only includes information on the provision of the `IncidentsService`:

```json
{
  "cds": {
    "provides": {
      "IncidentsService": {
        "kind": "odata",
        "credentials": {
          "url": "http://localhost:4004/odata/v4/incidents"
        },
        "server": 870
      }
    },
    "servers": {
      "870": {
        "root": "file:///workspaces/cap-service-integration-codejam/incidents",
        "url": "http://localhost:4004"
      }
    }
  }
}
```

## Request customer data

The moment of truth has arrived!

👉 Head over to the list of service endpoints at <http://localhost:4004/>, and choose the `Customers` entity set via <http://localhost:4004/odata/v4/incidents/Customers>.

The response should be similar to what you've seen before, but also different. Different data, like this (heavily reduced for brevity):

```json
{
  "@odata.context": "$metadata#Customers",
  "value": [
    {
      "ID": "1018",
      "name": "Bechtle AG Kriek street"
    },
    {
      "ID": "1710",
      "name": "Inlandskunde DE 80"
    },
    {
      "ID": "1000000",
      "name": "BANK5115"
    }
  ],
  "@odata.nextLink": "Customers?$skiptoken=1000"
}
```

This data is coming directly from the remote system.

👉 Check the log output (whitespace has been added to the URL for better readability):

```text
[odata] - GET /odata/v4/incidents/Customers
>> delegating to remote service...
[remote] - GET https://sandbox.api.sap.com
            /s4hanacloud/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_BusinessPartner
            ?$select=BusinessPartner,BusinessPartnerFullName
            &$orderby=BusinessPartner%20asc
            &$top=1000 {
  headers: {
    accept: 'application/json,text/plain',
    'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8,de;q=0.7',
    'x-correlation-id': 'b9b51f0c91ca849f313ba30db918fcc2'
  }
}
```

### Think about what happened

👉 Spend a couple of moments thinking about the flow here.

* The query that was sent (from your browser) to the CAP server was `GET /incidents/Customers`
* This caused the anonymous function defined as a handler for the `READ` event of the `Customers` entity to be triggered, and the query was received by that function inside the object passed as the argument to the `req` parameter:
    ```js
    this.on('READ', 'Customers', (req) => {
      console.log('>> delegating to remote service...')
      return S4bupa.run(req.query)
    })
    ```
* The query (in `req.query`) was transparently translated into an OData query by the CAP framework
* The constructed OData query was sent to the remote system using the SAP Cloud SDK
* The OData query included a `$select` system query option for `BusinessPartner` and `BusinessPartnerFullName`

## Summary

At this point you have a fully integrated external service wired up with your own service, and you've seen how simple the execution of remote queries is. No manual OData query construction needed, no manual handling of HTTP client configuration like authentication, no response parsing, error handling, issues like hard-wired hostnames and so on.

## Further reading

* [Consuming Services Cookbook](https://cap.cloud.sap/docs/guides/using-services)

---

## Questions

If you finish earlier than your fellow participants, you might like to ponder these questions. There isn't always a single correct answer and there are no prizes - they're just to give you something else to think about.

1. When we [started the CAP server](#start-the-cap-server), why did we observe a difference between the remote system types "odata" and "odata-v2"?

1. If you were to have omitted the `--profile sandbox` option when running `cds watch`, what would have happened?

1. Why was there a `$select=BusinessPartner,BusinessPartnerFullName` in the query made to the remote system?

---

[Next exercise](../11-associate-local-remote-entities/)
