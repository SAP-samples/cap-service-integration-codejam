# Exercise 10 - Run the service with real remote delegation

At the end of this exercise you'll have your main service integrated with a real remote system for the `API_BUSINESS_PARTNER` based customer data you've integrated via [the definitions in the previous exercise](../07-add-cds-definitions/README.md#consider-the-units-of-definition-and-their-relationships). 

## Start the CAP server

Finally we're ready. Let's go!

👉 Start the service as you have done before, but with the global `--profile` option:

```bash
cds watch --profile sandbox
```

👉 Observe the output - here's a section from the startup log output:

```text
[cds] - connect to API_BUSINESS_PARTNER > odata-v2 {
  url: 'https://sandbox.api.sap.com/s4hanacloud/sap/opu/odata/sap/API_BUSINESS_PARTNER/',
  headers: { APIKey: '...' }
}
[cds] - serving IncidentsService { path: '/incidents', impl: 'srv/incidents-service.js' }
```

While it's nice to see that the CAP server is still serving the `IncidentsService` as we'd expect (in the second log line here), it's also heart warming to see the connection to the system that is serving the external service, shown in the first log line. What we're seeing in this line is similar to what we saw when we [tried out a remote call to the mocked service which was running in an external process, in exercise 08](../08-introduce-sap-cloud-sdk/README.md#try-it-out):

```text
[cds] - connect to API_BUSINESS_PARTNER > odata { url: 'http://localhost:5005/api-business-partner' }
```

This time it's different, in two ways: 

* the type is `odata-v2` rather than `odata`
* the credentials now also include the APIKey header that will be added to each HTTP request

Note also that even though the `cds` command we used was `watch`, which implies `--with-mocks`, there's no need for the server to mock `API_BUSINESS_PARTNER` because there are details provided for it (and therefore we don't see any log lines that say something like `mocking API_BUSINESS_PARTNER { path: '/api-business-partner' }`. 

👉 Observe also the contents of `~/.cds-services.json`, which now of course only include information on the provision of the `IncidentsService`:

```json
{
  "cds": {
    "provides": { 
      "IncidentsService": {
        "kind": "odata",
        "credentials": {
          "url": "http://localhost:4004/incidents"
        }
      }
    }
  }
}
```

## Request customer data

The moment of truth has arrived! 

👉 Head over to the list of service endpoints at <http://localhost:4004/>, and choose the `Customers` entity set via <http://localhost:4004/incidents/Customers>.

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

👉 Check the log output:

```text
[cds] - GET /incidents/Customers 
>> delegating to S4 service...
[remote] - GET https://sandbox.api.sap.com/s4hanacloud/sap/opu/odata/sap/API_BUSINESS_PARTNER//A_BusinessPartner?$select=BusinessPartner,BusinessPartnerFullName&$orderby=BusinessPartner%20asc&$top=1000 {
  headers: {
    accept: 'application/json,text/plain',
    'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8',
    'x-correlation-id': '0b71b902-a02b-41a5-8322-037660e01520'
  },
  data: undefined
}
```

### Think about what happened

👉 Spend a couple of moments thinking about the flow here.

* The query that was sent (from your browser) to the CAP server was `GET /incidents/Customers`
* This caused the anonymous function defined as a handler for the `READ` event of the `Customers` entity to be triggered, and the query was received by that function inside the object passed as the argument to the `req` parameter:
    ```js
    this.on('READ', 'Customers', (req) => {
      console.log('>> delegating to SAP S/4HANA Cloud service...')
      return S4bupa.run(req.query)
    })
    ```
* The query (in `req.query`) is transparently translated into an OData query by the CAP framework
* The constructed OData query is sent to the remote system using the SAP Cloud SDK

## Summary

At this point you have a fully integrated external service wired up with your own service, and you've seen how simple the execution of remote queries is. No manual OData query construction needed, no manual handling of HTTP client configuration like authentication, no response parsing, error handling, issues like hard-wired hostnames and so on.

## Further reading

* [Consuming Services Cookbook](https://cap.cloud.sap/docs/guides/using-services)

---

## Questions

If you finish earlier than your fellow participants, you might like to ponder these questions. There isn't always a single correct answer and there are no prizes - they're just to give you something else to think about.

1. When we [started the CAP server](#start-the-cap-server), why did we observe a difference between the remote system types "odata" and "odata-v2"?

---

[Next exercise](../DIRNAME/)
